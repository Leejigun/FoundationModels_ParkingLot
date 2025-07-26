//
//  WeatherRepository.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation

protocol WeatherRepository {
    func fetchWeather(for location: CLLocation, locationInfo: LocationInfo) async throws -> WeatherInfo
}
