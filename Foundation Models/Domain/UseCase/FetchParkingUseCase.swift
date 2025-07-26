//
//  FetchParkingUseCase.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation

protocol FetchParkingUseCase {
    func execute(query: String, near location: CLLocation) async throws -> [ParkingInfo]
}

class DefaultFetchParkingUseCase: FetchParkingUseCase {
    private let parkingRepository: ParkingRepository

    init(parkingRepository: ParkingRepository) {
        self.parkingRepository = parkingRepository
    }

    func execute(query: String, near location: CLLocation) async throws -> [ParkingInfo] {
        return try await parkingRepository.searchParking(query: query, near: location)
    }
}
