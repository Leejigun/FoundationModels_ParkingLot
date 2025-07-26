//
//  ParkingView.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import SwiftUI
import MapKit // MapKit의 특정 타입 (예: MKCoordinateRegion)을 사용하기 위해 임포트

struct ParkingView: View {
    @State var viewModel: ParkingViewModel
    @State private var searchQuery: String = "주차장" // 검색어 입력 필드

    var body: some View {
        NavigationView {
            VStack {
                TextField("검색어 (예: 주차장, 공영주차장)", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button("주차장 검색") {
                    if let location = viewModel.currentLocation {
                        Task {
                            await viewModel.searchParking(query: searchQuery, near: location)
                        }
                    } else {
                        viewModel.errorMessage = "현재 위치를 가져올 수 없습니다. 위치 권한을 확인해주세요."
                    }
                }
                .padding(.vertical, 5)

                if viewModel.isLoading {
                    ProgressView("주차장 정보 불러오는 중...")
                        .padding()
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                List {
                    ForEach(viewModel.parkingPlaces) { parking in
                        ParkingRow(parking: parking)
                    }
                }
            }
            .navigationTitle("주변 주차장 검색")
            .onAppear {
                viewModel.requestLocationPermissionAndSearch() // 앱 시작 시 위치 권한 요청 및 초기 검색
            }
        }
    }
}

struct ParkingRow: View {
    let parking: ParkingInfo

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
            if let phone = parking.phoneNumber {
                Text("전화: \(phone)")
                    .font(.caption)
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
    }
}
