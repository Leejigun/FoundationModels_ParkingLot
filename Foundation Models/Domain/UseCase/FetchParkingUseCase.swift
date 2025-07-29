//
//  FetchParkingUseCase.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation
import MapKit

protocol FetchParkingUseCase {
    func execute(query: String, near location: CLLocation) async throws -> [ParkingInfo]
}

class DefaultFetchParkingUseCase: FetchParkingUseCase {
    private let parkingRepository: ParkingRepository

    init(parkingRepository: ParkingRepository) {
        self.parkingRepository = parkingRepository
    }

    func execute(query: String, near location: CLLocation) async throws -> [ParkingInfo] {
        let mapItems = try await parkingRepository.searchParking(query: query, near: location)
        
        var parkingInfos: [ParkingInfo] = []
        for mapItem in mapItems {
            let parkingInfo = ParkingInfo(mapItem: mapItem, current: location)
            parkingInfos.append(parkingInfo)
        }
        return parkingInfos
    }
}
