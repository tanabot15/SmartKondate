//
//  SettingsView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("userColorScheme") private var userColorScheme: String = "system"

    @State private var selectedPreset: PresetType = .balanced
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingResetConfirmation = false
    @State private var isShowingFileImporter = false
    @State private var exportURL: URL?
    @State private var isShowingShareSheet = false
    @State private var alertMessage: String?
    @State private var isShowingAlert = false

    var body: some View {
        List {
            // MARK: - 1. Appearance
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $userColorScheme) {
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                    Text("System").tag("system")
                }
                .pickerStyle(.menu)
            }

            // MARK: - 2. Data Transfer (JSON Export / Import)
            Section(header: Text("Backup & Sharing")) {

            }

            // MARK: - 3. Data Management
            Section(header: Text("Data Management")) {
                // Preset data
                HStack {
                    Text("Restore Preset")
                    Spacer()
                    SwiftUI.Menu {
                        ForEach(PresetType.allCases) { preset in
                            Button(preset.rawValue) {
                                selectedPreset = preset
                                isShowingResetConfirmation = true
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedPreset.rawValue)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(.tint)
                    }
                }

                // Delete Data
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text("Delete All Data")
                }
                
                // Export Data
                Button {
                    exportData()
                } label: {
                    Text("Export Data")
                }

                // Import Data
                Button {
                    isShowingFileImporter = true
                } label: {
                    Text("Import Data")
                }
            }

            // MARK: - 4. App Info
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("2.12")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importData(from: result)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Notice", isPresented: $isShowingAlert, presenting: alertMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .confirmationDialog(
            "Reset to Presets?",
            isPresented: $isShowingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset & Load \(selectedPreset.rawValue)", role: .destructive) {
                resetAndLoadPresets()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all current data and restore initial preset patterns and items for '\(selectedPreset.rawValue)'.")
        }
        .confirmationDialog(
            "Delete All Data?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All meal patterns, menus, ingredients, and stock items will be removed.")
        }
    }

    // MARK: - Export Logic
    private func exportData() {
        do {
            let data = try DataBackupService.exportJSON(context: modelContext)
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent("SmartKondate_Backup.json")
            try data.write(to: fileURL)
            self.exportURL = fileURL
            self.isShowingShareSheet = true
        } catch {
            self.alertMessage = "Failed to export data: \(error.localizedDescription)"
            self.isShowingAlert = true
        }
    }

    // MARK: - Import Logic
    private func importData(from result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedFileURL = urls.first else { return }
            guard selectedFileURL.startAccessingSecurityScopedResource() else {
                self.alertMessage = "Could not access the selected file."
                self.isShowingAlert = true
                return
            }
            defer { selectedFileURL.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: selectedFileURL)
                try DataBackupService.importJSON(data: data, context: modelContext)
                self.alertMessage = "Data successfully imported!"
                self.isShowingAlert = true
            } catch {
                self.alertMessage = "Failed to import data: \(error.localizedDescription)"
                self.isShowingAlert = true
            }
        case .failure(let error):
            self.alertMessage = "File selection failed: \(error.localizedDescription)"
            self.isShowingAlert = true
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: KondatePattern.self)
            try modelContext.delete(model: PatternDay.self)
            try modelContext.delete(model: Menu.self)
            try modelContext.delete(model: Ingredient.self)
            try modelContext.delete(model: StockItem.self)
            try modelContext.save()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }

    private func resetAndLoadPresets() {
        deleteAllData()
        PresetDataService.insertPresetDataIfNeeded(context: modelContext, presetType: selectedPreset)
    }
}

// MARK: - UIActivityViewController Helper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self], inMemory: true)
}
