import Foundation
import SwiftData
import WidgetKit

extension ModelContext {
    func saveAndRefreshWidgets() {
        try? save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum RainStore {
    static let appGroupIdentifier = "group.nickhaberman.Rain-Tracker"

    static func makeModelContainer(cloudKitSyncing: Bool) throws -> ModelContainer {
        let schema = Schema([RainObservation.self])

        #if targetEnvironment(simulator)
        let cloudKit: ModelConfiguration.CloudKitDatabase = .none
        #else
        let cloudKit: ModelConfiguration.CloudKitDatabase = cloudKitSyncing ? .automatic : .none
        #endif

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: cloudKit
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
