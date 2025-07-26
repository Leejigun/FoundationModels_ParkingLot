//
//  WeatherKitRepositoryImp.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import WeatherKit
import CoreLocation

class WeatherKitRepositoryImp: WeatherRepository {
    private let weatherService = WeatherService()

    func fetchWeather(for location: CLLocation, locationInfo: LocationInfo) async throws -> WeatherInfo {
        do {
            let (currentWeather, hourlyForecast, dailyForecast) = try await weatherService.weather(for: location, including: .current, .hourly, .daily)

            // WeatherKit 데이터를 Domain Entities로 변환
            let current = CurrentWeatherInfo(
                temperature: currentWeather.temperature,
                apparentTemperature: currentWeather.apparentTemperature,
                condition: currentWeather.condition,
                symbolName: currentWeather.symbolName
            )

            let hourly = hourlyForecast.map { hour in
                HourlyWeatherInfo(
                    date: hour.date,
                    temperature: hour.temperature,
                    symbolName: hour.symbolName
                )
            }

            let daily = dailyForecast.map { day in
                DailyWeatherInfo(
                    date: day.date,
                    lowTemperature: day.lowTemperature,
                    highTemperature: day.highTemperature,
                    symbolName: day.symbolName
                )
            }

            return WeatherInfo(
                location: locationInfo,
                current: current,
                hourlyForecast: Array(hourly.prefix(24)), // 다음 24시간 예보
                dailyForecast: Array(daily.prefix(7)) // 다음 7일 예보
            )

        } catch {
            throw WeatherError.weatherFetchFailed(error)
        }
    }
}

