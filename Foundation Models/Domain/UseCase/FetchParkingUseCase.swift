//
//  FetchParkingUseCase.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import Foundation
import CoreLocation
import MapKit

import FoundationModels

protocol FetchParkingUseCase {
    func execute(query: String, near location: CLLocation) async throws -> [ParkingInfo]
}

class DefaultFetchParkingUseCase: FetchParkingUseCase {
    private let parkingRepository: ParkingRepository

    init(parkingRepository: ParkingRepository) {
        self.parkingRepository = parkingRepository
    }

    func execute(query: String, near location: CLLocation) async throws -> [ParkingInfo] {
        let mapItems = try await parkingRepository.searchParking(query: query, near: location)
        
        var parkingInfos: [ParkingInfo] = []
        for mapItem in mapItems {
            let parkingInfo = ParkingInfo(
                name: mapItem.name ?? "알 수 없는 주차장",
                address: mapItem.address?.fullAddress,
                latitude: mapItem.location.coordinate.latitude,
                longitude: mapItem.location.coordinate.longitude,
                distance: mapItem.location.distance(from: location).formattedDistance(), // 거리 계산 및 포맷팅
                distanceInMeters: Int(mapItem.location.distance(from: location)),
                phoneNumber: mapItem.phoneNumber
            )
            parkingInfos.append(parkingInfo)
        }
        return parkingInfos
    }
}

class FMFetchParkingUseCase: FetchParkingUseCase {
    
    private var session: LanguageModelSession
    private let searchParkingTool: SearchParkingTool
    
    init(parkingRepository: ParkingRepository) {
        self.searchParkingTool = SearchParkingTool(parkingRepository: parkingRepository)
        self.session = LanguageModelSession(tools: [self.searchParkingTool], instructions: "좌표값 기준 근처 주차장 검색")
    }
    
    func execute(query: String, near location: CLLocation) async throws -> [ParkingInfo] {
        while session.isResponding {
            try await Task.sleep(nanoseconds: 100_000_000)  // 대기 시간 100ms로 늘려 안정성 강화
        }
        
        let prompt = """
        사용자한테 전달받은 값을 사용해 주차장을 조회하시오
        ------------------------------------------------------------
        query: \(query)
        위도: \(location.coordinate.latitude)
        경도: \(location.coordinate.longitude)
        """
        
        return try await response(to: prompt)
    }
    
    private func response(to prompt: String) async throws -> [ParkingInfo] {
        let startTime = Date()
        do {
            let response = try await session.respond(
                to: prompt,
                generating: [ParkingInfo].self
            )
            
            let timeElapsed = Date().timeIntervalSince(startTime)
            print(
                "DEBUG: Model responded in \(String(format: "%.2f", timeElapsed)) seconds for prompt:\n\(prompt)\n- \(response.content.count)\n"
            )
            
            return response.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            
            let timeElapsed = Date().timeIntervalSince(startTime)
            print(
                "DEBUG: Model exceeded context window in \(String(format: "%.2f", timeElapsed)) seconds for prompt:\n\(prompt)\n- exceededContextWindowSize\n"
            )
            
            session = newSession(previousSession: session)
            return (try? await response(to: prompt)) ?? []
        } catch {
            
            let timeElapsed = Date().timeIntervalSince(startTime)
            print(
                "DEBUG: Model exceeded context window in \(String(format: "%.2f", timeElapsed)) seconds for prompt:\n\(prompt)\n- \(error.localizedDescription)\n"
            )
            
            return []
        }
    }
    
    private func newSession(previousSession: LanguageModelSession)
        -> LanguageModelSession
    {
        let entries = [
            previousSession.transcript.first, previousSession.transcript.last,
        ].compactMap { $0 }
        let condensedTranscript = Transcript(entries: entries)
        return LanguageModelSession(tools: [self.searchParkingTool], transcript: condensedTranscript)
    }
}

class SearchParkingTool: Tool {
    let name = "SearchParking"
    let description = "위도, 경도 정보를 토대로 주차장 조회"
    
    private let parkingRepository: ParkingRepository

    init(parkingRepository: ParkingRepository) {
        self.parkingRepository = parkingRepository
    }
    
    @Generable
    struct Arguments {
        @Guide(description: "사용자가 전달한 자연어 쿼리")
        let query: String
        @Guide(description: "사용자의 위도")
        let latitude: Double
        @Guide(description: "사용자의 경도")
        let longitude: Double
    }
    
    func call(arguments: Arguments) async throws -> [ParkingInfo] {
        print("Call SearchParkingTool: \(arguments)")
        let location = CLLocation(latitude: arguments.latitude, longitude: arguments.longitude)
        let mapItems = try await parkingRepository.searchParking(query: arguments.query, near: location)
        return mapItems
            .map { mapItem in
                ParkingInfo(
                    name: mapItem.name ?? "알 수 없는 주차장",
                    address: mapItem.address?.fullAddress,
                    latitude: mapItem.location.coordinate.latitude,
                    longitude: mapItem.location.coordinate.longitude,
                    distance: mapItem.location.distance(from: location).formattedDistance(), // 거리 계산 및 포맷팅
                    distanceInMeters: Int(mapItem.location.distance(from: location)),
                    phoneNumber: mapItem.phoneNumber
                )
            }
    }
}
