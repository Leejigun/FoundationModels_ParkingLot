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
        let fetchWeatherUseCase: FetchWeatherUseCase =
            DefaultFetchWeatherUseCase(weatherRepository: weatherRepository)
        let locationService: LocationService = DefaultLocationService()  // Singleton 패턴으로 관리할 수도 있음
        let viewModel = WeatherViewModel(
            fetchWeatherUseCase: fetchWeatherUseCase,
            locationService: locationService
        )
        return WeatherView(viewModel: viewModel)
    }

    static func configureParkingView() -> ParkingView {
        // Data 계층 구현체 생성
        let parkingRepository: ParkingRepository = MapKitParkingRepository()
        let locationService: LocationService = DefaultLocationService()
        
        // Domain 계층 Use Case 생성 (Repository에 의존성 주입)
        let generateParkingTagsUseCase: GenerateParkingTagsUseCase = DefaultGenerateParkingTagsUseCase()
        let fetchParkingUseCase: FetchParkingUseCase =
        DefaultFetchParkingUseCase(parkingRepository: parkingRepository)

        // Presentation 계층 ViewModel 생성 (Use Case 및 LocationService에 의존성 주입)
        let viewModel = ParkingViewModel(
            fetchParkingUseCase: fetchParkingUseCase, generateParkingTagsUseCase: generateParkingTagsUseCase,
            locationService: locationService
        )

        // View 생성 (ViewModel에 의존성 주입)
        return ParkingView(viewModel: viewModel)
    }
}
