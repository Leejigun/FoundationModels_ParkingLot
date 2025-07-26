//
//  Foundation_ModelsApp.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import SwiftData
import SwiftUI

@main
struct Foundation_ModelsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {

            AppConfigurator.configureParkingView()
                .tabItem {
                    Label("주차장", systemImage: "car.fill")
                }

            //            TabView {
            //                AppConfigurator.configureParkingView()
            //                    .tabItem {
            //                        Label("주차장", systemImage: "car.fill")
            //                    }
            //
            //                AppConfigurator.configureWeatherView()
            //                    .tabItem {
            //                        Label("날씨", systemImage: "cloud.sun.fill")
            //                    }
            //            }
        }
        .modelContainer(sharedModelContainer)
    }
}
