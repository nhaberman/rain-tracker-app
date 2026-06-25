import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingAdd = false

    var body: some View {
        TabView {
            MeasurementsView(showingAdd: $showingAdd)
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
        .tabViewStyle(.sidebarAdaptable)
        .sheet(isPresented: $showingAdd) {
            AddObservationView()
        }
        .onOpenURL { url in
            if url.scheme == "raintracker", url.host == "add" {
                showingAdd = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
