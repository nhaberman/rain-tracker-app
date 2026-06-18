//
//  Rain_TrackerApp.swift
//  Rain Tracker
//
//  Created by Nick Haberman on 6/18/26.
//

import SwiftUI
import SwiftData

@main
struct Rain_TrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RainObservation.self,
        ])
        #if targetEnvironment(simulator)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        #else
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        #endif

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
