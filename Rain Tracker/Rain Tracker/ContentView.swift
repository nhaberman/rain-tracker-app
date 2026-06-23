import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingAdd = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
            .tabViewStyle(.sidebarAdaptable)

            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .backgroundStyle(Color.accentColor)
                    .frame(width: 56, height: 56)
                    .glassEffect(in: Circle())
            }
            .padding(.trailing, 24)
            .padding(.bottom, 70)
        }
        .sheet(isPresented: $showingAdd) {
            AddObservationView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
