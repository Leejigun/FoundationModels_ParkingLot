//
//  WeatherViewModel.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation
import Combine

class WeatherViewModel: ObservableObject {
    @Published var myLocationWeather: WeatherInfo?
    @Published var majorCityWeathers: [WeatherInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let fetchWeatherUseCase: FetchWeatherUseCase
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()

    // 주요 대도시 리스트
    private let predefinedCities: [LocationInfo] = [
        LocationInfo(name: "서울", latitude: 37.5665, longitude: 126.9780),
        LocationInfo(name: "도쿄", latitude: 35.6895, longitude: 139.6917),
        LocationInfo(name: "뉴욕", latitude: 40.7128, longitude: -74.0060),
        LocationInfo(name: "런던", latitude: 51.5072, longitude: -0.1276),
        LocationInfo(name: "파리", latitude: 48.8566, longitude: 2.3522),
        LocationInfo(name: "베이징", latitude: 39.9042, longitude: 116.4074),
        LocationInfo(name: "시드니", latitude: -33.8688, longitude: 151.2093)
    ]

    init(fetchWeatherUseCase: FetchWeatherUseCase, locationService: LocationService) {
        self.fetchWeatherUseCase = fetchWeatherUseCase
        self.locationService = locationService

        // 주요 도시 WeatherInfo 초기화
        self.majorCityWeathers = predefinedCities.map {
            WeatherInfo(location: $0, errorMessage: "로딩 중...")
        }

        setupLocationObservers()
    }

    private func setupLocationObservers() {
        locationService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("위치 권한 승인됨. 위치 요청 시작.")
                    self.locationService.requestLocation()
                case .denied, .restricted:
                    print("위치 권한 거부 또는 제한됨.")
                    self.errorMessage = WeatherError.locationAccessDenied.localizedDescription
                    self.isLoading = false
                    self.myLocationWeather = WeatherInfo(
                        location: LocationInfo(name: "내 위치", latitude: 0, longitude: 0, isMyLocation: true),
                        errorMessage: self.errorMessage
                    )
                case .notDetermined:
                    print("위치 권한 아직 결정되지 않음.")
                    // 사용자에게 다시 요청할 수 있음
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)

        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.myLocationWeather = WeatherInfo(
                        location: LocationInfo(name: "내 위치", latitude: 0, longitude: 0, isMyLocation: true),
                        errorMessage: self.errorMessage
                    )
                }
            }, receiveValue: { [weak self] location in
                guard let self = self else { return }
                let myLocationInfo = LocationInfo(name: "내 위치", latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, isMyLocation: true)
                Task {
                    await self.fetchWeather(for: location, locationInfo: myLocationInfo)
                }
            })
            .store(in: &cancellables)
    }

    func requestLocationPermission() {
        locationService.requestAuthorization()
    }

    func loadAllWeatherData() {
        isLoading = true
        errorMessage = nil

        // 내 위치 날씨 로드 트리거 (위치 권한에 따라 처리됨)
        // setupLocationObservers에서 authorizationStatusPublisher를 구독하여 처리
        locationService.requestAuthorization()

        // 주요 도시 날씨 로드
        Task {
            await fetchMajorCitiesWeather()
            await MainActor.run {
                // 내 위치와 주요 도시 로딩이 모두 완료되었는지 확인 후 isLoading 해제
                if myLocationWeather != nil && majorCityWeathers.allSatisfy({ $0.current != nil || $0.errorMessage != nil }) {
                    isLoading = false
                }
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
                let weatherError: WeatherError
                if let err = error as? WeatherError {
                    weatherError = err
                } else {
                    weatherError = .unknown
                }
                let errorWeatherInfo = WeatherInfo(location: locationInfo, errorMessage: weatherError.localizedDescription)

                if locationInfo.isMyLocation {
                    self.myLocationWeather = errorWeatherInfo
                } else {
                    if let index = majorCityWeathers.firstIndex(where: { $0.location.id == locationInfo.id }) {
                        self.majorCityWeathers[index] = errorWeatherInfo
                    }
                }
                self.errorMessage = weatherError.localizedDescription // 전역 에러 메시지로도 설정
            }
        }
    }

    private func fetchMajorCitiesWeather() async {
        await withTaskGroup(of: Void.self) { group in
            for index in self.predefinedCities.indices {
                let cityInfo = self.predefinedCities[index]
                let location = CLLocation(latitude: cityInfo.latitude, longitude: cityInfo.longitude)
                group.addTask {
                    await self.fetchWeather(for: location, locationInfo: cityInfo)
                }
            }
        }
    }
}
