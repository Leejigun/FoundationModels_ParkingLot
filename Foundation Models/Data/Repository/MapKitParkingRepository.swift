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

    func searchParking(query: String, near location: CLLocation) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000) // 현재 위치 주변 2km 반경

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            return response.mapItems
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
