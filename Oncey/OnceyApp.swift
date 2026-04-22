//
//  OnceyApp.swift
//  Oncey
//
//  Created by enivia on 2026/4/22.
//

import SwiftUI
import SwiftData

@main
struct OnceyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Album.self,
            Moment.self,
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
