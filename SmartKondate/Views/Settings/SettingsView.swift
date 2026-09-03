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
            Section {
                Button {
                    isShowingResetConfirmation = true
                } label: {
                    Text("Reset & Restore Preset Data")
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text("Delete All Data")
                }
            } header: {
                Text("Data Management")
            }

            // MARK: - 3. App Info
            Section(header: Text("About")) {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("2.2")
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
            Button("Reset & Load Presets", role: .destructive) {
                resetAndLoadPresets()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all current data and restore initial preset patterns and items.")
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
        PresetDataService.insertPresetDataIfNeeded(context: modelContext)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self], inMemory: true)
}
