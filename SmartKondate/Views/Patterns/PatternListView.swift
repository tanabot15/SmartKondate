//
//  PatternListView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData
import WidgetKit

struct PatternListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KondatePattern.createdAt, order: .reverse) private var patterns: [KondatePattern]
    
    @AppStorage("isQueueLoopEnabled") private var isQueueLoopEnabled: Bool = false
    @State private var isShowingCreateSheet = false

    private var queuedPatterns: [KondatePattern] {
        patterns
            .filter { $0.queueOrder != nil }
            .sorted { ($0.queueOrder ?? 0) < ($1.queueOrder ?? 0) }
    }

    private var unqueuedPatterns: [KondatePattern] {
        patterns.filter { $0.queueOrder == nil }
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
                // MARK: - Active & Upcoming Queue Section
                if !queuedPatterns.isEmpty {
                    Section {
                        Toggle(isOn: $isQueueLoopEnabled) {
                            Label {
                                Text("Loop Queue Patterns")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            } icon: {
                                Image(systemName: "repeat")
                                    .foregroundStyle(isQueueLoopEnabled ? Color.accentColor : .secondary)
                            }
                        }

                        ForEach(Array(queuedPatterns.enumerated()), id: \.element.id) { index, pattern in
                            NavigationLink(destination: PatternDetailView(pattern: pattern)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text(pattern.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

                                            if index == 0 {
                                                Text("Now Active")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.accentColor)
                                                    .foregroundStyle(.white)
                                                    .clipShape(Capsule())
                                            } else {
                                                Text("Next #\(index)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.secondary.opacity(0.2))
                                                    .foregroundStyle(.secondary)
                                                    .clipShape(Capsule())
                                            }
                                        }

                                        Text("\(pattern.durationDays) Days Cycle")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        removeFromQueue(pattern)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .onMove(perform: moveQueuedPatterns)
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.square.stack.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Active & Scheduled Queue")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.bold)
                        }
                    } footer: {
                        Text(isQueueLoopEnabled
                             ? "Finished patterns move to the end of the queue automatically."
                             : "Drag to reorder upcoming patterns. When the active pattern finishes, the next one starts automatically.")
                            .font(.caption)
                    }
                }

                // MARK: - Available Patterns Section
                if !unqueuedPatterns.isEmpty {
                    Section {
                        ForEach(unqueuedPatterns) { pattern in
                            NavigationLink(destination: PatternDetailView(pattern: pattern)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pattern.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text("\(pattern.durationDays) Days Cycle")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        addToQueue(pattern)
                                    } label: {
                                        Label("Add to Queue", systemImage: "plus.circle")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.accentColor)
                                }
                            }
                        }
                        .onDelete(perform: deleteUnqueuedPatterns)
                    } header: {
                        Text("Other Patterns")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Patterns")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
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

    private func addToQueue(_ pattern: KondatePattern) {
        let nextOrder = queuedPatterns.count
        pattern.queueOrder = nextOrder
        pattern.isActive = (nextOrder == 0)
        if nextOrder == 0 {
            pattern.startDate = Date()
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func removeFromQueue(_ pattern: KondatePattern) {
        pattern.queueOrder = nil
        pattern.isActive = false
        pattern.startDate = nil
        reindexQueue()
        
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func moveQueuedPatterns(from source: IndexSet, to destination: Int) {
        var updatedQueue = queuedPatterns
        updatedQueue.move(fromOffsets: source, toOffset: destination)
        
        for (index, pattern) in updatedQueue.enumerated() {
            pattern.queueOrder = index
            pattern.isActive = (index == 0)
            if index == 0 && pattern.startDate == nil {
                pattern.startDate = Date()
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func reindexQueue() {
        for (index, pattern) in queuedPatterns.enumerated() {
            pattern.queueOrder = index
            pattern.isActive = (index == 0)
            if index == 0 && pattern.startDate == nil {
                pattern.startDate = Date()
            }
        }
    }

    private func deleteUnqueuedPatterns(offsets: IndexSet) {
        for index in offsets {
            let patternToDelete = unqueuedPatterns[index]
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
