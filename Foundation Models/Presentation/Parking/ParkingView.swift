//
//  ParkingView.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//
// ParkingView.swift (수정)

import SwiftUI
import MapKit

struct ParkingView: View {
    @State var viewModel: ParkingViewModel
    @State private var addressQuery: String = "" // <-- 변수명 변경: addressQuery
    @State private var showParkingListSheet: Bool = false
    @FocusState private var isSearchFieldFocused: Bool // 키보드 관리용

    var body: some View {
        ZStack(alignment: .bottom) {
            MapKitViewRepresentable(
                region: $viewModel.mapRegion,
                annotations: viewModel.parkingAnnotations
            ) { newCenterCoordinate in
                Task { @MainActor in
                    viewModel.mapCenterDidChange(to: newCenterCoordinate)
                }
            } onVisibleRectChange: { newMapRect in
                Task { @MainActor in
                    viewModel.mapVisibleRectDidChange(to: newMapRect)
                }
            }
            .edgesIgnoringSafeArea(.all)

            // MARK: - 검색 바 및 버튼 재구성
            VStack {
                HStack {
                    TextField("주소 또는 장소 검색 (예: 판교역)", text: $addressQuery) // <-- 텍스트 필드 텍스트 변경
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isSearchFieldFocused) // 포커스 상태 바인딩
                        .onSubmit { // 키패드에서 검색 버튼 눌렀을 때
                            Task {
                                await viewModel.searchAddressAndMoveMap(addressQuery: addressQuery)
                                isSearchFieldFocused = false // 검색 후 키패드 내리기
                            }
                        }

                    Button(action: {
                        Task {
                            await viewModel.searchAddressAndMoveMap(addressQuery: addressQuery)
                            isSearchFieldFocused = false // 검색 후 키패드 내리기
                        }
                    }) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain) // 버튼 스타일 제거 (아이콘만 보이게)
                }
                .padding(.horizontal)
                .background(Color.white.opacity(0.8)) // 배경 추가
                .cornerRadius(8)
                .padding(.top, 10)

                Spacer()
            }
            .padding(.horizontal) // HStack이 ZStack의 가장자리에 붙도록

            Image(systemName: "mappin.and.ellipse")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
                .offset(y: -25)
                .shadow(radius: 5)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .offset(y: -50)
            }
        }
        .onAppear {
            viewModel.requestLocationPermissionAndInitialSearch()
        }
        .sheet(isPresented: $showParkingListSheet) {
            NavigationView {
                List {
                    ForEach(viewModel.visibleParkingPlaces) { parking in
                        ParkingRow(parking: parking)
                    }
                }
                .navigationTitle("화면 내 주차장 리스트")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("닫기") {
                            showParkingListSheet = false
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .frame(width: 150, height: 50)
                    .background(Color.accentColor.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 60)
            } else if viewModel.errorMessage == nil {
                Button {
                    showParkingListSheet.toggle()
                } label: {
                    Label("리스트 보기 (\(viewModel.visibleParkingPlaces.count)개)", systemImage: "list.bullet")
                        .font(.headline)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 60)
            }
        }
    }
}

// ParkingRow는 기존과 동일
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
    }
}
