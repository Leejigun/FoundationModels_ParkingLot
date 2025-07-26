//
//  ParkingRepository.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation
import MapKit

protocol ParkingRepository {
    func searchParking(query: String, near location: CLLocation) async throws -> [MKMapItem]
}
