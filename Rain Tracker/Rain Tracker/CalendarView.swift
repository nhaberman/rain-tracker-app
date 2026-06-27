import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var observations: [RainObservation]
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var showingMonthPicker = false
    @State private var pickerDate: Date = .now
    @AppStorage("useMetric") private var useMetric = false

    private let calendar = Calendar.current
    private let dayColumns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    private var dailyTotals: [Date: Double] {
        var totals: [Date: Double] = [:]
        for obs in observations {
            guard let date = obs.date else { continue }
            let day = calendar.startOfDay(for: date)
            totals[day, default: 0] += obs.amount
        }
        return totals
    }

    private var monthlyTotals: [Date: Double] {
        var totals: [Date: Double] = [:]
        for obs in observations {
            guard let date = obs.date else { continue }
            let month = calendar.startOfMonth(for: date)
            totals[month, default: 0] += obs.amount
        }
        return totals
    }

    private var displayedMonthTotal: Double {
        monthlyTotals[displayedMonth] ?? 0
    }

    private var displayedMonthRainyDayCount: Int {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return 0 }
        return dailyTotals.keys.filter { monthInterval.contains($0) }.count
    }

    private var displayedMonthAvgPerRainyDay: Double {
        guard displayedMonthRainyDayCount > 0 else { return 0 }
        return displayedMonthTotal / Double(displayedMonthRainyDayCount)
    }

    private var displayedMonthRainiestDay: (date: Date, total: Double)? {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return nil }
        let entry = dailyTotals
            .filter { monthInterval.contains($0.key) }
            .max(by: { $0.value < $1.value })
        guard let entry else { return nil }
        return (date: entry.key, total: entry.value)
    }

    private var daysInGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return []
        }
        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay) - calendar.firstWeekday
        let leadingEmpties = (firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmpties)

        var current = firstDay
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        let remainder = days.count % 7
        if remainder != 0 {
            days += Array(repeating: nil, count: 7 - remainder)
        }

        return days
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 0) {
                        monthHeader
                        weekdayHeader
                        Divider()
                        calendarGrid
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onEnded { value in
                                let horizontal = value.translation.width
                                let vertical = value.translation.height
                                guard abs(horizontal) > abs(vertical) else { return }
                                if horizontal < 0 {
                                    let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                                    if !calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month) {
                                        displayedMonth = next
                                    }
                                } else {
                                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                                }
                            }
                    )

                    VStack(spacing: 0) {
                        statRow(label: "Month total", systemImage: "drop.fill", value: displayedMonthTotal)
                        Divider().padding(.leading, 40)
                        statRow(label: "Rainy days", systemImage: "cloud.rain.fill", intValue: displayedMonthRainyDayCount)
                        Divider().padding(.leading, 40)
                        statRow(label: "Avg / rainy day", systemImage: "chart.line.uptrend.xyaxis", value: displayedMonthAvgPerRainyDay)
                        if let rainiest = displayedMonthRainiestDay {
                            Divider().padding(.leading, 40)
                            rainiestDayRow(rainiest)
                        }

                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Today") {
                            displayedMonth = calendar.startOfMonth(for: .now)
                        }
                        .hoverEffect()
                    }
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .hoverEffect()

            Spacer()

            Button {
                pickerDate = displayedMonth
                showingMonthPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(monthTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color(.label))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            .hoverEffect()
            .sheet(isPresented: $showingMonthPicker) {
                MonthPickerSheet(selectedDate: $pickerDate) {
                    displayedMonth = calendar.startOfMonth(for: pickerDate)
                    showingMonthPicker = false
                }
            }

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .hoverEffect()
            .disabled(calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func statRow(label: String, systemImage: String, value: Double) -> some View {
        HStack {
            Label(label, systemImage: systemImage)
                .labelStyle(TintedIconLabelStyle())
            Spacer()
            Text(value.toDisplay(metric: useMetric), format: .number.precision(.fractionLength(useMetric ? 0 : 2)))
            Text(useMetric ? "mm" : "in").foregroundStyle(.secondary)
        }
        .font(.headline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func rainiestDayRow(_ rainiest: (date: Date, total: Double)) -> some View {
        HStack {
            Label("Rainiest day", systemImage: "cloud.heavyrain.fill")
                .labelStyle(TintedIconLabelStyle())
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(rainiest.total.toDisplay(metric: useMetric), format: .number.precision(.fractionLength(useMetric ? 0 : 2)))
                    Text(useMetric ? "mm" : "in").foregroundStyle(.secondary)
                }
                Text(rainiest.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.headline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func statRow(label: String, systemImage: String, intValue: Int) -> some View {
        HStack {
            Label(label, systemImage: systemImage)
                .labelStyle(TintedIconLabelStyle())
            Spacer()
            Text("\(intValue)")
            Text("days").foregroundStyle(.secondary)
        }
        .font(.headline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: dayColumns, spacing: 0) {
            ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, day in
                DayCell(
                    date: day,
                    isToday: day.map { calendar.isDateInToday($0) } ?? false,
                    rainTotal: day.flatMap { dailyTotals[calendar.startOfDay(for: $0)] },
                    useMetric: useMetric
                )
            }
        }
        .padding(.horizontal, 8)
    }
}

struct DayCell: View {
    let date: Date?
    let isToday: Bool
    let rainTotal: Double?
    var useMetric: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            if let date {
                let dayNumber = Calendar.current.component(.day, from: date)
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 28, height: 28)
                    }
                    Text("\(dayNumber)")
                        .font(.body)
                        .foregroundStyle(isToday ? .white : .primary)
                }
                .frame(height: 28)
                if let total = rainTotal {
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.blue)
                        Text(total.toDisplay(metric: useMetric), format: .number.precision(.fractionLength(useMetric ? 0 : 2)))
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                    }
                    .frame(height: 14)
                } else {
                    Color.clear.frame(height: 14)
                }
            } else {
                Color.clear.frame(height: 46)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
    }
}

struct TintedIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(.blue)
                .frame(width: 24, alignment: .center)
            configuration.title
        }
    }
}

struct MonthPickerSheet: View {
    @Binding var selectedDate: Date
    let onDone: () -> Void

    private let calendar = Calendar.current
    private let monthSymbols = Calendar.current.monthSymbols

    @State private var selectedMonth: Int
    @State private var selectedYear: Int

    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        return Array(2000...currentYear).reversed()
    }

    private var maxMonthForSelectedYear: Int {
        let currentYear = calendar.component(.year, from: .now)
        let currentMonth = calendar.component(.month, from: .now)
        return selectedYear == currentYear ? currentMonth : 12
    }

    init(selectedDate: Binding<Date>, onDone: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.onDone = onDone
        let cal = Calendar.current
        _selectedMonth = State(initialValue: cal.component(.month, from: selectedDate.wrappedValue))
        _selectedYear = State(initialValue: cal.component(.year, from: selectedDate.wrappedValue))
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...maxMonthForSelectedYear, id: \.self) { month in
                        Text(monthSymbols[month - 1]).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .onChange(of: selectedYear) {
                if selectedMonth > maxMonthForSelectedYear {
                    selectedMonth = maxMonthForSelectedYear
                }
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var components = DateComponents()
                        components.year = selectedYear
                        components.month = selectedMonth
                        components.day = 1
                        selectedDate = calendar.date(from: components) ?? selectedDate
                        onDone()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDone() }
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
