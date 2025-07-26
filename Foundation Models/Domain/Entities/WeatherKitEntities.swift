//
//  WeatherKitEntities.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import WeatherKit
import CoreLocation

struct LocationInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    var isMyLocation: Bool = false
}

struct WeatherInfo: Identifiable {
    let id = UUID()
    let location: LocationInfo
    var current: CurrentWeatherInfo?
    var hourlyForecast: [HourlyWeatherInfo]?
    var dailyForecast: [DailyWeatherInfo]?
    var errorMessage: String?
}

// WeatherKit의 CurrentWeather를 추상화하거나, 필요한 데이터만 뽑아내는 구조
struct CurrentWeatherInfo {
    let temperature: Measurement<UnitTemperature>
    let apparentTemperature: Measurement<UnitTemperature>
    let condition: WeatherCondition // WeatherKit의 WeatherCondition 사용
    let symbolName: String // WeatherKit의 symbolName 사용
}

// WeatherKit의 HourWeather를 추상화
struct HourlyWeatherInfo: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Measurement<UnitTemperature>
    let symbolName: String
}

// WeatherKit의 DayWeather를 추상화
struct DailyWeatherInfo: Identifiable {
    let id = UUID()
    let date: Date
    let lowTemperature: Measurement<UnitTemperature>
    let highTemperature: Measurement<UnitTemperature>
    let symbolName: String
}

// 에러 핸들링을 위한 Enum
enum WeatherError: Error, LocalizedError {
    case locationAccessDenied
    case locationFetchFailed(Error)
    case weatherFetchFailed(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .locationAccessDenied:
            return "위치 접근 권한이 거부되었습니다. 설정에서 변경해주세요."
        case .locationFetchFailed(let error):
            return "위치를 가져오는 데 실패했습니다: \(error.localizedDescription)"
        case .weatherFetchFailed(let error):
            return "날씨 정보를 불러오는 데 실패했습니다: \(error.localizedDescription)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
