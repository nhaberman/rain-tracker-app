import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var allObservations: [RainObservation]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)

    private let calendar = Calendar.current
    private let currentYear = Calendar.current.component(.year, from: .now)

    private var oldestYear: Int {
        allObservations.compactMap { $0.date }.map { calendar.component(.year, from: $0) }.min() ?? currentYear
    }

    private var yearObservations: [RainObservation] {
        allObservations.filter {
            calendar.component(.year, from: $0.date ?? .now) == selectedYear
        }
    }

    private var yearTotal: Double {
        yearObservations.reduce(0) { $0 + $1.amount }
    }

    private var rainyDayCount: Int {
        let days = Set(yearObservations.compactMap { obs -> Date? in
            guard let d = obs.date else { return nil }
            return calendar.startOfDay(for: d)
        })
        return days.count
    }

    private var avgPerRainyDay: Double {
        rainyDayCount > 0 ? yearTotal / Double(rainyDayCount) : 0
    }

    // [month 1–12: total inches]
    private var monthlyTotals: [Int: Double] {
        var totals: [Int: Double] = [:]
        for obs in yearObservations {
            let month = calendar.component(.month, from: obs.date ?? .now)
            totals[month, default: 0] += obs.amount
        }
        return totals
    }

    private var wettestMonth: Int? {
        monthlyTotals.max(by: { $0.value < $1.value })?.key
    }

    private var chartData: [MonthBar] {
        (1...12).map { month in
            MonthBar(month: month, total: monthlyTotals[month] ?? 0)
        }
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

    private func monthName(_ month: Int) -> String {
        let components = DateComponents(year: selectedYear, month: month, day: 1)
        let date = calendar.date(from: components) ?? .now
        return Self.monthFormatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                if yearObservations.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No data for \(String(selectedYear))",
                            systemImage: "chart.bar",
                            description: Text("Log rain readings to see statistics here.")
                        )
                    }
                } else {
                    // Stat cards
                    Section {
                        HStack(spacing: 0) {
                            StatCard(
                                title: "Total",
                                value: String(format: "%.2f", yearTotal),
                                unit: "in",
                                icon: "drop.fill"
                            )
                            Divider()
                            StatCard(
                                title: "Rainy Days",
                                value: "\(rainyDayCount)",
                                unit: "days",
                                icon: "cloud.rain.fill"
                            )
                            Divider()
                            StatCard(
                                title: "Avg / Day",
                                value: String(format: "%.2f", avgPerRainyDay),
                                unit: "in",
                                icon: "chart.line.uptrend.xyaxis"
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(EdgeInsets())

                    // Bar chart
                    Section("Monthly Rainfall") {
                        Chart(chartData) { bar in
                            BarMark(
                                x: .value("Month", bar.abbreviatedName),
                                y: .value("Inches", bar.total)
                            )
                            .foregroundStyle(
                                wettestMonth == bar.month
                                    ? Color.accentColor
                                    : Color.accentColor.opacity(0.5)
                            )
                            .cornerRadius(4)
                        }
                        .chartXScale(domain: MonthBar.abbreviatedMonthNames)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label).font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        .padding(.vertical, 8)
                    }

                    // Monthly breakdown list
                    Section("Monthly Breakdown") {
                        ForEach((1...12).filter { monthlyTotals[$0] != nil }, id: \.self) { month in
                            let total = monthlyTotals[month] ?? 0
                            HStack {
                                if month == wettestMonth {
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .font(.caption)
                                }
                                Text(monthName(month))
                                Spacer()
                                Text(total, format: .number.precision(.fractionLength(2)))
                                    .font(.body.monospacedDigit())
                                    .bold()
                                Text("in")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        if value.translation.width < 0, selectedYear < currentYear {
                            selectedYear += 1
                        } else if value.translation.width > 0, selectedYear > oldestYear {
                            selectedYear -= 1
                        }
                    }
            )
            .navigationTitle("\(String(selectedYear)) Statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedYear > oldestYear {
                        Button { selectedYear -= 1 } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedYear < currentYear {
                        Button { selectedYear += 1 } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
            }
        }
    }
}

private struct MonthBar: Identifiable {
    let month: Int
    let total: Double
    var id: Int { month }

    static let abbreviatedMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var abbreviatedName: String { Self.abbreviatedMonthNames[month - 1] }
}

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
