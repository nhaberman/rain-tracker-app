//
//  MeasurementsView.swift
//  Rain Tracker
//
//  Created by Nick Haberman on 6/18/26.
//

import Foundation
import SwiftUI
import SwiftData

enum MeasurementFilter: String, CaseIterable {
    case all = "All Measurements"
    case currentYear = "Current Year"
    case last30Days = "Last 30 Days"

    var systemImage: String {
        switch self {
        case .last30Days: return "30.calendar"
        case .currentYear: return "calendar.badge.clock"
        case .all: return "list.bullet.rectangle.portrait"
        }
    }
}

struct MeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RainObservation.date, order: .reverse) private var rawObservations: [RainObservation]

    private var observations: [RainObservation] {
        rawObservations.sorted {
            let d0 = $0.date ?? .distantPast, d1 = $1.date ?? .distantPast
            guard Calendar.current.isDate(d0, inSameDayAs: d1) else { return d0 > d1 }
            return $0.resolvedTimeOfDay.sortOrder > $1.resolvedTimeOfDay.sortOrder
        }
    }

    @State private var showingAdd = false
    @State private var showingSettings = false
    @AppStorage("useMetric") private var useMetric = false
    @AppStorage("measurementFilter") private var filterRawValue: String = MeasurementFilter.last30Days.rawValue
    private var filter: MeasurementFilter { MeasurementFilter(rawValue: filterRawValue) ?? .last30Days }
    private func setFilter(_ f: MeasurementFilter) { filterRawValue = f.rawValue }

    private var visibleObservations: [RainObservation] {
        let now = Date.now
        let cal = Calendar.current
        switch filter {
        case .all:
            return observations
        case .last30Days:
            let cutoff = cal.date(byAdding: .day, value: -30, to: cal.startOfDay(for: now))!
            return observations.filter { ($0.date ?? now) >= cutoff }
        case .currentYear:
            let year = cal.component(.year, from: now)
            return observations.filter { cal.component(.year, from: $0.date ?? now) == year }
        }
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private var groupedObservations: [(key: String, sortDate: Date, observations: [RainObservation])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: visibleObservations) { obs -> Date in
            let d = obs.date ?? .now
            return cal.date(from: cal.dateComponents([.year, .month], from: d))!
        }
        return grouped
            .map { (key: Self.monthFormatter.string(from: $0.key), sortDate: $0.key, observations: $0.value) }
            .sorted { $0.sortDate > $1.sortDate }
    }

    private var monthTotal: Double {
        let cal = Calendar.current
        let now = Date.now
        return observations
            .filter { cal.isDate($0.date ?? now, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    private var yearTotal: Double {
        let cal = Calendar.current
        let now = Date.now
        return observations
            .filter { cal.isDate($0.date ?? now, equalTo: now, toGranularity: .year) }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            List {
                if !observations.isEmpty {
                    Section {
                        HStack {
                            Label("This month", systemImage: "drop.fill")
                            Spacer()
                            Text(monthTotal.toDisplay(metric: useMetric), format: .number.precision(.fractionLength(useMetric ? 0 : 2)))
                            Text(useMetric ? "mm" : "in").foregroundStyle(.secondary)
                        }
                        .font(.headline)
                        HStack {
                            Label { Text("This year") } icon: { TripleDropIcon() }
                            Spacer()
                            Text(yearTotal.toDisplay(metric: useMetric), format: .number.precision(.fractionLength(useMetric ? 0 : 2)))
                            Text(useMetric ? "mm" : "in").foregroundStyle(.secondary)
                        }
                        .font(.headline)
                    }
                }

                if observations.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No readings yet",
                            systemImage: "cloud.rain",
                            description: Text("Tap + to log your first rain gauge reading.")
                        )
                    }
                } else if visibleObservations.isEmpty {
                    Section {
                        let periodLabel = filter == .currentYear ? "this year" : "the last 30 days"
                        ContentUnavailableView(
                            "No readings for \(periodLabel)",
                            systemImage: "cloud.sun.rain",
                            description: Text("Tap \(Image(systemName: "line.3.horizontal.decrease.circle.fill")) to view more measurements.")
                        )
                    }
                } else if filter == .last30Days {
                    Section {
                        ForEach(visibleObservations) { observation in
                            NavigationLink(destination: ObservationDetailView(observation: observation)) {
                                ObservationRow(observation: observation)
                            }
                        }
                        .onDelete(perform: delete)
                    } footer: {
                        footerText
                    }
                } else {
                    ForEach(groupedObservations, id: \.key) { group in
                        Section(group.key) {
                            ForEach(group.observations) { observation in
                                NavigationLink(destination: ObservationDetailView(observation: observation)) {
                                    ObservationRow(observation: observation)
                                }
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    modelContext.delete(group.observations[index])
                                }
                            }
                        }
                    }
                    Section { } footer: {
                        footerText
                    }
                }
            }
            .navigationTitle("Rain Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 16) {
                        Button { showingSettings = true } label: {
                            Image(systemName: "gear")
                        }
                        .hoverEffect()

                        Menu {
                            Picker("Filter", selection: Binding(get: { filter }, set: { setFilter($0) })) {
                                ForEach(MeasurementFilter.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.inline)
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle\(filter == .all ? "" : ".fill")")
                                .foregroundColor(filter == .all ? .primary : Color.accentColor)
                        }
                        .hoverEffect()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.accentColor)
                    }
                    .hoverEffect()
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddObservationView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(visibleObservations[index])
        }
    }

    @ViewBuilder private var footerText: some View {
        if filter == .all || visibleObservations.count == observations.count {
            Text("Showing all \(observations.count) measurements recorded.")
        } else {
            Text("Showing \(visibleObservations.count) of \(observations.count) total measurements. Tap \(Image(systemName: "line.3.horizontal.decrease.circle.fill")) to view more.")
        }
    }
}

struct ObservationRow: View {
    let observation: RainObservation
    @AppStorage("useTimeOfDay") private var useTimeOfDay = true
    @AppStorage("useMetric") private var useMetric = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(observation.date ?? .now, style: .date)
                    .font(.subheadline)
                if useTimeOfDay && observation.resolvedTimeOfDay != .unknown {
                    Text(observation.resolvedTimeOfDay.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(observation.amount.toDisplay(metric: useMetric), format: .number.precision(.fractionLength(useMetric ? 0 : 2)))
                    .font(.body.monospacedDigit())
                    .bold()
                Text(useMetric ? "mm" : "in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ObservationDetailView: View {
    let observation: RainObservation
    @AppStorage("useTimeOfDay") private var useTimeOfDay = true
    @AppStorage("useMetric") private var useMetric = false
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var timeOfDay: TimeOfDay = .morning

    private var amount: Double? { Double(amountText) }
    private var canSave: Bool { amount != nil && amount! > 0 }

    var body: some View {
        Form {
            Section("Reading") {
                if isEditing {
                    HStack {
                        TextField(useMetric ? "0" : "0.00", text: $amountText)
                            .keyboardType(useMetric ? .numberPad : .decimalPad)
                            .onChange(of: amountText) { _, new in
                                if useMetric {
                                    amountText = new.filter { $0.isNumber }
                                } else {
                                    limitToTwoDecimals(new)
                                }
                            }
                        Text(useMetric ? "mm" : "inches")
                            .foregroundStyle(.secondary)
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                    if useTimeOfDay {
                        Picker("Time of Day", selection: $timeOfDay) {
                            ForEach(TimeOfDay.selectableCases, id: \.self) { t in
                                Text(t.label).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    LabeledContent("Amount") {
                        Text("\(observation.amount.toDisplay(metric: useMetric), format: .number.precision(.fractionLength(useMetric ? 0 : 2))) \(useMetric ? "mm" : "in")")
                    }
                    LabeledContent("Date") {
                        Text(observation.date ?? .now, format: .dateTime.year().month().day())
                    }
                    if useTimeOfDay && observation.resolvedTimeOfDay != .unknown {
                        LabeledContent("Time of Day") {
                            Text(observation.resolvedTimeOfDay.label)
                        }
                    }
                }
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isEditing {
                    Button("Save") {
                        commitEdit()
                    }
                    .disabled(!canSave)
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                }
            }
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
        }
    }

    private func limitToTwoDecimals(_ value: String) {
        let separator = Locale.current.decimalSeparator ?? "."
        let parts = value.components(separatedBy: separator)
        if parts.count >= 2, parts[1].count > 2 {
            amountText = parts[0] + separator + String(parts[1].prefix(2))
        }
    }

    private func startEditing() {
        let display = observation.amount.toDisplay(metric: useMetric)
        amountText = useMetric ? String(Int(display)) : String(display)
        date = observation.date ?? .now
        timeOfDay = observation.resolvedTimeOfDay == .unknown ? .morning : observation.resolvedTimeOfDay
        isEditing = true
    }

    private func commitEdit() {
        guard let amount, amount > 0 else { return }
        observation.amount = Double.fromDisplay(amount, metric: useMetric)
        observation.date = Calendar.current.startOfDay(for: date)
        observation.timeOfDay = useTimeOfDay ? timeOfDay : .unknown
        isEditing = false
    }
}


struct DropPlusIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "drop.fill")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.accentColor)
            Image(systemName: "plus")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .offset(y: 3)
        }
        .frame(width: 20, height: 20)
    }
}

struct TripleDropIcon: View {
    private let dropSize: CGFloat = 13
    private let outlineSize: CGFloat = 15.5

    var body: some View {
        ZStack {
            singleDrop(offset: CGSize(width: -6, height: -3))   // left: back, highest
            singleDrop(offset: CGSize(width: 6, height: -1))    // right: middle
            singleDrop(offset: CGSize(width: 0, height: 3))     // center: front, lowest
        }
        .frame(width: 22, height: 22)
    }

    private func singleDrop(offset: CGSize) -> some View {
        ZStack {
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .frame(width: outlineSize, height: outlineSize)
                .foregroundStyle(Color(uiColor: .secondarySystemGroupedBackground))
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .frame(width: dropSize, height: dropSize)
                .foregroundStyle(Color.accentColor)
        }
        .offset(offset)
    }
}

#Preview {
    MeasurementsView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
