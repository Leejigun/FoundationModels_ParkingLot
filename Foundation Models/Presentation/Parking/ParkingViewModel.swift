//
//  ParkingViewModel.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation
import Observation
import MapKit

@Observable
class ParkingViewModel {
    var parkingPlaces: [ParkingInfo] = []
    var visibleParkingPlaces: [ParkingInfo] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var currentLocation: CLLocation?

    var mapRegion: MKCoordinateRegion
    var parkingAnnotations: [MKPointAnnotation] = []

    var currentVisibleMapRect: MKMapRect = MKMapRect.world

    private let fetchParkingUseCase: FetchParkingUseCase
    private let generateParkingTagsUseCase: GenerateParkingTagsUseCase
    private let locationService: LocationService

    init(fetchParkingUseCase: FetchParkingUseCase, generateParkingTagsUseCase: GenerateParkingTagsUseCase, locationService: LocationService) {
        self.fetchParkingUseCase = fetchParkingUseCase
        self.generateParkingTagsUseCase = generateParkingTagsUseCase
        self.locationService = locationService
        self.mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.6186, longitude: 126.9189),
                                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
    }

    func requestLocationPermissionAndInitialSearch() {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let status = try await locationService.requestAuthorizationStatus()
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("위치 권한 승인됨. 현재 위치 요청 시작.")
                    do {
                        let location = try await locationService.requestCurrentLocation()
                        self.currentLocation = location
                        self.mapRegion = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                        await self.searchParking(query: "주차장", near: location)
                    } catch {
                        print("현재 위치 가져오기 실패: \(error.localizedDescription). 지도 중심 기준으로 검색합니다.")
                        self.errorMessage = "현재 위치를 가져오는 데 실패했습니다. 지도 중심 기준으로 검색합니다."
                        await self.searchParking(query: "주차장", near: CLLocation(latitude: self.mapRegion.center.latitude, longitude: self.mapRegion.center.longitude))
                    }
                case .denied, .restricted:
                    print("위치 권한 거부 또는 제한됨. 지도 중심 기준으로 검색합니다.")
                    self.errorMessage = ParkingError.locationAccessDenied.localizedDescription
                    await self.searchParking(query: "주차장", near: CLLocation(latitude: self.mapRegion.center.latitude, longitude: self.mapRegion.center.longitude))
                case .notDetermined:
                    print("위치 권한 아직 결정되지 않음. 사용자에게 요청 필요.")
                    self.errorMessage = "위치 권한이 필요합니다. 앱 설정에서 권한을 허용해주세요. (지도 중심 기준으로 검색)"
                    await self.searchParking(query: "주차장", near: CLLocation(latitude: self.mapRegion.center.latitude, longitude: self.mapRegion.center.longitude))
                @unknown default:
                    self.errorMessage = ParkingError.unknown.localizedDescription
                    await self.searchParking(query: "주차장", near: CLLocation(latitude: self.mapRegion.center.latitude, longitude: self.mapRegion.center.longitude))
                }
            } catch {
                if let parkingError = error as? ParkingError {
                    self.errorMessage = parkingError.localizedDescription
                } else {
                    self.errorMessage = ParkingError.unknown.localizedDescription
                }
                await self.searchParking(query: "주차장", near: CLLocation(latitude: self.mapRegion.center.latitude, longitude: self.mapRegion.center.longitude))
            }
        }
    }

    func mapCenterDidChange(to coordinate: CLLocationCoordinate2D) {
        // 지도가 멈출 때마다 지도 중심 기준으로 주차장 검색 (기존 로직 유지)
        Task { @MainActor in
            await self.searchParking(query: "주차장", near: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
    }
    
    func mapVisibleRectDidChange(to mapRect: MKMapRect) {
        self.currentVisibleMapRect = mapRect
        filterVisibleParkingPlaces()
    }

    // MARK: - 주소 검색 및 지도 이동 기능 추가
    func searchAddressAndMoveMap(addressQuery: String) async {
        guard !addressQuery.isEmpty else {
            self.errorMessage = "검색할 주소를 입력해주세요."
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = addressQuery
        // 현재 맵의 리전을 기반으로 검색하면 더 정확할 수 있습니다.
        // 하지만 전역 검색을 위해 region을 넓게 잡거나 설정하지 않을 수도 있습니다.
        // request.region = self.mapRegion

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            await MainActor.run {
                if let firstItem = response.mapItems.first {
                    // 검색된 첫 번째 항목의 좌표로 지도 이동
                    self.mapRegion = MKCoordinateRegion(center: firstItem.location.coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                    // 지도 이동 후 해당 위치를 중심으로 주차장 검색 자동 트리거 (mapCenterDidChange에서 처리)
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "입력하신 주소를 찾을 수 없습니다."
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "주소 검색 중 오류가 발생했습니다: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func searchParking(query: String, near location: CLLocation) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.parkingAnnotations = []
            self.parkingPlaces = []
            self.visibleParkingPlaces = []
        }
        do {
            let results = try await fetchParkingUseCase.execute(query: query, near: location)
            await MainActor.run {
                self.parkingPlaces = results
                self.parkingAnnotations = results.map { parking in
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = parking.coordinate
                    annotation.title = parking.name
                    annotation.subtitle = parking.address
                    return annotation
                }
                filterVisibleParkingPlaces()
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

    private func filterVisibleParkingPlaces() {
        self.visibleParkingPlaces = parkingPlaces.filter { parking in
            let mapPoint = MKMapPoint(parking.coordinate)
            return self.currentVisibleMapRect.contains(mapPoint)
        }
    }
    
    // MARK: Tag 조회
    func getTagByParkingInfo(_ parkingInfo: ParkingInfo) async -> [String] {
        return (try? await generateParkingTagsUseCase.execute(parkingInfo: parkingInfo)) ?? []
    }
}
