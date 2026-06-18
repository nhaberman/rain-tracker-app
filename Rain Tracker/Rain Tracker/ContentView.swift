import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RainObservation.date, order: .reverse) private var observations: [RainObservation]

    @State private var showingAdd = false

    private var monthTotal: Double {
        let cal = Calendar.current
        let now = Date.now
        return observations
            .filter { cal.isDate($0.date ?? now, equalTo: now, toGranularity: .month) }
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
                            Text(monthTotal, format: .number.precision(.fractionLength(2)))
                            Text("in").foregroundStyle(.secondary)
                        }
                        .font(.headline)
                    }
                }

                Section {
                    if observations.isEmpty {
                        ContentUnavailableView(
                            "No readings yet",
                            systemImage: "cloud.rain",
                            description: Text("Tap + to log your first rain gauge reading.")
                        )
                    } else {
                        ForEach(observations) { observation in
                            NavigationLink(destination: ObservationDetailView(observation: observation)) {
                                ObservationRow(observation: observation)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Rain Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Label("Log Rain", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddObservationView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(observations[index])
        }
    }
}

struct ObservationRow: View {
    let observation: RainObservation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(observation.date ?? .now, style: .date)
                    .font(.subheadline)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(observation.amount, format: .number.precision(.fractionLength(2)))
                    .font(.body.monospacedDigit())
                    .bold()
                Text("in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ObservationDetailView: View {
    let observation: RainObservation

    var body: some View {
        Form {
            Section("Reading") {
                LabeledContent("Amount") {
                    Text("\(observation.amount, format: .number.precision(.fractionLength(2))) in")
                }
                LabeledContent("Date") {
                    Text(observation.date ?? .now, format: .dateTime)
                }
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
