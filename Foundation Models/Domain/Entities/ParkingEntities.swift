//
//  ParkingEntities.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation
import MapKit

struct ParkingInfo: Identifiable {
    let id = UUID()
    let name: String
    /// 사용자의 현재 위치 여부
    let isCurrentLocation: Bool
    let address: String?
    let addressRepresentations: MKAddressRepresentations?
    let coordinate: CLLocationCoordinate2D
    let distance: String? // 예: "290m"
    let distanceInMeters: Int?
    let webSiteUrl: URL?
    let phoneNumber: String?
    let pointOfInterestCategory: MKPointOfInterestCategory?
    
    init(mapItem: MKMapItem, current location: CLLocation) {
        self.name = mapItem.name ?? "알 수 없는 주차장"
        self.isCurrentLocation = mapItem.isCurrentLocation
        self.address = mapItem.address?.fullAddress
        self.addressRepresentations = mapItem.addressRepresentations
        self.coordinate = mapItem.location.coordinate
        self.distance = mapItem.location.distance(from: location).formattedDistance()
        self.distanceInMeters = Int(mapItem.location.distance(from: location))
        self.webSiteUrl = mapItem.url
        self.phoneNumber = mapItem.phoneNumber
        self.pointOfInterestCategory = mapItem.pointOfInterestCategory
    }
}

extension ParkingInfo {
    var description: String {
        var info: [String] = []
        
        // 1. 이름 (필수)
        info.append("주차장 이름: **\(name)**")
        
        // 2. 주소
        if let addr = address, !addr.isEmpty {
            info.append("주소: \(addr)")
        }
        
        // 3. 거리
        if let dist = distance {
            info.append("현재 위치로부터 **\(dist)** 거리에 있습니다.")
        } else {
            info.append("현재 위치와의 거리를 알 수 없습니다.")
        }
        
        // 4. 전화번호
        if let phone = phoneNumber, !phone.isEmpty {
            info.append("문의 전화: \(phone)")
        }
        
        // 5. 웹사이트
        if let url = webSiteUrl {
            info.append("웹사이트: \(url.absoluteString)")
        }
        
        // 6. 카테고리 (iOS 13.0 이상)
        if let category = pointOfInterestCategory {
            info.append("카테고리: \(category.rawValue)")
        }
        
        // 7. 현재 위치 여부 (필요 시 추가)
        if isCurrentLocation {
            info.append("이곳은 사용자의 현재 위치입니다.")
        }
        
        // 모든 정보 줄바꿈으로 연결
        return info.joined(separator: "\n")
    }
}

// 에러 핸들링을 위한 Enum (WeatherKit 예시에서 사용한 WeatherError를 ParkingError로 확장 또는 분리)
enum ParkingError: Error, LocalizedError {
    case locationAccessDenied
    case locationFetchFailed(Error)
    case parkingSearchFailed(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .locationAccessDenied:
            return "위치 접근 권한이 거부되었습니다. 설정에서 변경해주세요."
        case .locationFetchFailed(let error):
            return "위치를 가져오는 데 실패했습니다: \(error.localizedDescription)"
        case .parkingSearchFailed(let error):
            return "주차장 정보를 불러오는 데 실패했습니다: \(error.localizedDescription)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
