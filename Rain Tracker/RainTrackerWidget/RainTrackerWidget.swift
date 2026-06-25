//
//  RainTrackerWidget.swift
//  RainTrackerWidget
//
//  Created by Nick Haberman on 6/24/26.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct DropPlusIcon: View {
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Image(systemName: "drop.fill")
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.tint)
            Image(systemName: "plus")
                .font(.system(size: size * 0.4, weight: .heavy))
                .foregroundStyle(.white)
                .offset(y: size * 0.1)
        }
    }
}



struct RainEntry: TimelineEntry {
    let date: Date
    let todayTotal: Double
    let monthTotal: Double
    let yearTotal: Double
    let rainyDaysThisMonth: Int
}

struct RainProvider: TimelineProvider {
    func placeholder(in context: Context) -> RainEntry {
        RainEntry(date: .now, todayTotal: 0.25, monthTotal: 2.40, yearTotal: 18.75, rainyDaysThisMonth: 6)
    }

    func getSnapshot(in context: Context, completion: @escaping (RainEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RainEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> RainEntry {
        let now = Date.now
        do {
            let container = try RainStore.makeModelContainer(cloudKitSyncing: false)
            let context = ModelContext(container)
            let observations = try context.fetch(FetchDescriptor<RainObservation>())
            return summarize(observations, now: now)
        } catch {
            return RainEntry(date: now, todayTotal: 0, monthTotal: 0, yearTotal: 0, rainyDaysThisMonth: 0)
        }
    }

    private func summarize(_ observations: [RainObservation], now: Date) -> RainEntry {
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

        return RainEntry(
            date: now,
            todayTotal: todayTotal,
            monthTotal: monthTotal,
            yearTotal: yearTotal,
            rainyDaysThisMonth: monthDays.count
        )
    }
}

struct RainBigStat: View {
    let label: String
    let value: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.tint)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value, format: .number.precision(.fractionLength(2)))
                    .font(.title2.bold().monospacedDigit())
                Text("in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RainTrackerWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: RainEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallBody
        default:
            mediumBody
        }
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            todayCallout
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 2) {
                statRow(label: "Month", value: entry.monthTotal)
                statRow(label: "Year", value: entry.yearTotal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumBody: some View {
        HStack(spacing: 16) {
            todayCallout
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                RainBigStat(label: "This Month", value: entry.monthTotal, icon: "calendar")
                RainBigStat(label: "Year to Date", value: entry.yearTotal, icon: "chart.bar.fill")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var todayCallout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.tint)
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.todayTotal, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                Text("in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statRow(label: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(value, format: .number.precision(.fractionLength(2)))
                .font(.caption.monospacedDigit())
                .bold()
            Text("in")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct RainTotalsWidgetEntryView: View {
    var entry: RainEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RainBigStat(label: "This Month", value: entry.monthTotal, icon: "calendar")
            RainBigStat(label: "Year to Date", value: entry.yearTotal, icon: "chart.bar.fill")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct RainTrackerWidget: Widget {
    let kind: String = "RainTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RainProvider()) { entry in
            RainTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rain Tracker")
        .description("See today's rainfall plus month and year totals.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RainTotalsWidget: Widget {
    let kind: String = "RainTotalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RainProvider()) { entry in
            RainTotalsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rain Totals")
        .description("See this month's and year-to-date rainfall totals.")
        .supportedFamilies([.systemSmall])
    }
}

struct RainAddEntry: TimelineEntry {
    let date: Date
}

struct RainAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> RainAddEntry {
        RainAddEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (RainAddEntry) -> Void) {
        completion(RainAddEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RainAddEntry>) -> Void) {
        completion(Timeline(entries: [RainAddEntry(date: .now)], policy: .never))
    }
}

struct RainAddWidgetEntryView: View {
    var entry: RainAddEntry

    var body: some View {
        VStack(spacing: 10) {
            DropPlusIcon(size: 56)
            Text("Log Rain")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "raintracker://add"))
    }
}

struct RainAddWidget: Widget {
    let kind: String = "RainAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RainAddProvider()) { entry in
            RainAddWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Log Rain")
        .description("Tap to quickly log a new rain measurement.")
        .supportedFamilies([.systemSmall])
    }
}

struct RainAddControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "nickhaberman.Rain-Tracker.LogRainControl") {
            ControlWidgetButton(action: LogRainIntent()) {
                Label("Log Rain", systemImage: "drop.fill")
            }
        }
        .displayName("Log Rain")
        .description("Quickly open Rain Tracker to log a measurement.")
    }
}

struct RainCalendarDay: Hashable {
    let dayNumber: Int?
    let total: Double
    let isToday: Bool
}

struct RainCalendarEntry: TimelineEntry {
    let date: Date
    let monthTitle: String
    let weekdaySymbols: [String]
    let days: [RainCalendarDay]
}

struct RainCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> RainCalendarEntry {
        Self.makeEntry(observations: [], now: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (RainCalendarEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RainCalendarEntry>) -> Void) {
        let entry = loadEntry()
        let cal = Calendar.current
        let refreshAt = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: .now))
            ?? .now.addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }

    private func loadEntry() -> RainCalendarEntry {
        do {
            let container = try RainStore.makeModelContainer(cloudKitSyncing: false)
            let context = ModelContext(container)
            let observations = try context.fetch(FetchDescriptor<RainObservation>())
            return Self.makeEntry(observations: observations, now: .now)
        } catch {
            return Self.makeEntry(observations: [], now: .now)
        }
    }

    private static func makeEntry(observations: [RainObservation], now: Date) -> RainCalendarEntry {
        let cal = Calendar.current
        let monthComponents = cal.dateComponents([.year, .month], from: now)
        let monthStart = cal.date(from: monthComponents) ?? now
        guard let monthInterval = cal.dateInterval(of: .month, for: monthStart) else {
            return RainCalendarEntry(date: now, monthTitle: "", weekdaySymbols: [], days: [])
        }

        var totals: [Date: Double] = [:]
        for obs in observations {
            guard let date = obs.date, monthInterval.contains(date) else { continue }
            let day = cal.startOfDay(for: date)
            totals[day, default: 0] += obs.amount
        }

        let firstDay = monthInterval.start
        let firstWeekday = cal.component(.weekday, from: firstDay) - cal.firstWeekday
        let leadingEmpties = (firstWeekday + 7) % 7

        var days: [RainCalendarDay] = Array(
            repeating: RainCalendarDay(dayNumber: nil, total: 0, isToday: false),
            count: leadingEmpties
        )

        var current = firstDay
        while current < monthInterval.end {
            let dayStart = cal.startOfDay(for: current)
            days.append(RainCalendarDay(
                dayNumber: cal.component(.day, from: current),
                total: totals[dayStart] ?? 0,
                isToday: cal.isDateInToday(current)
            ))
            current = cal.date(byAdding: .day, value: 1, to: current) ?? monthInterval.end
        }

        let remainder = days.count % 7
        if remainder != 0 {
            days.append(contentsOf: Array(
                repeating: RainCalendarDay(dayNumber: nil, total: 0, isToday: false),
                count: 7 - remainder
            ))
        }

        return RainCalendarEntry(
            date: now,
            monthTitle: monthStart.formatted(.dateTime.month(.wide).year()),
            weekdaySymbols: cal.veryShortWeekdaySymbols,
            days: days
        )
    }
}

struct RainCalendarWidgetEntryView: View {
    var entry: RainCalendarEntry

    private var weeks: [[RainCalendarDay]] {
        stride(from: 0, to: entry.days.count, by: 7).map { i in
            Array(entry.days[i..<min(i + 7, entry.days.count)])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(entry.monthTitle)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            HStack(spacing: 0) {
                ForEach(entry.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            VStack(spacing: 0) {
                ForEach(weeks.indices, id: \.self) { wi in
                    HStack(spacing: 0) {
                        ForEach(weeks[wi].indices, id: \.self) { di in
                            WidgetCalendarDayCell(day: weeks[wi][di])
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct WidgetCalendarDayCell: View {
    let day: RainCalendarDay

    var body: some View {
        VStack(spacing: 2) {
            if let dayNumber = day.dayNumber {
                ZStack {
                    if day.isToday {
                        Circle()
                            .fill(.tint)
                            .frame(width: 26, height: 26)
                    }
                    Text("\(dayNumber)")
                        .font(.system(size: 15))
                        .foregroundStyle(day.isToday ? .white : .primary)
                }
                .frame(height: 26)

                if day.total > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 9))
                        Text(day.total, format: .number.precision(.fractionLength(2)))
                            .font(.system(size: 11).monospacedDigit())
                    }
                    .foregroundStyle(.tint)
                    .frame(height: 13)
                } else {
                    Color.clear.frame(height: 13)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RainCalendarWidget: Widget {
    let kind: String = "RainCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RainCalendarProvider()) { entry in
            RainCalendarWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rain Calendar")
        .description("See this month's rainfall by day.")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemSmall) {
    RainTrackerWidget()
} timeline: {
    RainEntry(date: .now, todayTotal: 0.42, monthTotal: 3.18, yearTotal: 22.65, rainyDaysThisMonth: 8)
    RainEntry(date: .now, todayTotal: 0, monthTotal: 3.18, yearTotal: 22.65, rainyDaysThisMonth: 8)
}

#Preview(as: .systemMedium) {
    RainTrackerWidget()
} timeline: {
    RainEntry(date: .now, todayTotal: 0.42, monthTotal: 3.18, yearTotal: 22.65, rainyDaysThisMonth: 8)
}
#Preview(as: .systemSmall) {
    RainTotalsWidget()
} timeline: {
    RainEntry(date: .now, todayTotal: 0.42, monthTotal: 3.18, yearTotal: 22.65, rainyDaysThisMonth: 8)
}

#Preview(as: .systemSmall) {
    RainAddWidget()
} timeline: {
    RainAddEntry(date: .now)
}

private func sampleCalendarEntry() -> RainCalendarEntry {
    let cal = Calendar.current
    let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .now
    let interval = cal.dateInterval(of: .month, for: monthStart)!
    var sample: [Date: Double] = [:]
    var iter = interval.start
    var i = 0
    while iter < interval.end {
        if i % 4 == 0 { sample[iter] = Double(i % 7) * 0.18 + 0.05 }
        iter = cal.date(byAdding: .day, value: 1, to: iter)!
        i += 1
    }
    let firstWeekday = cal.component(.weekday, from: interval.start) - cal.firstWeekday
    let leadingEmpties = (firstWeekday + 7) % 7
    var days: [RainCalendarDay] = Array(
        repeating: RainCalendarDay(dayNumber: nil, total: 0, isToday: false),
        count: leadingEmpties
    )
    var current = interval.start
    while current < interval.end {
        days.append(RainCalendarDay(
            dayNumber: cal.component(.day, from: current),
            total: sample[current] ?? 0,
            isToday: cal.isDateInToday(current)
        ))
        current = cal.date(byAdding: .day, value: 1, to: current)!
    }
    let remainder = days.count % 7
    if remainder != 0 {
        days.append(contentsOf: Array(
            repeating: RainCalendarDay(dayNumber: nil, total: 0, isToday: false),
            count: 7 - remainder
        ))
    }
    return RainCalendarEntry(
        date: .now,
        monthTitle: monthStart.formatted(.dateTime.month(.wide).year()),
        weekdaySymbols: cal.veryShortWeekdaySymbols,
        days: days
    )
}

#Preview(as: .systemLarge) {
    RainCalendarWidget()
} timeline: {
    sampleCalendarEntry()
}

