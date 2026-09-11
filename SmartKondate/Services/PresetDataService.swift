//
//  PresetDataService.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

enum PresetType: String, CaseIterable, Identifiable {
    case standard = "Standard (Japanese & Western)"
    case quick3Day = "Quick 3-Day Rotation"
    case light = "Light & Healthy"

    var id: String { rawValue }
}

struct PresetDataService {
    static func insertPresetDataIfNeeded(context: ModelContext, presetType: PresetType = .standard) {
        let descriptor = FetchDescriptor<KondatePattern>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return
        }

        // MARK: - Preset-Specific Menus, StockItems & Patterns
        switch presetType {
        case .standard:
            insertStandardPreset(context: context)
        case .quick3Day:
            insertQuick3DayPreset(context: context)
        case .light:
            insertLightPreset(context: context)
        }

        do {
            try context.save()
        } catch {
            print("Failed to save preset data: \(error)")
        }
    }

    // MARK: - 1. Standard Preset
    private static func insertStandardPreset(context: ModelContext) {
        let stockItems = [
            StockItem(name: "Soy Sauce", category: "Seasoning"),
            StockItem(name: "Miso", category: "Seasoning"),
            StockItem(name: "Mirin", category: "Seasoning"),
            StockItem(name: "Cooking Sake", category: "Seasoning"),
            StockItem(name: "Olive Oil", category: "Seasoning"),
            StockItem(name: "Salt & Pepper", category: "Seasoning"),
            StockItem(name: "Rice", category: "Pantry"),
            StockItem(name: "Pasta", category: "Pantry"),
            StockItem(name: "Bread", category: "Pantry"),
            StockItem(name: "Eggs", category: "Pantry"),
            StockItem(name: "Milk", category: "Pantry"),
            StockItem(name: "Tofu", category: "Pantry")
        ]
        stockItems.forEach { context.insert($0) }

        let m1 = Menu(name: "Toast & Fried Eggs", category: "Main")
        let m2 = Menu(name: "Grilled Salmon", category: "Main")
        let m3 = Menu(name: "Chicken Teriyaki Bowl", category: "Main")
        let s1 = Menu(name: "Caesar Salad", category: "Side")
        let sp1 = Menu(name: "Miso Soup", category: "Soup")

        [m1, m2, m3, s1, sp1].forEach { context.insert($0) }

        let pattern = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
        context.insert(pattern)

        let days = (0..<7).map { index in
            PatternDay(dayIndex: index, breakfastMenus: [m1], lunchMenus: [m3], dinnerMenus: [m2, s1, sp1])
        }
        days.forEach {
            $0.pattern = pattern
            context.insert($0)
        }
    }

    // MARK: - 2. Quick 3-Day Preset
    private static func insertQuick3DayPreset(context: ModelContext) {
        let stockItems = [
            StockItem(name: "Consommé Cubes", category: "Seasoning"),
            StockItem(name: "Curry Roux", category: "Pantry"),
            StockItem(name: "Olive Oil", category: "Seasoning"),
            StockItem(name: "Salt & Pepper", category: "Seasoning"),
            StockItem(name: "Pasta", category: "Pantry"),
            StockItem(name: "Rice", category: "Pantry"),
            StockItem(name: "Frozen Vegetables", category: "Pantry"),
            StockItem(name: "Eggs", category: "Pantry")
        ]
        stockItems.forEach { context.insert($0) }

        let m1 = Menu(name: "Pasta Carbonara", category: "Main")
        let m2 = Menu(name: "Pork Ginger Stir-fry", category: "Main")
        let m3 = Menu(name: "Japanese Curry Rice", category: "Main")
        let sp1 = Menu(name: "Corn Soup", category: "Soup")

        [m1, m2, m3, sp1].forEach { context.insert($0) }

        let pattern = KondatePattern(name: "Quick 3-Day Rotation", durationDays: 3, isActive: true)
        context.insert(pattern)

        let days = [
            PatternDay(dayIndex: 0, breakfastMenus: [], lunchMenus: [m1], dinnerMenus: [m2, sp1]),
            PatternDay(dayIndex: 1, breakfastMenus: [], lunchMenus: [m3], dinnerMenus: [m1]),
            PatternDay(dayIndex: 2, breakfastMenus: [], lunchMenus: [m2], dinnerMenus: [m3])
        ]
        days.forEach {
            $0.pattern = pattern
            context.insert($0)
        }
    }

    // MARK: - 3. Light & Healthy Preset
    private static func insertLightPreset(context: ModelContext) {
        let stockItems = [
            StockItem(name: "Ponzu Sauce", category: "Seasoning"),
            StockItem(name: "Extra Virgin Olive Oil", category: "Seasoning"),
            StockItem(name: "Sea Salt", category: "Seasoning"),
            StockItem(name: "Tofu", category: "Pantry"),
            StockItem(name: "Chicken Breast", category: "Pantry"),
            StockItem(name: "Eggs", category: "Pantry"),
            StockItem(name: "Broccoli", category: "Pantry"),
            StockItem(name: "Miso", category: "Seasoning")
        ]
        stockItems.forEach { context.insert($0) }

        let m1 = Menu(name: "Steamed Chicken Breast", category: "Main")
        let s1 = Menu(name: "Spinach Ohitashi", category: "Side")
        let s2 = Menu(name: "Steamed Broccoli", category: "Side")
        let sp1 = Menu(name: "Tofu Miso Soup", category: "Soup")

        [m1, s1, s2, sp1].forEach { context.insert($0) }

        let pattern = KondatePattern(name: "Light & Healthy 5-Day", durationDays: 5, isActive: true)
        context.insert(pattern)

        let days = (0..<5).map { index in
            PatternDay(dayIndex: index, breakfastMenus: [sp1], lunchMenus: [m1, s2], dinnerMenus: [m1, s1, sp1])
        }
        days.forEach {
            $0.pattern = pattern
            context.insert($0)
        }
    }
}
