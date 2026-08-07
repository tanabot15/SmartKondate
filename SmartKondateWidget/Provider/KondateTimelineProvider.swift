//
//  KondateTimelineProvider.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import WidgetKit
import SwiftUI
import SwiftData

struct SimpleKondateEntry: TimelineEntry {
    let date: Date
    let patternName: String
    let dayText: String
    let breakfast: String
    let lunch: String
    let dinner: String
}

struct KondateTimelineProvider: TimelineProvider {

    // MARK: - Placeholder
    func placeholder(in context: Context) -> SimpleKondateEntry {
        SimpleKondateEntry(
            date: Date(),
            patternName: "Standard Rotation",
            dayText: "Day 1",
            breakfast: "Toast & Eggs",
            lunch: "Curry Rice",
            dinner: "Steak & Salad"
        )
    }

    // MARK: - Snapshot
    func getSnapshot(in context: Context, completion: @escaping (SimpleKondateEntry) -> Void) {
        Task { @MainActor in
            let entry = WidgetDataFetcher.fetchTodayEntry(for: Date()) ?? placeholder(in: context)
            completion(entry)
        }
    }

    // MARK: - Timeline
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleKondateEntry>) -> Void) {
        let currentDate = Date()
        
        Task { @MainActor in
            let entry = WidgetDataFetcher.fetchTodayEntry(for: currentDate) ?? SimpleKondateEntry(
                date: currentDate,
                patternName: "Not Set",
                dayText: "-",
                breakfast: "Not Set",
                lunch: "Not Set",
                dinner: "Not Set"
            )
            
            let calendar = Calendar.current
            let nextUpdate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate)
            
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - Data Fetcher (MainActor Isolated)
@MainActor
private enum WidgetDataFetcher {
    static func fetchTodayEntry(for date: Date) -> SimpleKondateEntry? {
        let schema = Schema([
            Ingredient.self,
            Menu.self,
            PatternDay.self,
            KondatePattern.self,
            StockItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            return nil
        }
        
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<KondatePattern>(
            predicate: #Predicate { $0.isActive == true }
        )
        
        guard let activePattern = try? context.fetch(descriptor).first,
              activePattern.durationDays > 0,
              !activePattern.days.isEmpty else {
            return nil
        }
        
        let calendar = Calendar.current
        let startOfTarget = calendar.startOfDay(for: date)
        let startOfBase = calendar.startOfDay(for: activePattern.createdAt)
        let dayDifference = calendar.dateComponents([.day], from: startOfBase, to: startOfTarget).day ?? 0
        
        let remainder = dayDifference % activePattern.durationDays
        let dayIndex = remainder >= 0 ? remainder : remainder + activePattern.durationDays
        
        if let targetDay = activePattern.days.first(where: { $0.dayIndex == dayIndex }) {
            return SimpleKondateEntry(
                date: date,
                patternName: activePattern.name,
                dayText: "Day \(dayIndex + 1)",
                breakfast: targetDay.breakfastMenu?.name ?? "Not Set",
                lunch: targetDay.lunchMenu?.name ?? "Not Set",
                dinner: targetDay.dinnerMenu?.name ?? "Not Set"
            )
        }
        
        return nil
    }
}
