import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingAdd = false
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { consumePendingAddObservation() }
        }
        .onAppear { consumePendingAddObservation() }
    }

    private func consumePendingAddObservation() {
        let defaults = UserDefaults(suiteName: RainStore.appGroupIdentifier)
        if defaults?.bool(forKey: RainStore.pendingAddObservationKey) == true {
            defaults?.set(false, forKey: RainStore.pendingAddObservationKey)
            showingAdd = true
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
