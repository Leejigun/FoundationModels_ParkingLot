//
//  MapKitParkingRepository.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import MapKit
import CoreLocation
import Contacts

class MapKitParkingRepository: ParkingRepository {

    func searchParking(query: String, near location: CLLocation) async throws -> [ParkingInfo] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000) // 현재 위치 주변 2km 반경

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            return response.mapItems.map { mapItem in
                // MKMapItem을 ParkingInfo로 변환
                ParkingInfo(
                    name: mapItem.name ?? "알 수 없는 주차장",
                    address: mapItem.address?.fullAddress,
                    distance: mapItem.location.distance(from: location).formattedDistance(), // 거리 계산 및 포맷팅
                    distanceInMeters: Int(mapItem.location.distance(from: location)),
                    mapURL: mapItem.url,
                    phoneNumber: mapItem.phoneNumber,
                    rating: nil, // MapKit의 MKMapItem은 직접적인 평점 정보를 제공하지 않음
                    openingHours: nil // MapKit에서는 영업시간 정보를 직접 제공하지 않음
                )
            }
        } catch {
            throw ParkingError.parkingSearchFailed(error)
        }
    }
}

// MARK: - Helper Extensions for Formatting

extension CLLocationDistance {
    func formattedDistance() -> String {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        return formatter.string(fromValue: self, unit: .meter)
    }
}

