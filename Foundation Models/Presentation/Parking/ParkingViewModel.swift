//
//  ParkingViewModel.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//
// ParkingViewModel.swift (수정)
// ParkingViewModel.swift (수정)

import Foundation
import CoreLocation
import Observation

@Observable
class ParkingViewModel {
    
    var parkingPlaces: [ParkingInfo] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var currentLocation: CLLocation?

    private let fetchParkingUseCase: FetchParkingUseCase
    private let locationService: LocationService

    init(fetchParkingUseCase: FetchParkingUseCase, locationService: LocationService) {
        self.fetchParkingUseCase = fetchParkingUseCase
        self.locationService = locationService
    }

    func requestLocationPermissionAndSearch() {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let status = try await locationService.requestAuthorizationStatus()
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("위치 권한 승인됨. 위치 요청 시작.")
                    let location = try await locationService.requestCurrentLocation()
                    self.currentLocation = location
                    await self.searchParking(query: "주차장", near: location)
                case .denied, .restricted:
                    print("위치 권한 거부 또는 제한됨.")
                    
                    let defaultLocation = CLLocation(latitude: 37.6186, longitude: 126.9189)
                    self.currentLocation = defaultLocation
                    await self.searchParking(query: "주차장", near: defaultLocation)
                    
                    self.errorMessage = ParkingError.locationAccessDenied.localizedDescription
                case .notDetermined:
                    print("위치 권한 아직 결정되지 않음.")
                    
                    let defaultLocation = CLLocation(latitude: 37.6186, longitude: 126.9189)
                    self.currentLocation = defaultLocation
                    await self.searchParking(query: "주차장", near: defaultLocation)
                    
                    self.errorMessage = "위치 권한이 필요합니다. 앱 설정에서 권한을 허용해주세요."
                    self.isLoading = false
                @unknown default:
                    self.errorMessage = ParkingError.unknown.localizedDescription
                    self.isLoading = false
                }
            } catch {
                if let parkingError = error as? ParkingError {
                    self.errorMessage = parkingError.localizedDescription
                } else {
                    self.errorMessage = ParkingError.unknown.localizedDescription
                }
                self.isLoading = false
            }
        }
    }

    func searchParking(query: String, near location: CLLocation) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            let results = try await fetchParkingUseCase.execute(query: query, near: location)
            await MainActor.run {
                self.parkingPlaces = results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                let parkingError: ParkingError
                if let err = error as? ParkingError {
                    parkingError = err
                } else {
                    parkingError = .unknown
                }
                self.errorMessage = parkingError.localizedDescription
                self.isLoading = false
            }
        }
    }
}
