import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            MeasurementsView()
                .tabItem {
                    Label("Measurements", systemImage: "drop.fill")
                }
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
