//
//  SettingsView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @AppStorage("userColorScheme") private var userColorScheme: String = "system"

    @State private var selectedPreset: PresetType = .balanced
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingResetConfirmation = false

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

            // MARK: - 2. Data Management
            Section(header: Text("Data Management")) {
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

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text("Delete All Data")
                }
            }

            // MARK: - 3. App Info
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

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self], inMemory: true)
}
