//
//  LocationService.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation

protocol LocationService {
    // 위치 권한 상태를 비동기적으로 요청하고 반환합니다.
    func requestAuthorizationStatus() async throws -> CLAuthorizationStatus
    // 현재 위치를 비동기적으로 요청하고 반환합니다.
    func requestCurrentLocation() async throws -> CLLocation
}

class DefaultLocationService: NSObject, LocationService, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    
    // 권한 요청 시 사용될 Continuation
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Error>?
    // 위치 요청 시 사용될 Continuation
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced // 배터리 효율을 위해 정확도 낮춤
    }

    // MARK: - LocationService Protocol Implementation

    func requestAuthorizationStatus() async throws -> CLAuthorizationStatus {
          let status = locationManager.authorizationStatus
          switch status {
          case .notDetermined:
              return try await withCheckedThrowingContinuation { continuation in
                  self.authorizationContinuation = continuation
                  locationManager.requestWhenInUseAuthorization()
              }
          default:
              return status // 즉시 반환!
          }
    }

    func requestCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation() // 단일 위치 업데이트 요청
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            // 위치가 없으면 오류로 처리
            locationContinuation?.resume(throwing: ParkingError.locationFetchFailed(NSError(domain: "LocationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No location found"])))
            locationContinuation = nil
            return
        }
        locationContinuation?.resume(returning: location)
        locationContinuation = nil // Continuation 사용 후 nil로 설정
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            if clError.code == .denied {
                authorizationContinuation?.resume(throwing: ParkingError.locationAccessDenied)
                locationContinuation?.resume(throwing: ParkingError.locationAccessDenied)
            } else {
                authorizationContinuation?.resume(throwing: ParkingError.locationFetchFailed(error))
                locationContinuation?.resume(throwing: ParkingError.locationFetchFailed(error))
            }
        } else {
            authorizationContinuation?.resume(throwing: ParkingError.locationFetchFailed(error))
            locationContinuation?.resume(throwing: ParkingError.locationFetchFailed(error))
        }
        authorizationContinuation = nil
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 권한 변경 시, 대기 중인 authorizationContinuation이 있다면 결과를 반환
        if let continuation = authorizationContinuation {
            continuation.resume(returning: manager.authorizationStatus)
            authorizationContinuation = nil
        }
        // 위치 요청 중인데 권한이 변경되어 위치를 더 이상 가져올 수 없는 경우 처리
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            locationContinuation?.resume(throwing: ParkingError.locationAccessDenied)
            locationContinuation = nil
        }
    }
}
