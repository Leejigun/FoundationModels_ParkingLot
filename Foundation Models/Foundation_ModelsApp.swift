//
//  Foundation_ModelsApp.swift
//  Foundation Models
//
//  Created by bimo.ez on 7/26/25.
//

import SwiftUI
import SwiftData

@main
struct Foundation_ModelsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppConfigurator.configureWeatherView()
        }
        .modelContainer(sharedModelContainer)
    }
}
