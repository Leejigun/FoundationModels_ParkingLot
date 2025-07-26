//
//  WeatherViewModel.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation
import Observation

@Observable
class WeatherViewModel {
    var myLocationWeather: WeatherInfo?
    var majorCityWeathers: [WeatherInfo] = []
    var isLoading = false
    var errorMessage: String?

    private let fetchWeatherUseCase: FetchWeatherUseCase
    private let locationService: LocationService

    init(fetchWeatherUseCase: FetchWeatherUseCase, locationService: LocationService) {
        self.fetchWeatherUseCase = fetchWeatherUseCase
        self.locationService = locationService

        self.majorCityWeathers = predefinedCities.map {
            WeatherInfo(location: $0, errorMessage: "로딩 중...")
        }
    }
    
    func fetchWeatherForAllLocations() {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let authStatus = try await locationService.requestAuthorizationStatus()
                switch authStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("위치 권한 승인됨. 내 위치 날씨 요청 시작.")
                    do {
                        let location = try await locationService.requestCurrentLocation()
                        let myLocationInfo = LocationInfo(name: "내 위치", latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, isMyLocation: true)
                        self.myLocationWeather = try await fetchWeatherUseCase.execute(for: location, locationInfo: myLocationInfo)
                    } catch {
                        // 내 위치 가져오기 실패 시 처리
                        // 이 시점에서는 실제 위치 정보가 없으므로, 기본 LocationInfo를 생성하여 전달합니다.
                        let defaultMyLocationInfo = LocationInfo(name: "내 위치", latitude: 37.6186, longitude: 126.9189, isMyLocation: true)

                        self.myLocationWeather = WeatherInfo(
                            location: defaultMyLocationInfo,
                            current: nil,
                            hourlyForecast: nil,
                            dailyForecast: nil,
                            errorMessage: error.localizedDescription
                        )
                        
                        self.errorMessage = error.localizedDescription
                    }
                case .denied, .restricted:
                    print("위치 권한 거부 또는 제한됨.")
                    let defaultMyLocationInfo = LocationInfo(name: "내 위치", latitude: 37.6186, longitude: 126.9189, isMyLocation: true)
                    self.myLocationWeather = WeatherInfo(
                        location: defaultMyLocationInfo,
                        current: nil,
                        hourlyForecast: nil,
                        dailyForecast: nil,
                        errorMessage: WeatherError.locationAccessDenied.localizedDescription
                    )
                    self.errorMessage = WeatherError.locationAccessDenied.localizedDescription
                case .notDetermined:
                    print("위치 권한 아직 결정되지 않음. 사용자에게 요청 필요.")
                    self.errorMessage = "위치 권한이 필요합니다. 앱 설정에서 권한을 허용해주세요."
                    let defaultMyLocationInfo = LocationInfo(name: "내 위치", latitude: 37.6186, longitude: 126.9189, isMyLocation: true)
                    self.myLocationWeather = WeatherInfo(
                        location: defaultMyLocationInfo,
                        current: nil,
                        hourlyForecast: nil,
                        dailyForecast: nil,
                        errorMessage: self.errorMessage
                    )
                @unknown default:
                    self.errorMessage = WeatherError.unknown.localizedDescription
                    let defaultMyLocationInfo = LocationInfo(name: "내 위치", latitude: 37.6186, longitude: 126.9189, isMyLocation: true)
                    self.myLocationWeather = WeatherInfo(
                        location: defaultMyLocationInfo,
                        current: nil,
                        hourlyForecast: nil,
                        dailyForecast: nil,
                        errorMessage: self.errorMessage
                    )
                }

                // 주요 대도시 날씨는 위치 권한과 별개로 진행
                await fetchMajorCitiesWeather()

                self.isLoading = false // 모든 작업 완료 후 로딩 상태 해제
            } catch {
                // 권한 요청 자체에서 발생한 오류
                if let weatherError = error as? WeatherError {
                    self.errorMessage = weatherError.localizedDescription
                } else {
                    self.errorMessage = WeatherError.unknown.localizedDescription
                }
                self.isLoading = false
            }
        }
    }

    private func fetchWeather(for location: CLLocation, locationInfo: LocationInfo) async {
        do {
            let weather = try await fetchWeatherUseCase.execute(for: location, locationInfo: locationInfo)
            await MainActor.run {
                if locationInfo.isMyLocation {
                    self.myLocationWeather = weather
                } else {
                    if let index = majorCityWeathers.firstIndex(where: { $0.location.id == locationInfo.id }) {
                        self.majorCityWeathers[index] = weather
                    }
                }
            }
        } catch {
            await MainActor.run {
                let errorWeatherInfo = WeatherInfo(location: locationInfo, errorMessage: error.localizedDescription)
                if locationInfo.isMyLocation {
                    self.myLocationWeather = errorWeatherInfo
                } else {
                    if let index = majorCityWeathers.firstIndex(where: { $0.location.id == locationInfo.id }) {
                        self.majorCityWeathers[index] = errorWeatherInfo
                    }
                }
            }
        }
    }

    private func fetchMajorCitiesWeather() async {
        await withTaskGroup(of: Void.self) { group in
            for city in predefinedCities {
                group.addTask {
                    let location = CLLocation(latitude: city.latitude, longitude: city.longitude)
                    await self.fetchWeather(for: location, locationInfo: city)
                }
            }
        }
    }

    // 주요 대도시 리스트는 그대로 유지
    private let predefinedCities: [LocationInfo] = [
        LocationInfo(name: "서울", latitude: 37.5665, longitude: 126.9780),
        LocationInfo(name: "도쿄", latitude: 35.6895, longitude: 139.6917),
        LocationInfo(name: "뉴욕", latitude: 40.7128, longitude: -74.0060),
        LocationInfo(name: "런던", latitude: 51.5072, longitude: -0.1276),
        LocationInfo(name: "파리", latitude: 48.8566, longitude: 2.3522),
        LocationInfo(name: "베이징", latitude: 39.9042, longitude: 116.4074),
        LocationInfo(name: "시드니", latitude: -33.8688, longitude: 151.2093)
    ]
}
