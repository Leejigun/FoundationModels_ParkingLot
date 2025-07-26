//
//  AppConfigurator.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import SwiftUI

// WeatherKitExampleApp.swift 파일의 @main struct 안에 다음과 같이 사용
class AppConfigurator {
    static func configureWeatherView() -> WeatherView {
        let weatherRepository: WeatherRepository = WeatherKitRepositoryImp()
        let fetchWeatherUseCase: FetchWeatherUseCase = DefaultFetchWeatherUseCase(weatherRepository: weatherRepository)
        let locationService: LocationService = DefaultLocationService() // Singleton 패턴으로 관리할 수도 있음
        let viewModel = WeatherViewModel(fetchWeatherUseCase: fetchWeatherUseCase, locationService: locationService)
        return WeatherView(viewModel: viewModel)
    }
}
