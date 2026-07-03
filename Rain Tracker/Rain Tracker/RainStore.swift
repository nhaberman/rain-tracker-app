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

struct RainTotals {
    let today: Double
    let month: Double
    let year: Double
    let rainyDaysThisMonth: Int
}

extension RainStore {
    /// Sums observations into today/month/year-to-date totals, all in stored (inches) units.
    static func totals(from observations: [RainObservation], now: Date = .now) -> RainTotals {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        var todayTotal: Double = 0
        var monthTotal: Double = 0
        var yearTotal: Double = 0
        var monthDays: Set<Date> = []

        for obs in observations {
            guard let date = obs.date else { continue }
            let year = calendar.component(.year, from: date)
            guard year == currentYear else { continue }
            yearTotal += obs.amount

            let month = calendar.component(.month, from: date)
            if month == currentMonth {
                monthTotal += obs.amount
                monthDays.insert(calendar.startOfDay(for: date))
            }

            if calendar.isDate(date, inSameDayAs: startOfToday) {
                todayTotal += obs.amount
            }
        }

        return RainTotals(today: todayTotal, month: monthTotal, year: yearTotal, rainyDaysThisMonth: monthDays.count)
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
    static let title: LocalizedStringResource = "Open to Log Rain"
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
