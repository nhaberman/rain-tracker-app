import Foundation
import SwiftData
import AppIntents

enum RainPeriod: String, AppEnum {
    case today
    case month
    case year

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Rain Period")
    static let caseDisplayRepresentations: [RainPeriod: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "Today"),
        .month: DisplayRepresentation(title: "This Month"),
        .year: DisplayRepresentation(title: "This Year")
    ]
}

enum RainIntentError: LocalizedError {
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "Enter an amount greater than zero."
        }
    }
}

struct LogRainAmountIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Rain Amount"
    static let description = IntentDescription("Log a new rain measurement without opening the app.")

    @Parameter(title: "Amount", requestValueDialog: IntentDialog("How much rain fell?"))
    var amount: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) of rain")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else { throw RainIntentError.invalidAmount }

        let useMetric = UserDefaults.standard.bool(forKey: "useMetric")
        let stored = Double.fromDisplay(amount, metric: useMetric)

        let container = try RainStore.makeModelContainer(cloudKitSyncing: false)
        let context = ModelContext(container)
        context.insert(RainObservation(amount: stored, date: .now, timeOfDay: TimeOfDay.from(date: .now)))
        context.saveAndRefreshWidgets()

        let unit = useMetric ? "mm" : "in"
        return .result(dialog: "Logged \(amount.formatted(.number.precision(.fractionLength(2)))) \(unit) of rain.")
    }
}

struct GetRainTotalIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Rain Total"
    static let description = IntentDescription("Get the total rainfall for today, this month, or this year.")

    @Parameter(title: "Period", default: .today)
    var period: RainPeriod

    static var parameterSummary: some ParameterSummary {
        Summary("Get rain total for \(\.$period)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let container = try RainStore.makeModelContainer(cloudKitSyncing: false)
        let context = ModelContext(container)
        let observations = try context.fetch(FetchDescriptor<RainObservation>())
        let totals = RainStore.totals(from: observations)

        let value: Double
        let label: String
        switch period {
        case .today: value = totals.today; label = "today"
        case .month: value = totals.month; label = "this month"
        case .year: value = totals.year; label = "this year"
        }

        let useMetric = UserDefaults.standard.bool(forKey: "useMetric")
        let displayValue = value.toDisplay(metric: useMetric)
        let unit = useMetric ? "mm" : "in"

        return .result(
            value: displayValue,
            dialog: "\(displayValue.formatted(.number.precision(.fractionLength(2)))) \(unit) of rain \(label)."
        )
    }
}

struct RainTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogRainAmountIntent(),
            phrases: [
                "Log rain in \(.applicationName)",
                "Log a rain measurement in \(.applicationName)"
            ],
            shortTitle: "Log Rain Amount",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: GetRainTotalIntent(),
            phrases: [
                "Get my rain total in \(.applicationName)",
                "Check rain total in \(.applicationName)"
            ],
            shortTitle: "Rain Total",
            systemImageName: "chart.bar.fill"
        )
    }
}
