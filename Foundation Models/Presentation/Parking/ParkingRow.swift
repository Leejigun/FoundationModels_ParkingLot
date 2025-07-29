//
//  ParkingRow.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import SwiftUI
import SwiftUI
import MapKit

import SwiftUI
import MapKit

struct ParkingRow: View {

    @State private var isLoadingSummary = true
    @State private var parkingSummary: ParkingSummary? = nil

    let parking: ParkingInfo
    weak var viewModel: ParkingViewModel? // ParkingViewModel이 ObservableObject여야 함

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // 전체적인 간격 확대
            // MARK: - 이름 및 현재 위치
            HStack(alignment: .firstTextBaseline) {
                Text(parking.name)
                    .font(.title3) // 이름 폰트 크기 키움
                    .fontWeight(.bold) // 볼드 처리
                    .lineLimit(1)
                    .minimumScaleFactor(0.8) // 공간 부족 시 폰트 크기 자동 조절

                if parking.isCurrentLocation {
                    Image(systemName: "location.fill")
                        .font(.subheadline) // 아이콘 크기 조정
                        .foregroundColor(.accentColor)
                    Text("현재 내 위치")
                        .font(.subheadline) // 텍스트 크기 조정
                        .foregroundColor(.accentColor)
                }
                Spacer() // 이름과 현재 위치를 왼쪽으로 붙이고 나머지 공간 확보
            }

            // MARK: - 요약 (Summary) - 이름 바로 아래에 배치하여 중요도 강조
            if let summary = parkingSummary?.summary, !summary.isEmpty {
                Text(summary)
                    .font(.body) // 본문 폰트 사용
                    .foregroundColor(.primary) // 기본 텍스트 색상
                    .lineLimit(2) // 두 줄까지 표시 가능
            }

            // MARK: - 주소, 구, 거리, 이동 시간 정보
            // 각 정보를 한 줄에 깔끔하게 배치 (HStack 활용)
            VStack(alignment: .leading, spacing: 4) { // 주소 관련 정보들 간 간격
                HStack(spacing: 5) {
                    Image(systemName: "map.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if let address = parking.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    if let district = parkingSummary?.district, !district.isEmpty {
                        Text("(\(district))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                HStack(spacing: 8) { // 거리 및 시간 정보들 간 간격
                    Image(systemName: "figure.walk.circle.fill") // 걷는 아이콘 추가
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let distance = parking.distance {
                        Text(distance)
                            .font(.subheadline)
                            .foregroundColor(parking.distanceInMeters ?? 0 < 500 ? .green : .secondary) // 500m 이내면 초록색
                    }
                    if let distCategory = parkingSummary?.distanceCategory, !distCategory.isEmpty {
                        Text("(\(distCategory))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let drivingTime = parkingSummary?.estimatedDrivingTime, !drivingTime.isEmpty {
                        Image(systemName: "car.fill") // 차량 아이콘 추가
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(drivingTime)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 5) // 이 블록 전체에 수직 패딩 추가

            // MARK: - 태그 및 카테고리
            HStack(spacing: 6) { // 태그 간 간격 조정
                if isLoadingSummary {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                } else {
                    // 태그 표시 (있을 경우만)
                    if let tags = parkingSummary?.tags, !tags.isEmpty {
                        ForEach(tags, id: \.self) { tag in
                            TagView(text: tag, color: .blue)
                        }
                    }

                    // 카테고리 태그 (있을 경우만)
                    if #available(iOS 13.0, *), let category = parking.pointOfInterestCategory {
                        if category == .parking {
                            TagView(text: "주차시설", color: .green) // 좀 더 명확한 이름
                        }
                    }
                }
            }

            // MARK: - 전화번호 및 웹사이트 (아이콘과 함께)
            VStack(alignment: .leading, spacing: 4) {
                let displayPhoneNumber = parkingSummary?.correctedPhoneNumber ?? parking.phoneNumber
                if let phone = displayPhoneNumber, !phone.isEmpty {
                    Button(action: {
                        if let url = URL(string: "tel://\(phone.filter("0123456789".contains))") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                            Text(phone)
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue) // 클릭 가능함을 강조
                    }
                }

                if let webSiteUrl = parking.webSiteUrl {
                    Link(destination: webSiteUrl) {
                        HStack(spacing: 5) {
                            Image(systemName: "link")
                                .font(.caption)
                            Text("웹사이트 방문하기")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding() // 셀 전체에 패딩 추가
        .background(Color.white) // 배경색 추가하여 경계 명확화
        .cornerRadius(10) // 모서리 둥글게
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3) // 은은한 그림자
        .padding(.horizontal, 10) // 좌우 바깥 여백
        .task {
            guard parkingSummary == nil else {
                isLoadingSummary = false
                return
            }
            isLoadingSummary = true
            defer { isLoadingSummary = false }

            self.parkingSummary = await viewModel?.getTagByParkingInfo(parking)
        }
    }
}

// TagView (이전과 동일)
struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.15))) // 배경색 진하게
            .foregroundColor(color)
    }
}
