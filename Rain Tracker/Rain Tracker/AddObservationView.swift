import SwiftUI
import SwiftData

struct AddObservationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("useTimeOfDay") private var useTimeOfDay = true

    @State private var amountText = ""
    @State private var date = Date.now
    @State private var timeOfDay: TimeOfDay = TimeOfDay.from(date: .now)
    @FocusState private var amountFocused: Bool

    private var amount: Double? { Double(amountText) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading") {
                    HStack {
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .focused($amountFocused)
                            .onChange(of: amountText) { _, new in limitToTwoDecimals(new) }
                        Text("inches")
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
                }
            }
            .navigationTitle("Log Rain")
            .navigationBarTitleDisplayMode(.inline)
            .frame(maxWidth: 540)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear { amountFocused = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(amount == nil || amount! <= 0)
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

    private func save() {
        guard let amount, amount > 0 else { return }
        modelContext.insert(RainObservation(amount: amount, date: date, timeOfDay: useTimeOfDay ? timeOfDay : .unknown))
        modelContext.saveAndRefreshWidgets()
        dismiss()
    }
}

#Preview {
    AddObservationView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
