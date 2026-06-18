import SwiftUI
import SwiftData

struct AddObservationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var date = Date.now

    private var amount: Double? { Double(amountText) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading") {
                    HStack {
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                        Text("inches")
                            .foregroundStyle(.secondary)
                    }
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

            }
            .navigationTitle("Log Rain")
            .navigationBarTitleDisplayMode(.inline)
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

    private func save() {
        guard let amount, amount > 0 else { return }
        modelContext.insert(RainObservation(amount: amount, date: date))
        dismiss()
    }
}

#Preview {
    AddObservationView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
