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
            let parkingInfo = ParkingInfo(
                name: mapItem.name ?? "알 수 없는 주차장",
                address: mapItem.address?.fullAddress,
                coordinate: mapItem.location.coordinate,
                distance: mapItem.location.distance(from: location).formattedDistance(), // 거리 계산 및 포맷팅
                distanceInMeters: Int(mapItem.location.distance(from: location)),
                mapURL: mapItem.url,
                phoneNumber: mapItem.phoneNumber,
                openingHours: ["영업 시간 정보는 MapKit에서 직접 제공되지 않습니다. 상세 정보는 웹사이트를 확인해주세요."]
            )
            parkingInfos.append(parkingInfo)
        }
        return parkingInfos
    }
}
