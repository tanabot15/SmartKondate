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
    @Query(filter: #Predicate<KondatePattern> { $0.isActive }, sort: \KondatePattern.createdAt)
    private var activePatterns: [KondatePattern]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("userColorScheme") private var userColorScheme: String = "system"
    @AppStorage("isQueueLoopEnabled") private var isQueueLoopEnabled: Bool = false

    @AppStorage("enablePatternSwitchReminder") private var enablePatternSwitchReminder: Bool = false
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore: Int = 2
    @AppStorage("reminderHour") private var reminderHour: Int = 19

    // DatePicker連携用のBinding Date (時・分のみ保持)
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = 0
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let hour = Calendar.current.component(.hour, from: newDate)
                reminderHour = hour
                updateNotificationSchedule(enabled: true)
            }
        )
    }

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
            // MARK: - 1. General & Preferences
            Section(
                header: Text("App Preferences"),
                footer: Text("When loop mode is enabled, completed meal patterns automatically rotate to the end of the queue.")
            ) {
                // Theme Toggle
                Picker(selection: $userColorScheme) {
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                    Text("System").tag("system")
                } label: {
                    Label("Theme", systemImage: "paintpalette")
                }
                .pickerStyle(.menu)

                // Pattern Queue Loop Mode
                Toggle(isOn: $isQueueLoopEnabled) {
                    Label("Loop Queue Patterns", systemImage: "repeat")
                }

                // Next Pattern Switch Reminder
                Toggle(isOn: $enablePatternSwitchReminder.animation()) {
                    Label {
                        Text("Next Pattern Reminder")
                    } icon: {
                        Image(systemName: enablePatternSwitchReminder ? "bell.fill" : "bell")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .onChange(of: enablePatternSwitchReminder) { _, newValue in
                    updateNotificationSchedule(enabled: newValue)
                }

                if enablePatternSwitchReminder {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Advance Notice", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("Advance Notice", selection: $reminderDaysBefore) {
                            Text("Same day").tag(0)
                            Text("1 day ago").tag(1)
                            Text("2 days ago").tag(2)
                            Text("3 days ago").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: reminderDaysBefore) { _, _ in
                            updateNotificationSchedule(enabled: true)
                        }
                    }
                    .padding(.vertical, 4)

                    DatePicker(
                        selection: reminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    ) {
                        Label("Reminder Time", systemImage: "clock")
                    }
                }
            }

            // MARK: - 2. Data Management
            Section(header: Text("Data Management")) {
                // Preset data
                HStack {
                    Label("Restore Preset", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(.primary)
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

                // Export Data
                Button {
                    exportData()
                } label: {
                    Label("Export Backup (JSON)", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.primary)
                }

                // Import Data
                Button {
                    isShowingFileImporter = true
                } label: {
                    Label("Import Backup (JSON)", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.primary)
                }

                // Delete Data
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }

            // MARK: - 3. Help & Onboarding
            Section(header: Text("Help & Guide")) {
                Button {
                    hasCompletedOnboarding = false
                } label: {
                    Label("Replay Onboarding", systemImage: "book.pages")
                        .foregroundStyle(.primary)
                }
            }

            // MARK: - 4. App Info & Support
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("3.14")
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

    private func updateNotificationSchedule(enabled: Bool) {
        if enabled {
            NotificationManager.shared.requestAuthorization { granted in
                if granted {
                    NotificationManager.shared.scheduleNextPatternReminder(
                        activePattern: activePatterns.first,
                        daysBefore: reminderDaysBefore,
                        notificationHour: reminderHour
                    )
                } else {
                    enablePatternSwitchReminder = false
                }
            }
        } else {
            NotificationManager.shared.cancelAllReminders()
        }
    }

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
            let patterns = try modelContext.fetch(FetchDescriptor<KondatePattern>())
            for pattern in patterns {
                modelContext.delete(pattern)
            }

            let days = try modelContext.fetch(FetchDescriptor<PatternDay>())
            for day in days {
                day.breakfastMenus.removeAll()
                day.lunchMenus.removeAll()
                day.dinnerMenus.removeAll()
                modelContext.delete(day)
            }

            let menus = try modelContext.fetch(FetchDescriptor<Menu>())
            for menu in menus {
                modelContext.delete(menu)
            }

            let ingredients = try modelContext.fetch(FetchDescriptor<Ingredient>())
            for ingredient in ingredients {
                modelContext.delete(ingredient)
            }

            let stockItems = try modelContext.fetch(FetchDescriptor<StockItem>())
            for stockItem in stockItems {
                modelContext.delete(stockItem)
            }

            try modelContext.save()
            NotificationManager.shared.cancelAllReminders()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }

    private func resetAndLoadPresets() {
        deleteAllData()
        PresetDataService.insertPresetDataIfNeeded(context: modelContext, presetType: selectedPreset)

        self.alertMessage = "Preset '\(selectedPreset.rawValue)' has been successfully restored."
        self.isShowingAlert = true
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
