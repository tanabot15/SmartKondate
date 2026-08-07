//
//  PresetDataService.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

struct PresetDataService {
    
    /// Initial setup for preset data (StockItems: 20, Menus: 30, KondatePatterns: 4, PatternDays: 16)
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
        
        // MARK: - 2. Menus (30 menus with ingredients)
        // Breakfast (1-5)
        let m1 = Menu(name: "Toast & Fried Eggs", category: "Breakfast")
        m1.ingredients = [Ingredient(name: "Bread", amount: "2 slices"), Ingredient(name: "Egg", amount: "2 pcs")]
        
        let m2 = Menu(name: "Oatmeal & Berries", category: "Breakfast")
        m2.ingredients = [Ingredient(name: "Oats", amount: "50g"), Ingredient(name: "Mixed Berries", amount: "30g")]
        
        let m3 = Menu(name: "Japanese Breakfast Set", category: "Breakfast")
        m3.ingredients = [Ingredient(name: "Grilled Salmon", amount: "1 pc"), Ingredient(name: "Rice", amount: "1 bowl"), Ingredient(name: "Miso Soup", amount: "1 cup")]
        
        let m4 = Menu(name: "Pancakes & Bacon", category: "Breakfast")
        m4.ingredients = [Ingredient(name: "Pancake Mix", amount: "100g"), Ingredient(name: "Bacon", amount: "2 slices")]
        
        let m5 = Menu(name: "Fruit Smoothie & Granola", category: "Breakfast")
        m5.ingredients = [Ingredient(name: "Banana", amount: "1 pc"), Ingredient(name: "Yogurt", amount: "100g"), Ingredient(name: "Granola", amount: "40g")]
        
        // Lunch (6-15)
        let m6 = Menu(name: "Chicken Teriyaki Bowl", category: "Lunch")
        m6.ingredients = [Ingredient(name: "Chicken Thigh", amount: "150g"), Ingredient(name: "Rice", amount: "1 bowl")]
        
        let m7 = Menu(name: "Pasta Carbonara", category: "Lunch")
        m7.ingredients = [Ingredient(name: "Pasta", amount: "100g"), Ingredient(name: "Bacon", amount: "40g"), Ingredient(name: "Egg", amount: "1 pc")]
        
        let m8 = Menu(name: "Beef Gyudon", category: "Lunch")
        m8.ingredients = [Ingredient(name: "Sliced Beef", amount: "120g"), Ingredient(name: "Onion", amount: "1/2 pc")]
        
        let m9 = Menu(name: "Club Sandwich", category: "Lunch")
        m9.ingredients = [Ingredient(name: "Bread", amount: "3 slices"), Ingredient(name: "Turkey Slices", amount: "50g"), Ingredient(name: "Lettuce", amount: "2 leaves")]
        
        let m10 = Menu(name: "Shrimp Fried Rice", category: "Lunch")
        m10.ingredients = [Ingredient(name: "Rice", amount: "200g"), Ingredient(name: "Shrimp", amount: "80g"), Ingredient(name: "Egg", amount: "1 pc")]
        
        let m11 = Menu(name: "Ramen & Gyoza", category: "Lunch")
        m11.ingredients = [Ingredient(name: "Ramen Noodles", amount: "1 pack"), Ingredient(name: "Frozen Gyoza", amount: "5 pcs")]
        
        let m12 = Menu(name: "Caesar Salad Bowl", category: "Lunch")
        m12.ingredients = [Ingredient(name: "Chicken Breast", amount: "100g"), Ingredient(name: "Romaine Lettuce", amount: "100g"), Ingredient(name: "Croutons", amount: "20g")]
        
        let m13 = Menu(name: "Japanese Curry Rice", category: "Lunch")
        m13.ingredients = [Ingredient(name: "Curry Roux", amount: "2 cubes"), Ingredient(name: "Potato", amount: "1 pc"), Ingredient(name: "Carrot", amount: "1/2 pc")]
        
        let m14 = Menu(name: "Udon Noodles with Tempura", category: "Lunch")
        m14.ingredients = [Ingredient(name: "Udon Noodles", amount: "1 pack"), Ingredient(name: "Shrimp Tempura", amount: "2 pcs")]
        
        let m15 = Menu(name: "Tuna & Mayo Rice Balls", category: "Lunch")
        m15.ingredients = [Ingredient(name: "Canned Tuna", amount: "1 can"), Ingredient(name: "Rice", amount: "2 bowls"), Ingredient(name: "Nori", amount: "2 sheets")]
        
        // Dinner (16-30)
        let m16 = Menu(name: "Grilled Salmon & Vegetables", category: "Main")
        m16.ingredients = [Ingredient(name: "Salmon Fillet", amount: "2 pcs"), Ingredient(name: "Broccoli", amount: "1/2 head")]
        
        let m17 = Menu(name: "Pork Ginger Stir-fry", category: "Main")
        m17.ingredients = [Ingredient(name: "Pork Slice", amount: "200g"), Ingredient(name: "Onion", amount: "1 pc")]
        
        let m18 = Menu(name: "Hamburger Steak", category: "Main")
        m18.ingredients = [Ingredient(name: "Minced Meat", amount: "250g"), Ingredient(name: "Breadcrumbs", amount: "2 tbsp")]
        
        let m19 = Menu(name: "Chicken Katsu", category: "Main")
        m19.ingredients = [Ingredient(name: "Chicken Breast", amount: "200g"), Ingredient(name: "Panko", amount: "50g")]
        
        let m20 = Menu(name: "Beef Steak & Garlic Rice", category: "Main")
        m20.ingredients = [Ingredient(name: "Beef Steak Cut", amount: "200g"), Ingredient(name: "Garlic", amount: "2 cloves")]
        
        let m21 = Menu(name: "Mabo Tofu", category: "Main")
        m21.ingredients = [Ingredient(name: "Tofu", amount: "1 block"), Ingredient(name: "Minced Pork", amount: "100g")]
        
        let m22 = Menu(name: "Saba Miso (Mackerel)", category: "Main")
        m22.ingredients = [Ingredient(name: "Mackerel Fillet", amount: "2 pcs"), Ingredient(name: "Ginger", amount: "1 slice")]
        
        let m23 = Menu(name: "Vegetable Soup & Roast Pork", category: "Main")
        m23.ingredients = [Ingredient(name: "Roast Pork", amount: "150g"), Ingredient(name: "Cabbage", amount: "1/4 head")]
        
        let m24 = Menu(name: "Beef Stew", category: "Main")
        m24.ingredients = [Ingredient(name: "Beef Chunk", amount: "200g"), Ingredient(name: "Onion", amount: "1 pc"), Ingredient(name: "Red Wine", amount: "100ml")]
        
        let m25 = Menu(name: "Stir-fried Meat & Beansprouts", category: "Main")
        m25.ingredients = [Ingredient(name: "Pork Slice", amount: "150g"), Ingredient(name: "Bean Sprouts", amount: "1 bag")]
        
        let m26 = Menu(name: "Grilled Chicken & Asparagus", category: "Main")
        m26.ingredients = [Ingredient(name: "Chicken Leg", amount: "200g"), Ingredient(name: "Asparagus", amount: "4 spears")]
        
        let m27 = Menu(name: "Cod Poached in Butter & Herb", category: "Main")
        m27.ingredients = [Ingredient(name: "Cod Fillet", amount: "2 pcs"), Ingredient(name: "Butter", amount: "20g")]
        
        let m28 = Menu(name: "Suae (Sour & Sweet Pork)", category: "Main")
        m28.ingredients = [Ingredient(name: "Pork Cubes", amount: "200g"), Ingredient(name: "Bell Pepper", amount: "1 pc")]
        
        let m29 = Menu(name: "Sukiyaki Hot Pot", category: "Main")
        m29.ingredients = [Ingredient(name: "Beef Slices", amount: "250g"), Ingredient(name: "Tofu", amount: "1/2 block"), Ingredient(name: "Enoki Mushroom", amount: "1 pack")]
        
        let m30 = Menu(name: "Chilled Soba & Vegetable Tempura", category: "Main")
        m30.ingredients = [Ingredient(name: "Soba Noodles", amount: "200g"), Ingredient(name: "Sweet Potato", amount: "1/2 pc")]
        
        let allMenus = [m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18, m19, m20, m21, m22, m23, m24, m25, m26, m27, m28, m29, m30]
        allMenus.forEach { context.insert($0) }

        // MARK: - 3. KondatePatterns (4 Patterns) & PatternDays (16 Total)

        // Pattern 1: Standard Weekly (7 Days) - Active
        let pattern1 = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
        context.insert(pattern1)
        
        let daysP1 = [
            PatternDay(dayIndex: 0, breakfastMenu: m1, lunchMenu: m6, dinnerMenu: m16),
            PatternDay(dayIndex: 1, breakfastMenu: m2, lunchMenu: m7, dinnerMenu: m17),
            PatternDay(dayIndex: 2, breakfastMenu: m3, lunchMenu: m8, dinnerMenu: m18),
            PatternDay(dayIndex: 3, breakfastMenu: m4, lunchMenu: m9, dinnerMenu: m19),
            PatternDay(dayIndex: 4, breakfastMenu: m5, lunchMenu: m10, dinnerMenu: m20),
            PatternDay(dayIndex: 5, breakfastMenu: m1, lunchMenu: m11, dinnerMenu: m21),
            PatternDay(dayIndex: 6, breakfastMenu: m3, lunchMenu: m12, dinnerMenu: m22)
        ]
        daysP1.forEach { day in
            day.pattern = pattern1
            context.insert(day)
        }

        // Pattern 2: Quick 3-Day Rotation (3 Days)
        let pattern2 = KondatePattern(name: "Quick 3-Day Rotation", durationDays: 3, isActive: false)
        context.insert(pattern2)
        
        let daysP2 = [
            PatternDay(dayIndex: 0, breakfastMenu: m1, lunchMenu: m13, dinnerMenu: m23),
            PatternDay(dayIndex: 1, breakfastMenu: m2, lunchMenu: m14, dinnerMenu: m24),
            PatternDay(dayIndex: 2, breakfastMenu: m4, lunchMenu: m15, dinnerMenu: m25)
        ]
        daysP2.forEach { day in
            day.pattern = pattern2
            context.insert(day)
        }

        // Pattern 3: Healthy & Light (3 Days)
        let pattern3 = KondatePattern(name: "Healthy & Light", durationDays: 3, isActive: false)
        context.insert(pattern3)
        
        let daysP3 = [
            PatternDay(dayIndex: 0, breakfastMenu: m2, lunchMenu: m12, dinnerMenu: m16),
            PatternDay(dayIndex: 1, breakfastMenu: m5, lunchMenu: m9, dinnerMenu: m27),
            PatternDay(dayIndex: 2, breakfastMenu: m3, lunchMenu: m15, dinnerMenu: m30)
        ]
        daysP3.forEach { day in
            day.pattern = pattern3
            context.insert(day)
        }

        // Pattern 4: Weekend Special (2 Days)
        let pattern4 = KondatePattern(name: "Weekend Special", durationDays: 2, isActive: false)
        context.insert(pattern4)
        
        let daysP4 = [
            PatternDay(dayIndex: 0, breakfastMenu: m4, lunchMenu: m11, dinnerMenu: m20),
            PatternDay(dayIndex: 1, breakfastMenu: m5, lunchMenu: m10, dinnerMenu: m29)
        ]
        daysP4.forEach { day in
            day.pattern = pattern4
            context.insert(day)
        }

        try? context.save()
    }
}
