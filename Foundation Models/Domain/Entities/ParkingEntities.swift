//
//  ParkingEntities.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation

struct ParkingInfo: Identifiable {
    let id = UUID()
    let name: String
    let address: String?
    let distance: String? // 예: "290m"
    let distanceInMeters: Int?
    let mapURL: URL?
    let phoneNumber: String?
    let rating: String? // 평점
    let openingHours: [String]? // 영업 시간
    var errorMessage: String?
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
