//
//  SettingsView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData
import CloudKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var cloudKitManager = CloudKitManager.shared
    @State private var isShowingShareSheet = false
    @State private var activeShare: CKShare?
    @State private var isLoadingShare = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingResetConfirmation = false

    var body: some View {
        List {
            // MARK: - 1. 家族共有 (CloudKit Share)
            Section {
                Button {
                    Task {
                        await prepareAndShowShareSheet()
                    }
                } label: {
                    HStack {
                        Label {
                            Text("Invite Family")
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        
                        if isLoadingShare {
                            ProgressView()
                        } else if cloudKitManager.accountStatus == .available {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text("iCloud Unavailable")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(cloudKitManager.accountStatus != .available || isLoadingShare)
            } header: {
                Text("Family Sharing")
            } footer: {
                Text("Share meal patterns and shopping checklists with family members via iCloud.")
            }

            // MARK: - 2. データ管理 (初期化・リセット)
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

            // MARK: - 3. アプリ情報 & 規約
            Section(header: Text("About")) {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("1.6")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingShareSheet) {
            if let share = activeShare {
                CloudKitShareView(share: share, container: cloudKitManager.container)
            }
        }
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

    @MainActor
    private func prepareAndShowShareSheet() async {
        isLoadingShare = true
        defer { isLoadingShare = false }
        
        do {
            let share = try await cloudKitManager.prepareShare()
            self.activeShare = share
            self.isShowingShareSheet = true
        } catch {
            print("CloudKit Share error: \(error.localizedDescription)")
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
