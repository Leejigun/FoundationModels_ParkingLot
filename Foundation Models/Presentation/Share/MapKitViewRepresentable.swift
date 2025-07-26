//
//  MapKitViewRepresentable.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import SwiftUI
import MapKit

struct MapKitViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [MKPointAnnotation]
    var onRegionChange: ((CLLocationCoordinate2D) -> Void)?
    var onVisibleRectChange: ((MKMapRect) -> Void)? // <-- 추가: 보이는 영역 변경 알림

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.region.center.latitude != region.center.latitude ||
           uiView.region.center.longitude != region.center.longitude ||
           uiView.region.span.latitudeDelta != region.span.latitudeDelta ||
           uiView.region.span.longitudeDelta != region.span.longitudeDelta {
            uiView.setRegion(region, animated: context.transaction.animation != nil)
        }

        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapKitViewRepresentable
        private var timer: Timer?

        init(_ parent: MapKitViewRepresentable) {
            self.parent = parent
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.region = mapView.region

            // MARK: - 추가된 부분
            // 지도의 보이는 영역이 변경될 때마다 ViewModel에 알립니다.
            // 이 역시 디바운스 로직을 태워서 너무 빈번하게 호출되지 않도록 합니다.
            timer?.invalidate() // 기존 타이머 무효화
            timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.parent.onRegionChange?(mapView.centerCoordinate) // 지도 중심 변경 알림
                self.parent.onVisibleRectChange?(mapView.visibleMapRect) // <-- 추가: 보이는 영역 변경 알림
            }
        }
    }
}
