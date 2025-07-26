//
//  FetchWeatherUseCase.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation

protocol FetchWeatherUseCase {
    func execute(for location: CLLocation, locationInfo: LocationInfo) async throws -> WeatherInfo
}

class DefaultFetchWeatherUseCase: FetchWeatherUseCase {
    private let weatherRepository: WeatherRepository

    init(weatherRepository: WeatherRepository) {
        self.weatherRepository = weatherRepository
    }

    func execute(for location: CLLocation, locationInfo: LocationInfo) async throws -> WeatherInfo {
        return try await weatherRepository.fetchWeather(for: location, locationInfo: locationInfo)
    }
}
