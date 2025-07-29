//
//  GenerateParkingSummaryUseCase.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import CoreLocation
import Foundation
import FoundationModels
import MapKit
import Playgrounds

protocol GenerateParkingSummaryUseCase {
    func execute(parkingInfo: ParkingInfo) async throws -> ParkingSummary?
}

// 1. 요약 (Summarization)
// 2. 추출 (Extraction)
// 3. 분류 (Classification)
// 4. 태깅 (Tagging)
// 5. 구성 (Composition)
// 6. 교정 (Revision)

@Generable(description: "주차장 특성 태그")
struct ParkingSummary {
    @Guide(description: "해당 주차장을 한 문장으로 요약")
    public let summary: String? // 요약
    @Guide(description: "주차장이 위치한 '구' 정보 (예: 강남구, 종로구). 주소 정보에서 추출되어야 한다.")
    public let district: String? // 추출
    @Guide(description: "사용자의 현재 위치로부터 주차장의 상대적인 거리 분류 (예: '초근접', '근거리', '원거리').")
    public let distanceCategory: String? // 분류
    @Guide(description: "주차장 정보에서 가장 핵심적인 특징을 나타내는 태그, 앞에 #으로 시작해야 한다.", .maximumCount(3))
    public let tags: [String] // 태깅
    @Guide(description: "사용자의 현재 위치에서 주차장까지 차량으로 이동하는 데 걸리는 예상 시간 (예: '약 5분', '10분 미만').")
    public let estimatedDrivingTime: String? // 구성
    @Guide(description: "주차장 전화번호를 한국 국내 형식으로 교정 (예: '02-385-2193' 또는 02) 385-2193.")
    public let correctedPhoneNumber: String? // 교정
    
    public var description: String {
        var parts: [String] = []
        
        if let summary = summary {
            parts.append("Summary: \"\(summary)\"")
        }
        if let district = district {
            parts.append("District: \(district)")
        }
        if let distanceCategory = distanceCategory {
            parts.append("Distance Category: \(distanceCategory)")
        }
        if !tags.isEmpty {
            parts.append("Tags: [\(tags.joined(separator: ", "))]")
        }
        if let estimatedDrivingTime = estimatedDrivingTime {
            parts.append("Estimated Driving Time: \(estimatedDrivingTime)")
        }
        if let correctedPhoneNumber = correctedPhoneNumber {
            parts.append("Corrected Phone: \(correctedPhoneNumber)")
        }
        
        // 모든 정보가 없을 경우를 대비
        if parts.isEmpty {
            return "Empty ParkingSummary"
        }
        
        return "ParkingSummary(\n  \(parts.joined(separator: ",\n  "))\n)"
    }
}

actor DefaultGenerateParkingTagsUseCase: GenerateParkingSummaryUseCase {

    var session = LanguageModelSession()

    func execute(parkingInfo: ParkingInfo) async throws -> ParkingSummary? {
        while session.isResponding {
            try await Task.sleep(nanoseconds: 100_000_000)  // 대기 시간 100ms로 늘려 안정성 강화
        }
        
        let prompt = """
        당신은 사용자의 주차장 검색 요청에 응답하는 전문 AI입니다. 다음 [주차장 정보]를 분석하여 JSON 형식의 'ParkingSummary' 객체를 생성해야 합니다. 각 필드의 설명을 정확히 따르세요.

        ---
        [필드 설명]
        - summary: 해당 주차장을 한 문장으로 간결하게 요약해 주세요.
        - district: 주차장이 위치한 '구' 정보를 주소에서 추출해 주세요. (예: 강남구, 종로구)
        - distanceCategory: 사용자의 현재 위치로부터 주차장의 상대적인 거리를 '초근접'(500m 이내), '근거리'(500m ~ 2km), '원거리'(2km 초과) 중 하나로 분류해 주세요.
        - tags: 주차장 정보에서 가장 핵심적인 특징을 나타내는 태그를 최대 3개까지 생성해 주세요. 각 태그는 '#'으로 시작해야 합니다.
          예시 태그: [#24시간, #공영, #무료, #넓은, #지하주차장, #야외주차장, #마트주차장, #병원주차장, #쇼핑몰주차장, #식당주차장, #공항주차장, #역주차장, #환승주차장, #전기차충전, #가까운, #먼, #경차할인, #발렛파킹, #주차대수많음]
        - estimatedDrivingTime: 주차장까지 차량으로 이동하는 데 걸리는 예상 시간을 추정하여 '약 N분', 'N분 미만'과 같이 표시해 주세요. (교통 상황은 고려하지 않은 대략적인 시간)
        - correctedPhoneNumber: 주차장의 전화번호가 있다면 한국 국내 형식으로 교정해 주세요. '+82 2-385-2193'은 '02-385-2193' 또는 '02) 385-2193'처럼 변경해 주세요. 전화번호가 없는 경우 null로 표시합니다.

        ---
        [주차장 정보]
        \(await parkingInfo.description)
        """
        
        return try await response(to: prompt)
    }

    private func response(to prompt: String) async throws -> ParkingSummary? {
        let startTime = Date()
        do {
            let response = try await session.respond(
                to: prompt,
                generating: ParkingSummary.self
            )
            
            let timeElapsed = Date().timeIntervalSince(startTime)
            print(
                "\nDEBUG: Model responded in \(String(format: "%.2f", timeElapsed)) seconds for prompt:\n\(prompt)\n- \(response.content.description)\n"
            )
            
            return response.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            
            let timeElapsed = Date().timeIntervalSince(startTime)
            print(
                "\nDEBUG: Model exceeded context window in \(String(format: "%.2f", timeElapsed)) seconds for prompt:\n\(prompt)\n- exceededContextWindowSize\n"
            )
            
            session = newSession(previousSession: session)
            return try? await response(to: prompt)
        } catch {
            
            let timeElapsed = Date().timeIntervalSince(startTime)
            print(
                "\nDEBUG: Model exceeded context window in \(String(format: "%.2f", timeElapsed)) seconds for prompt:\n\(prompt)\n- \(error.localizedDescription)\n"
            )
            
            return nil
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
