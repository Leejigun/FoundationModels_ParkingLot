//
//  ParkingRow.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import SwiftUI

struct ParkingRow: View {
    
    @State var isLoadingTags = true
    @State var tags: [String] = []
    
    let parking: ParkingInfo
    weak var viewModel: ParkingViewModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(parking.name)
                .font(.headline)
            if let address = parking.address {
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            HStack {
                if let distance = parking.distance {
                    Text("거리: \(distance)")
                        .font(.caption)
                }
                if let rating = parking.rating {
                    Text("평점: \(rating)점")
                        .font(.caption)
                }
            }
            
            // MARK: - 태그 로딩 상태 및 태그 표시
            if isLoadingTags {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7)
            } else if !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if let phone = parking.phoneNumber {
                Text("전화: \(phone)")
                    .font(.caption)
                // Link("전화 걸기", destination: URL(string: "tel://\(phone)")!) // 실제 전화 걸기 기능 추가 가능
            }
            if let hours = parking.openingHours, !hours.isEmpty {
                ForEach(hours, id: \.self) { hour in
                    Text(hour)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if let mapURL = parking.mapURL {
                Link("지도에서 보기", destination: mapURL)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            if let errorMsg = parking.errorMessage {
                Text(errorMsg)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 5)
        .task {
            guard tags.isEmpty else {
                isLoadingTags = false
                return
            }
            isLoadingTags = true
            self.tags = await viewModel?.getTagByParkingInfo(parking) ?? []
            isLoadingTags = false
        }
    }
}
