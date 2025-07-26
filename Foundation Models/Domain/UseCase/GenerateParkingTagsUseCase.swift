//
//  GenerateParkingTagsUseCase.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import CoreLocation
import Foundation
import FoundationModels
import MapKit
import Playgrounds

protocol GenerateParkingTagsUseCase {
    func execute(mapItem: MKMapItem) async throws -> [String]
    func execute(parkingInfo: ParkingInfo) async throws -> [String]
}

@Generable(description: "주차장 특성 태그")
struct Tags {
    @Guide(description: "MKMapItem 기반으로 주차장의 특징을 태그로 생성")
    public let tags: [String]
}

actor DefaultGenerateParkingTagsUseCase: GenerateParkingTagsUseCase {

    var session = LanguageModelSession(instructions: "MKMapItem 정보로 주차장 태그를 생성")

    func execute(mapItem: MKMapItem) async throws -> [String] {
        while session.isResponding {
            try await Task.sleep(nanoseconds: 100_000_000)  // 대기 시간 100ms로 늘려 안정성 강화
        }

        let name = mapItem.name ?? "정보 없음"
        let category = mapItem.pointOfInterestCategory?.rawValue ?? "정보 없음"
        let address = mapItem.address?.fullAddress ?? "정보 없음"

        let prompt = """
            다음 주차장 정보에서 가장 핵심적인 특징을 나타내는 태그를 5개 이내로 생성해줘.
            예시 태그: #24시간, #공영, #무료, #넓은, #지하주차장, #야외주차장, #마트주차장, #병원주차장, #쇼핑몰주차장, #식당주차장, #공항주차장, #역주차장, #환승주차장, #전기차충전

            ---
            [주차장 정보]
            이름: \(name)
            카테고리: \(category)
            주소: \(address)
            """
        return try await response(to: prompt)
    }

    func execute(parkingInfo: ParkingInfo) async throws -> [String] {
        while session.isResponding {
            try await Task.sleep(nanoseconds: 100_000_000)  // 대기 시간 100ms로 늘려 안정성 강화
        }

        let name = parkingInfo.name
        let distance = parkingInfo.distance ?? "정보없음"
        let address = parkingInfo.address ?? "정보없음"

        let prompt = """
            다음 주차장 정보에서 가장 핵심적인 특징을 나타내는 태그를 5개 이내로 생성해줘.
            예시 태그: #24시간, #공영, #무료, #넓은, #지하주차장, #야외주차장, #마트주차장, #병원주차장, #쇼핑몰주차장, #식당주차장, #공항주차장, #역주차장, #환승주차장, #전기차충전, #가까운, #먼

            ---
            [주차장 정보]
            이름: \(name)
            거리: \(distance)
            주소: \(address)
            """
        return try await response(to: prompt)
    }

    private func response(to prompt: String) async throws -> [String] {
        let startTime = Date()
        do {
            let response = try await session.respond(
                to: prompt,
                generating: Tags.self
            )
            
            let timeElapsed = Date().timeIntervalSince(startTime)
            print(
                "DEBUG: Model responded in \(String(format: "%.2f", timeElapsed)) seconds for prompt:\n\(prompt)\n- \(response.content.tags)\n"
            )
            
            return response.content.tags
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
        return LanguageModelSession(transcript: condensedTranscript)
    }
}
