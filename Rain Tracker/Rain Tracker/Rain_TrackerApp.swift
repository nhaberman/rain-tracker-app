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
        do {
            return try RainStore.makeModelContainer(cloudKitSyncing: true)
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
