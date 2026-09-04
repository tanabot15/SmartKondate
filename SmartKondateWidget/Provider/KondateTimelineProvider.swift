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
    
    let breakfastMain: String
    let breakfastSub: String
    
    let lunchMain: String
    let lunchSub: String
    
    let dinnerMain: String
    let dinnerSub: String
}

struct KondateTimelineProvider: TimelineProvider {

    // MARK: - Placeholder
    func placeholder(in context: Context) -> SimpleKondateEntry {
        SimpleKondateEntry(
            date: Date(),
            patternName: "Standard Rotation",
            dayText: "Day 1",
            breakfastMain: "Toast & Eggs",
            breakfastSub: "Coffee",
            lunchMain: "Curry Rice",
            lunchSub: "Side Salad",
            dinnerMain: "Steak",
            dinnerSub: "Miso Soup"
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
                breakfastMain: "-", breakfastSub: "",
                lunchMain: "-", lunchSub: "",
                dinnerMain: "-", dinnerSub: ""
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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
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
                breakfastMain: extractMain(from: targetDay.breakfastMenus),
                breakfastSub: extractSub(from: targetDay.breakfastMenus),
                lunchMain: extractMain(from: targetDay.lunchMenus),
                lunchSub: extractSub(from: targetDay.lunchMenus),
                dinnerMain: extractMain(from: targetDay.dinnerMenus),
                dinnerSub: extractSub(from: targetDay.dinnerMenus)
            )
        }
        
        return nil
    }

    private static func extractMain(from menus: [Menu]) -> String {
        menus.first(where: { $0.category == "Main" })?.name ?? menus.first?.name ?? ""
    }

    private static func extractSub(from menus: [Menu]) -> String {
        let subs = menus.filter { $0.category != "Main" }
        return subs.map { $0.name }.joined(separator: " / ")
    }
}
