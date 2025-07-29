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
        formatter.unitStyle = .short // "m" 또는 "km" 등으로 짧게 표시

        // 1. LengthFormatter를 사용하여 기본 문자열 생성 (예: "290.5m", "1.2km")
        let formattedString = formatter.string(fromValue: self, unit: .meter)

        // 2. 문자열에서 숫자 부분과 단위 부분을 분리
        // 정규식을 사용하면 더 견고하지만, 간단한 경우 숫자만 추출
        let numberCharacterSet = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))
        let unitCharacterSet = CharacterSet.letters.union(CharacterSet(charactersIn: " ")) // 단위 문자 (m, km 등)와 공백

        var numberString = ""
        var unitString = ""

        for char in formattedString {
            if String(char).rangeOfCharacter(from: numberCharacterSet) != nil {
                numberString.append(char)
            } else if String(char).rangeOfCharacter(from: unitCharacterSet) != nil {
                unitString.append(char)
            }
        }

        // 3. 숫자 부분을 Double로 변환하고 정수로 올림/내림/반올림 처리
        if let doubleValue = Double(numberString) {
            let roundedValue = Int(doubleValue.rounded()) // 가장 가까운 정수로 반올림
            // 또는 Int(doubleValue) // 소수점 이하 버림 (내림)
            // 또는 Int(ceil(doubleValue)) // 올림 (import Foundation)

            // 4. 소수점을 버린 정수와 원래 단위를 합쳐서 반환
            return "\(roundedValue)\(unitString.trimmingCharacters(in: .whitespaces))" // 단위 앞뒤 공백 제거
        } else {
            // 숫자 추출 실패 시 원래 문자열 반환 (혹은 에러 처리)
            return formattedString
        }
    }
}
