//
//  WeatherView.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import SwiftUI
import WeatherKit // WeatherCondition, symbolName 등을 사용하기 위해 임포트

struct WeatherView: View {
    @State var viewModel: WeatherViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("날씨 정보 불러오는 중...")
                            .padding()
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    // 내 위치 날씨
                    if let myWeather = viewModel.myLocationWeather {
                        WeatherCard(weatherInfo: myWeather)
                            .padding(.horizontal)
                    }

                    Divider().padding(.horizontal)

                    Text("주요 대도시 날씨")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    ForEach(viewModel.majorCityWeathers) { cityWeather in
                        WeatherCard(weatherInfo: cityWeather)
                            .padding(.horizontal)
                    }
                }
                .navigationTitle("날씨")
                .onAppear {
                    viewModel.fetchWeatherForAllLocations()
                }
            }
        }
    }
}

// 개별 도시 날씨 정보를 표시하는 뷰 컴포넌트
struct WeatherCard: View {
    let weatherInfo: WeatherInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(weatherInfo.location.name)
                    .font(.headline)
                Spacer()
                if let errorMsg = weatherInfo.errorMessage {
                    Text(errorMsg)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if let current = weatherInfo.current {
                HStack {
                    Image(systemName: current.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Text("\(Int(current.temperature.converted(to: .celsius).value))°C")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                Text(current.condition.description)
                    .font(.subheadline)
                Text("체감: \(Int(current.apparentTemperature.converted(to: .celsius).value))°C")
                    .font(.subheadline)
            } else if weatherInfo.errorMessage == nil {
                Text("날씨 정보를 불러오는 중...")
                    .font(.subheadline)
            }

            if let hourlyForecast = weatherInfo.hourlyForecast, !hourlyForecast.isEmpty {
                Divider()
                Text("시간별 예보 (다음 24시간)")
                    .font(.subheadline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(hourlyForecast.prefix(12)) { hourWeather in // 최대 12시간 표시
                            VStack {
                                Text(hourWeather.date, format: .dateTime.hour())
                                Image(systemName: hourWeather.symbolName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                Text("\(Int(hourWeather.temperature.converted(to: .celsius).value))°C")
                            }
                            .font(.caption)
                        }
                    }
                }
            }

            if let dailyForecast = weatherInfo.dailyForecast, !dailyForecast.isEmpty {
                Divider()
                Text("주간 예보 (다음 7일)")
                    .font(.subheadline)
                ForEach(dailyForecast) { dayWeather in
                    HStack {
                        Text(dayWeather.date, format: .dateTime.weekday(.short))
                            .frame(width: 50, alignment: .leading)
                        Image(systemName: dayWeather.symbolName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                        Spacer()
                        Text("최저: \(Int(dayWeather.lowTemperature.converted(to: .celsius).value))°C")
                        Text("최고: \(Int(dayWeather.highTemperature.converted(to: .celsius).value))°C")
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}
