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
        
        // 1. DashboardView と同じく queueOrder 順にキューを取得
        let descriptor = FetchDescriptor<KondatePattern>(
            predicate: #Predicate { $0.queueOrder != nil },
            sortBy: [SortDescriptor(\.queueOrder, order: .forward)]
        )
        
        guard let queuedPatterns = try? context.fetch(descriptor), !queuedPatterns.isEmpty else {
            return nil
        }
        
        guard let firstPattern = queuedPatterns.first,
              let baseStartDate = firstPattern.startDate else {
            return nil
        }
        
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        
        // 2. DashboardView logic
        for index in 0..<queuedPatterns.count {
            let pattern = queuedPatterns[index]
            
            // patternIndex までの累積日数を計算 (DashboardView の startDate(for:) と同じ)
            let offsetDays = queuedPatterns.prefix(index).reduce(0) { $0 + $1.durationDays }
            guard let patternStartDate = calendar.date(byAdding: .day, value: offsetDays, to: baseStartDate) else { continue }
            
            // このパターンの期間中に「今日」が含まれるか判定
            for dayIndex in 0..<pattern.durationDays {
                if let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: patternStartDate),
                   calendar.isDate(dayDate, inSameDayAs: startOfToday) {
                    
                    // 該当する PatternDay からメニュー情報を取得
                    if let targetDay = pattern.days.first(where: { $0.dayIndex == dayIndex }) {
                        return SimpleKondateEntry(
                            date: date,
                            patternName: pattern.name,
                            dayText: "Day \(dayIndex + 1)",
                            breakfastMain: extractMain(from: targetDay.breakfastMenus),
                            breakfastSub: extractSub(from: targetDay.breakfastMenus),
                            lunchMain: extractMain(from: targetDay.lunchMenus),
                            lunchSub: extractSub(from: targetDay.lunchMenus),
                            dinnerMain: extractMain(from: targetDay.dinnerMenus),
                            dinnerSub: extractSub(from: targetDay.dinnerMenus)
                        )
                    }
                }
            }
        }
        
        return nil
    }

    private static func extractMain(from menus: [Menu]) -> String {
        menus.first(where: { $0.category == .main })?.name ?? menus.first?.name ?? ""
    }

    private static func extractSub(from menus: [Menu]) -> String {
        let subs = menus.filter { $0.category != .main }
        return subs.map { $0.name }.joined(separator: " / ")
    }
}
