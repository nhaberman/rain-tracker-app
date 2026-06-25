import Foundation
import SwiftData
import WidgetKit
import AppIntents

extension ModelContext {
    func saveAndRefreshWidgets() {
        try? save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum RainStore {
    static let appGroupIdentifier = "group.nickhaberman.Rain-Tracker"
    static let pendingAddObservationKey = "pendingAddObservation"

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

enum RainAppScreen: String, AppEnum {
    case logRain

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Rain Tracker Screen")
    static let caseDisplayRepresentations: [RainAppScreen: DisplayRepresentation] = [
        .logRain: DisplayRepresentation(title: "Log Rain")
    ]
}

struct LogRainIntent: OpenIntent {
    static let title: LocalizedStringResource = "Log Rain"
    static let description = IntentDescription("Open Rain Tracker to log a new measurement.")

    @Parameter(title: "Screen")
    var target: RainAppScreen

    init() {
        self.target = .logRain
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: RainStore.appGroupIdentifier)?
            .set(true, forKey: RainStore.pendingAddObservationKey)
        return .result()
    }
}
