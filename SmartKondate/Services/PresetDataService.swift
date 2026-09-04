//
//  PresetDataService.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

struct PresetDataService {
    static func insertPresetDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<KondatePattern>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return
        }
        
        // MARK: - 1. StockItems (20 items)
        let stockItems = [
            StockItem(name: "Soy Sauce", category: "Seasoning"),
            StockItem(name: "Miso", category: "Seasoning"),
            StockItem(name: "Mirin", category: "Seasoning"),
            StockItem(name: "Cooking Sake", category: "Seasoning"),
            StockItem(name: "Olive Oil", category: "Seasoning"),
            StockItem(name: "Salt & Pepper", category: "Seasoning"),
            StockItem(name: "Sesame Oil", category: "Seasoning"),
            StockItem(name: "Mayonnaise", category: "Seasoning"),
            StockItem(name: "Ketchup", category: "Seasoning"),
            StockItem(name: "Sugar", category: "Seasoning"),
            StockItem(name: "Rice", category: "Pantry"),
            StockItem(name: "Pasta", category: "Pantry"),
            StockItem(name: "Bread", category: "Pantry"),
            StockItem(name: "Eggs", category: "Pantry"),
            StockItem(name: "Milk", category: "Pantry"),
            StockItem(name: "Tofu", category: "Pantry"),
            StockItem(name: "Onion", category: "Pantry"),
            StockItem(name: "Garlic", category: "Pantry"),
            StockItem(name: "Kitchen Towels", category: "Household"),
            StockItem(name: "Dish Soap", category: "Household")
        ]
        stockItems.forEach { context.insert($0) }
        
        // MARK: - 2. Menus (Main, Side, Soup, Other)
        
        // Main Menus
        let m1 = Menu(name: "Toast & Fried Eggs", category: "Main")
        m1.ingredients = [Ingredient(name: "Bread", amount: "2 slices"), Ingredient(name: "Egg", amount: "2 pcs")]
        
        let m2 = Menu(name: "Grilled Salmon", category: "Main")
        m2.ingredients = [Ingredient(name: "Salmon Fillet", amount: "1 pc")]
        
        let m3 = Menu(name: "Chicken Teriyaki Bowl", category: "Main")
        m3.ingredients = [Ingredient(name: "Chicken Thigh", amount: "150g"), Ingredient(name: "Rice", amount: "1 bowl")]
        
        let m4 = Menu(name: "Pasta Carbonara", category: "Main")
        m4.ingredients = [Ingredient(name: "Pasta", amount: "100g"), Ingredient(name: "Bacon", amount: "40g"), Ingredient(name: "Egg", amount: "1 pc")]
        
        let m5 = Menu(name: "Pork Ginger Stir-fry", category: "Main")
        m5.ingredients = [Ingredient(name: "Pork Slice", amount: "200g"), Ingredient(name: "Onion", amount: "1 pc")]
        
        let m6 = Menu(name: "Hamburger Steak", category: "Main")
        m6.ingredients = [Ingredient(name: "Minced Meat", amount: "250g"), Ingredient(name: "Breadcrumbs", amount: "2 tbsp")]
        
        let m7 = Menu(name: "Japanese Curry Rice", category: "Main")
        m7.ingredients = [Ingredient(name: "Curry Roux", amount: "2 cubes"), Ingredient(name: "Potato", amount: "1 pc"), Ingredient(name: "Carrot", amount: "1/2 pc")]

        // Side Menus
        let s1 = Menu(name: "Caesar Salad", category: "Side")
        s1.ingredients = [Ingredient(name: "Romaine Lettuce", amount: "100g"), Ingredient(name: "Croutons", amount: "20g")]
        
        let s2 = Menu(name: "Spinach Ohitashi", category: "Side")
        s2.ingredients = [Ingredient(name: "Spinach", amount: "1/2 bundle")]
        
        let s3 = Menu(name: "Steamed Broccoli", category: "Side")
        s3.ingredients = [Ingredient(name: "Broccoli", amount: "1/2 head")]

        // Soup Menus
        let sp1 = Menu(name: "Miso Soup", category: "Soup")
        sp1.ingredients = [Ingredient(name: "Tofu", amount: "1/2 block"), Ingredient(name: "Wakame", amount: "5g")]
        
        let sp2 = Menu(name: "Corn Soup", category: "Soup")
        sp2.ingredients = [Ingredient(name: "Corn Cream Can", amount: "1/2 can"), Ingredient(name: "Milk", amount: "100ml")]

        let allMenus = [m1, m2, m3, m4, m5, m6, m7, s1, s2, s3, sp1, sp2]
        allMenus.forEach { context.insert($0) }

        // MARK: - 3. KondatePatterns & PatternDays

        // Pattern 1: Standard Weekly (7 Days) - Active
        let pattern1 = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
        context.insert(pattern1)
        
        let daysP1 = [
            PatternDay(dayIndex: 0, breakfastMenus: [m1], lunchMenus: [m3, s1], dinnerMenus: [m5, s2, sp1]),
            PatternDay(dayIndex: 1, breakfastMenus: [m2, sp1], lunchMenus: [m4], dinnerMenus: [m6, s3, sp2]),
            PatternDay(dayIndex: 2, breakfastMenus: [m1], lunchMenus: [m7, s1], dinnerMenus: [m2, s2, sp1]),
            PatternDay(dayIndex: 3, breakfastMenus: [m2, sp1], lunchMenus: [m3], dinnerMenus: [m5, s3]),
            PatternDay(dayIndex: 4, breakfastMenus: [m1], lunchMenus: [m4, s1], dinnerMenus: [m6, sp2]),
            PatternDay(dayIndex: 5, breakfastMenus: [m2, sp1], lunchMenus: [m7], dinnerMenus: [m5, s2, sp1]),
            PatternDay(dayIndex: 6, breakfastMenus: [m1], lunchMenus: [m3, s3], dinnerMenus: [m6, s1, sp2])
        ]
        daysP1.forEach { day in
            day.pattern = pattern1
            context.insert(day)
        }

        // Pattern 2: Quick 3-Day Rotation (3 Days)
        let pattern2 = KondatePattern(name: "Quick 3-Day Rotation", durationDays: 3, isActive: false)
        context.insert(pattern2)
        
        let daysP2 = [
            PatternDay(dayIndex: 0, breakfastMenus: [m1], lunchMenus: [m7, s1], dinnerMenus: [m5, sp1]),
            PatternDay(dayIndex: 1, breakfastMenus: [m2, sp1], lunchMenus: [m3], dinnerMenus: [m6, s3, sp2]),
            PatternDay(dayIndex: 2, breakfastMenus: [m1], lunchMenus: [m4], dinnerMenus: [m2, s2, sp1])
        ]
        daysP2.forEach { day in
            day.pattern = pattern2
            context.insert(day)
        }

        do {
            try context.save()
        } catch {
            print("Failed to save preset data: \(error)")
        }
    }
}
