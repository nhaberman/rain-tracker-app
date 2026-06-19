import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RainObservation.date) private var observations: [RainObservation]

    @AppStorage("useTimeOfDay") var useTimeOfDay = true

    @State private var exportItem: ExportItem?
    @State private var showExportError = false
    @State private var showImportPicker = false
    @State private var showImportModeAlert = false
    @State private var importMode: ImportMode = .merge
    @State private var importResult: ImportResult?
    @State private var showDeleteAllAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Data Management"), footer: Text("""
• Import an external file to load measurements to restore or transfer your data.
• Export your measurements to a file to back up or share them.
""")) {
                    Button("Import Data") {
                        if observations.isEmpty {
                            importMode = .merge
                            showImportPicker = true
                        } else {
                            showImportModeAlert = true
                        }
                    }
                    Button("Export Data") {
                        exportData()
                    }
                    Button("Delete All Data", role: .destructive) {
                        showDeleteAllAlert = true
                    }
                }

                Section("Behavior") {
                    Toggle("Use \"Time of Day\"", isOn: $useTimeOfDay)
                }

                Section("About") {
                    LabeledContent("Version") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $exportItem) { item in
                ShareSheet(items: [item.url])
                    .ignoresSafeArea()
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importData(from: url)
                case .failure:
                    importResult = ImportResult(imported: 0, skipped: 0, failed: true)
                }
            }
            .alert("Delete All Data", isPresented: $showDeleteAllAlert) {
                Button("Delete All", role: .destructive) {
                    observations.forEach { modelContext.delete($0) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(observations.count) logged measurement(s). This cannot be undone.")
            }
            .alert("Export Failed", isPresented: $showExportError) {
                Button("OK", role: .cancel) {}
            }
            .alert("Import Data", isPresented: $showImportModeAlert) {
                Button("Replace All", role: .destructive) {
                    importMode = .replace
                    showImportPicker = true
                }
                Button("Merge") {
                    importMode = .merge
                    showImportPicker = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Replace all existing records with the imported data, or merge the imported records with your current data?")
            }
            .alert(
                "Import Complete",
                isPresented: Binding(
                    get: { importResult != nil },
                    set: { if !$0 { importResult = nil } }
                ),
                presenting: importResult
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { result in
                if result.failed {
                    Text("Could not read the file.")
                } else {
                    Text("Imported \(result.imported) record(s). Skipped \(result.skipped) invalid line(s).")
                }
            }
        }
    }

    private func importData(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importResult = ImportResult(imported: 0, skipped: 0, failed: true)
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            importResult = ImportResult(imported: 0, skipped: 0, failed: true)
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var imported = 0
        var skipped = 0

        if importMode == .replace {
            observations.forEach { modelContext.delete($0) }
        }

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let parts = trimmed.components(separatedBy: ",")
            guard parts.count >= 2,
                  let date = formatter.date(from: parts[0]),
                  let amount = Double(parts[1])
            else {
                skipped += 1
                continue
            }

            let timeOfDay = parts.count >= 3 ? TimeOfDay(rawValue: parts[2]) : .unknown
            let observation = RainObservation(amount: amount, date: date, timeOfDay: timeOfDay)
            modelContext.insert(observation)
            imported += 1
        }

        importResult = ImportResult(imported: imported, skipped: skipped, failed: false)
    }

    private func exportData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let lines = observations.compactMap { obs -> String? in
            guard let date = obs.date else { return nil }
            return "\(formatter.string(from: date)),\(obs.amount),\(obs.resolvedTimeOfDay.rawValue)"
        }
        let content = lines.joined(separator: "\n")

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("rain_data.txt")

        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            exportItem = ExportItem(url: tempURL)
        } catch {
            showExportError = true
        }
    }
}

private enum ImportMode { case replace, merge }

private struct ImportResult {
    let imported: Int
    let skipped: Int
    let failed: Bool
}

private struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: RainObservation.self, inMemory: true)
}
