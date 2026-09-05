//
//  PatternListView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct PatternListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KondatePattern.createdAt, order: .reverse) private var patterns: [KondatePattern]
    
    @State private var isShowingCreateSheet = false

    // Active Pattern
    private var activePatterns: [KondatePattern] {
        patterns.filter { $0.isActive }
    }

    // Non-Active Pattern
    private var inactivePatterns: [KondatePattern] {
        patterns.filter { !$0.isActive }
    }

    var body: some View {
        List {
            if patterns.isEmpty {
                ContentUnavailableView {
                    Label("No Meal Patterns", systemImage: "calendar.day.timeline.left")
                } description: {
                    Text("Tap + to create a weekly or custom meal cycle pattern.")
                        .foregroundStyle(.secondary)
                }
            } else {
                // MARK: - Active Pattern Section
                if !activePatterns.isEmpty {
                    Section {
                        ForEach(activePatterns) { pattern in
                            NavigationLink(destination: PatternDetailView(pattern: pattern)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text(pattern.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

                                            Text("Active")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.accentColor)
                                                .foregroundStyle(.white)
                                                .clipShape(Capsule())
                                        }

                                        Text("\(pattern.durationDays) Days Cycle • \(pattern.days.count) Days Set")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Active Pattern")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.bold)
                        }
                    }
                }

                // MARK: - Inactive / Saved Patterns Section
                if !inactivePatterns.isEmpty {
                    Section {
                        ForEach(inactivePatterns) { pattern in
                            NavigationLink(destination: PatternDetailView(pattern: pattern)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pattern.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text("\(pattern.durationDays) Days Cycle • \(pattern.days.count) Days Set")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        toggleActive(pattern: pattern)
                                    } label: {
                                        Text("Activate")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.secondary.opacity(0.15))
                                            .foregroundStyle(.primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .onDelete(perform: deleteInactivePatterns)
                    } header: {
                        Text(activePatterns.isEmpty ? "Saved Patterns" : "Other Patterns")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Patterns")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            NavigationStack {
                PatternEditorView()
            }
        }
    }

    private func toggleActive(pattern: KondatePattern) {
        for p in patterns {
            p.isActive = false
        }
        pattern.isActive = true
    }

    private func deleteInactivePatterns(offsets: IndexSet) {
        for index in offsets {
            let patternToDelete = inactivePatterns[index]
            modelContext.delete(patternToDelete)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: KondatePattern.self, PatternDay.self, Menu.self,
        configurations: config
    )
    let context = container.mainContext

    let pattern1 = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
    let pattern2 = KondatePattern(name: "Quick 3-Day Rotation", durationDays: 3, isActive: false)
    let pattern3 = KondatePattern(name: "Healthy & Light", durationDays: 5, isActive: false)

    [pattern1, pattern2, pattern3].forEach { context.insert($0) }

    return NavigationStack {
        PatternListView()
    }
    .modelContainer(container)
}
