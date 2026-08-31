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

    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingResetConfirmation = false

    var body: some View {
        List {
            // MARK: - 1. データ管理 (初期化・リセット)
            Section {
                Button {
                    isShowingResetConfirmation = true
                } label: {
                    Label {
                        Text("Reset & Restore Preset Data")
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.orange)
                    }
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label {
                        Text("Delete All Data")
                            .foregroundStyle(.red)
                    } icon: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Data Management")
            }

            // MARK: - 2. アプリ情報
            Section(header: Text("About")) {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("1.8")
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
