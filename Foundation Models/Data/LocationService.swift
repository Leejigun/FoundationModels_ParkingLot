//
//  LocationService.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation
import Combine

protocol LocationService {
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    var locationPublisher: AnyPublisher<CLLocation, Error> { get }
    func requestAuthorization()
    func requestLocation()
}

class DefaultLocationService: NSObject, LocationService, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    private let authorizationStatusSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    private let locationSubject = PassthroughSubject<CLLocation, Error>()

    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        authorizationStatusSubject.eraseToAnyPublisher()
    }

    var locationPublisher: AnyPublisher<CLLocation, Error> {
        locationSubject.eraseToAnyPublisher()
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        locationManager.requestLocation() // 단일 위치 업데이트 요청
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationSubject.send(location)
        locationSubject.send(completion: .finished) // 한 번만 보내고 완료
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            locationSubject.send(completion: .failure(WeatherError.locationAccessDenied))
        } else {
            locationSubject.send(completion: .failure(WeatherError.locationFetchFailed(error)))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatusSubject.send(manager.authorizationStatus)
    }
}
