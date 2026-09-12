//
//  PresetDataService.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

enum PresetType: String, CaseIterable, Identifiable {
    case balanced = "Balanced Family"
    case busy = "Busy Professionals"
    case japanese = "Japanese Home"

    var id: String { rawValue }
}

struct PresetDataService {
    static func insertPresetDataIfNeeded(context: ModelContext, presetType: PresetType = .balanced) {
        let descriptor = FetchDescriptor<KondatePattern>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return
        }

        // MARK: - Preset-Specific Menus, StockItems & Patterns
        switch presetType {
        case .balanced:
            insertBalancedFamily(context: context)
        case .busy:
            insertBusyProfessionals(context: context)
        case .japanese:
            insertJapanseHome(context: context)
        }

        do {
            try context.save()
        } catch {
            print("Failed to save preset data: \(error)")
        }
    }

    // MARK: - 1. Balanced Family
    private static func insertBalancedFamily(context: ModelContext) {
        let stockItems = [
            StockItem(name: "Milk", category: .pantry),
            StockItem(name: "Eggs", category: .pantry),
            StockItem(name: "Cheddar Cheese", category: .pantry),
            StockItem(name: "Olive Oil", category: .seasoning),
            StockItem(name: "Salt & Pepper", category: .seasoning),
            StockItem(name: "Garlic Powder", category: .seasoning),
            StockItem(name: "Pasta", category: .pantry),
            StockItem(name: "Rice", category: .pantry),
            StockItem(name: "Canned Tomatoes", category: .pantry),
            StockItem(name: "Bread", category: .pantry),
            StockItem(name: "Chicken Breast", category: .pantry),
            StockItem(name: "Ground Beef", category: .pantry)
        ]
        stockItems.forEach { context.insert($0) }

        // Breakfast Menus
        let b1 = Menu(name: "Overnight Oats", category: .main)
        b1.ingredients = [
            Ingredient(name: "Rolled Oats", quantity: 1, unit: "cup", category: .pantryAndGrain),
            Ingredient(name: "Milk", quantity: 1, unit: "cup", category: .chilledAndDairy),
            Ingredient(name: "Chia Seeds", quantity: 1, unit: "tbsp", category: .pantryAndGrain),
            Ingredient(name: "Honey", quantity: 1, unit: "tbsp", category: .pantryAndGrain)
        ]

        let b2 = Menu(name: "Scrambled Eggs & Toast", category: .main)
        b2.ingredients = [
            Ingredient(name: "Eggs", quantity: 3, unit: "pcs", category: .chilledAndDairy),
            Ingredient(name: "Bread", quantity: 2, unit: "slices", category: .pantryAndGrain),
            Ingredient(name: "Butter", quantity: 1, unit: "tbsp", category: .chilledAndDairy)
        ]

        let b3 = Menu(name: "Berry Smoothie", category: .main)
        b3.ingredients = [
            Ingredient(name: "Mixed Berries", quantity: 1.5, unit: "cups", category: .produce),
            Ingredient(name: "Greek Yogurt", quantity: 0.5, unit: "cup", category: .chilledAndDairy),
            Ingredient(name: "Almond Milk", quantity: 1, unit: "cup", category: .chilledAndDairy)
        ]

        let b4 = Menu(name: "Pancakes with Maple Syrup", category: .main)
        b4.ingredients = [
            Ingredient(name: "Pancake Mix", quantity: 2, unit: "cups", category: .pantryAndGrain),
            Ingredient(name: "Milk", quantity: 1, unit: "cup", category: .chilledAndDairy),
            Ingredient(name: "Egg", quantity: 1, unit: "pc", category: .chilledAndDairy),
            Ingredient(name: "Maple Syrup", quantity: 3, unit: "tbsp", category: .pantryAndGrain)
        ]

        let b5 = Menu(name: "Avocado Toast with Poached Egg", category: .main)
        b5.ingredients = [
            Ingredient(name: "Bread", quantity: 2, unit: "slices", category: .pantryAndGrain),
            Ingredient(name: "Avocado", quantity: 1, unit: "pc", category: .produce),
            Ingredient(name: "Eggs", quantity: 2, unit: "pcs", category: .chilledAndDairy)
        ]

        let b6 = Menu(name: "Greek Yogurt Parfait", category: .main)
        b6.ingredients = [
            Ingredient(name: "Greek Yogurt", quantity: 1, unit: "cup", category: .chilledAndDairy),
            Ingredient(name: "Granola", quantity: 0.5, unit: "cup", category: .pantryAndGrain),
            Ingredient(name: "Strawberries", quantity: 5, unit: "pcs", category: .produce)
        ]

        let b7 = Menu(name: "Full English Breakfast Plate", category: .main)
        b7.ingredients = [
            Ingredient(name: "Sausages", quantity: 2, unit: "pcs", category: .meatAndFish),
            Ingredient(name: "Bacon", quantity: 2, unit: "slices", category: .meatAndFish),
            Ingredient(name: "Eggs", quantity: 2, unit: "pcs", category: .chilledAndDairy),
            Ingredient(name: "Baked Beans", quantity: 0.5, unit: "can", category: .pantryAndGrain),
            Ingredient(name: "Bread", quantity: 2, unit: "slices", category: .pantryAndGrain)
        ]

        // Lunch Menus
        let l1 = Menu(name: "Chicken Caesar Wrap", category: .main)
        l1.ingredients = [
            Ingredient(name: "Tortilla Wrap", quantity: 2, unit: "pcs", category: .pantryAndGrain),
            Ingredient(name: "Grilled Chicken Breast", quantity: 200, unit: "g", category: .meatAndFish),
            Ingredient(name: "Romaine Lettuce", quantity: 1, unit: "head", category: .produce),
            Ingredient(name: "Caesar Dressing", quantity: 2, unit: "tbsp", category: .pantryAndGrain)
        ]

        let l2 = Menu(name: "Turkey & Avocado Sandwich", category: .main)
        l2.ingredients = [
            Ingredient(name: "Bread", quantity: 2, unit: "slices", category: .pantryAndGrain),
            Ingredient(name: "Turkey Breast Slices", quantity: 100, unit: "g", category: .meatAndFish),
            Ingredient(name: "Avocado", quantity: 0.5, unit: "pc", category: .produce),
            Ingredient(name: "Cheddar Cheese", quantity: 1, unit: "slice", category: .chilledAndDairy)
        ]

        let l3 = Menu(name: "Quinoa Salad Bowl", category: .main)
        l3.ingredients = [
            Ingredient(name: "Cooked Quinoa", quantity: 1, unit: "cup", category: .pantryAndGrain),
            Ingredient(name: "Cherry Tomatoes", quantity: 8, unit: "pcs", category: .produce),
            Ingredient(name: "Cucumber", quantity: 0.5, unit: "pc", category: .produce),
            Ingredient(name: "Feta Cheese", quantity: 50, unit: "g", category: .chilledAndDairy)
        ]

        let l4 = Menu(name: "Grilled Cheese & Tomato Soup", category: .main)
        l4.ingredients = [
            Ingredient(name: "Bread", quantity: 2, unit: "slices", category: .pantryAndGrain),
            Ingredient(name: "Cheddar Cheese", quantity: 2, unit: "slices", category: .chilledAndDairy),
            Ingredient(name: "Canned Tomato Soup", quantity: 1, unit: "can", category: .pantryAndGrain)
        ]

        let l5 = Menu(name: "BLT Sandwich", category: .main)
        l5.ingredients = [
            Ingredient(name: "Bread", quantity: 2, unit: "slices", category: .pantryAndGrain),
            Ingredient(name: "Bacon", quantity: 3, unit: "slices", category: .meatAndFish),
            Ingredient(name: "Lettuce", quantity: 2, unit: "leaves", category: .produce),
            Ingredient(name: "Tomato", quantity: 1, unit: "pc", category: .produce)
        ]

        let l6 = Menu(name: "Cobb Salad", category: .main)
        l6.ingredients = [
            Ingredient(name: "Chicken Breast", quantity: 150, unit: "g", category: .meatAndFish),
            Ingredient(name: "Hard-boiled Egg", quantity: 1, unit: "pc", category: .chilledAndDairy),
            Ingredient(name: "Avocado", quantity: 0.5, unit: "pc", category: .produce),
            Ingredient(name: "Blue Cheese", quantity: 30, unit: "g", category: .chilledAndDairy)
        ]

        let l7 = Menu(name: "Tuna Melt Sandwich", category: .main)
        l7.ingredients = [
            Ingredient(name: "Canned Tuna", quantity: 1, unit: "can", category: .pantryAndGrain),
            Ingredient(name: "Mayonnaise", quantity: 1, unit: "tbsp", category: .pantryAndGrain),
            Ingredient(name: "Cheddar Cheese", quantity: 1, unit: "slice", category: .chilledAndDairy),
            Ingredient(name: "Bread", quantity: 2, unit: "slices", category: .pantryAndGrain)
        ]

        // Dinner Menus
        let d1 = Menu(name: "Sheet Pan Salmon & Veggies", category: .main)
        d1.ingredients = [
            Ingredient(name: "Salmon Fillets", quantity: 2, unit: "pcs", category: .meatAndFish),
            Ingredient(name: "Broccoli", quantity: 1, unit: "head", category: .produce),
            Ingredient(name: "Carrots", quantity: 2, unit: "pcs", category: .produce),
            Ingredient(name: "Olive Oil", quantity: 2, unit: "tbsp", category: .pantryAndGrain)
        ]

        let d2 = Menu(name: "Classic Spaghetti Bolognese", category: .main)
        d2.ingredients = [
            Ingredient(name: "Spaghetti", quantity: 250, unit: "g", category: .pantryAndGrain),
            Ingredient(name: "Ground Beef", quantity: 300, unit: "g", category: .meatAndFish),
            Ingredient(name: "Canned Tomatoes", quantity: 1, unit: "can", category: .pantryAndGrain),
            Ingredient(name: "Onion", quantity: 1, unit: "pc", category: .produce)
        ]

        let d3 = Menu(name: "Beef Tacos", category: .main)
        d3.ingredients = [
            Ingredient(name: "Ground Beef", quantity: 300, unit: "g", category: .meatAndFish),
            Ingredient(name: "Taco Shells", quantity: 6, unit: "pcs", category: .pantryAndGrain),
            Ingredient(name: "Shredded Lettuce", quantity: 1, unit: "cup", category: .produce),
            Ingredient(name: "Salsa", quantity: 0.5, unit: "cup", category: .pantryAndGrain)
        ]

        let d4 = Menu(name: "Grilled Chicken & Sweet Potatoes", category: .main)
        d4.ingredients = [
            Ingredient(name: "Chicken Breast", quantity: 300, unit: "g", category: .meatAndFish),
            Ingredient(name: "Sweet Potatoes", quantity: 2, unit: "pcs", category: .produce),
            Ingredient(name: "Green Beans", quantity: 150, unit: "g", category: .produce)
        ]

        let d5 = Menu(name: "Homemade Pepperoni Pizza", category: .main)
        d5.ingredients = [
            Ingredient(name: "Pizza Dough", quantity: 1, unit: "pc", category: .pantryAndGrain),
            Ingredient(name: "Pizza Sauce", quantity: 0.5, unit: "cup", category: .pantryAndGrain),
            Ingredient(name: "Mozzarella Cheese", quantity: 150, unit: "g", category: .chilledAndDairy),
            Ingredient(name: "Pepperoni Slices", quantity: 50, unit: "g", category: .meatAndFish)
        ]

        let d6 = Menu(name: "Shepherd's Pie", category: .main)
        d6.ingredients = [
            Ingredient(name: "Ground Beef", quantity: 300, unit: "g", category: .meatAndFish),
            Ingredient(name: "Potatoes", quantity: 3, unit: "pcs", category: .produce),
            Ingredient(name: "Frozen Peas & Carrots", quantity: 1, unit: "cup", category: .produce),
            Ingredient(name: "Butter", quantity: 2, unit: "tbsp", category: .chilledAndDairy)
        ]

        let d7 = Menu(name: "Roast Beef Dinner", category: .main)
        d7.ingredients = [
            Ingredient(name: "Beef Roast Cut", quantity: 500, unit: "g", category: .meatAndFish),
            Ingredient(name: "Potatoes", quantity: 4, unit: "pcs", category: .produce),
            Ingredient(name: "Gravy Mix", quantity: 1, unit: "packet", category: .pantryAndGrain)
        ]

        let allMenus = [
            b1, b2, b3, b4, b5, b6, b7,
            l1, l2, l3, l4, l5, l6, l7,
            d1, d2, d3, d4, d5, d6, d7
        ]
        allMenus.forEach { context.insert($0) }

        let pattern = KondatePattern(name: "Balanced Family", durationDays: 7, isActive: true)
        context.insert(pattern)

        let breakfasts = [b1, b2, b3, b4, b5, b6, b7]
        let lunches = [l1, l2, l3, l4, l5, l6, l7]
        let dinners = [d1, d2, d3, d4, d5, d6, d7]

        let days = (0..<7).map { index in
            PatternDay(
                dayIndex: index,
                breakfastMenus: [breakfasts[index]],
                lunchMenus: [lunches[index]],
                dinnerMenus: [dinners[index]]
            )
        }
        days.forEach {
            $0.pattern = pattern
            context.insert($0)
        }
    }

    // MARK: - 2. Busy Professionals
    private static func insertBusyProfessionals(context: ModelContext) {
        let stockItems = [
            StockItem(name: "Consommé Cubes", category: .seasoning),
            StockItem(name: "Curry Roux", category: .pantry),
            StockItem(name: "Olive Oil", category: .seasoning),
            StockItem(name: "Salt & Pepper", category: .seasoning),
            StockItem(name: "Pasta", category: .pantry),
            StockItem(name: "Rice", category: .pantry),
            StockItem(name: "Frozen Vegetables", category: .pantry),
            StockItem(name: "Eggs", category: .pantry),
            StockItem(name: "Canned Tuna", category: .pantry),
            StockItem(name: "Instant Miso Soup", category: .pantry),
            StockItem(name: "Frozen Gyoza", category: .pantry),
            StockItem(name: "Tomato Sauce", category: .pantry)
        ]
        stockItems.forEach { context.insert($0) }

        // Breakfast Menus
        let b1 = Menu(name: "Quick Granola & Yogurt", category: .main)
        b1.ingredients = [
            Ingredient(name: "Granola", quantity: 1, unit: "cup", category: .pantryAndGrain),
            Ingredient(name: "Yogurt", quantity: 0.5, unit: "cup", category: .chilledAndDairy)
        ]

        let b2 = Menu(name: "Tuna Toast", category: .main)
        b2.ingredients = [
            Ingredient(name: "Bread", quantity: 1, unit: "slice", category: .pantryAndGrain),
            Ingredient(name: "Canned Tuna", quantity: 0.5, unit: "can", category: .pantryAndGrain),
            Ingredient(name: "Mayonnaise", quantity: 1, unit: "tbsp", category: .pantryAndGrain)
        ]

        let b3 = Menu(name: "Scrambled Eggs & Sausage", category: .main)
        b3.ingredients = [
            Ingredient(name: "Eggs", quantity: 2, unit: "pcs", category: .chilledAndDairy),
            Ingredient(name: "Sausages", quantity: 2, unit: "pcs", category: .meatAndFish)
        ]

        let b4 = Menu(name: "Instant Miso & Rice", category: .main)
        b4.ingredients = [
            Ingredient(name: "Instant Miso Soup Packet", quantity: 1, unit: "pc", category: .pantryAndGrain),
            Ingredient(name: "Pre-cooked Rice Pack", quantity: 1, unit: "pc", category: .pantryAndGrain)
        ]

        let b5 = Menu(name: "Cheese Toast", category: .main)
        b5.ingredients = [
            Ingredient(name: "Bread", quantity: 1, unit: "slice", category: .pantryAndGrain),
            Ingredient(name: "Sliced Cheese", quantity: 1, unit: "slice", category: .chilledAndDairy)
        ]

        let b6 = Menu(name: "Banana Smoothie & Toast", category: .main)
        b6.ingredients = [
            Ingredient(name: "Banana", quantity: 1, unit: "pc", category: .produce),
            Ingredient(name: "Milk", quantity: 1, unit: "cup", category: .chilledAndDairy),
            Ingredient(name: "Bread", quantity: 1, unit: "slice", category: .pantryAndGrain)
        ]

        let b7 = Menu(name: "Fried Egg on Toast", category: .main)
        b7.ingredients = [
            Ingredient(name: "Egg", quantity: 1, unit: "pc", category: .chilledAndDairy),
            Ingredient(name: "Bread", quantity: 1, unit: "slice", category: .pantryAndGrain)
        ]

        // Lunch Menus
        let l1 = Menu(name: "Pasta Carbonara", category: .main)
        l1.ingredients = [
            Ingredient(name: "Pasta", quantity: 100, unit: "g", category: .pantryAndGrain),
            Ingredient(name: "Bacon", quantity: 2, unit: "slices", category: .meatAndFish),
            Ingredient(name: "Egg", quantity: 1, unit: "pc", category: .chilledAndDairy),
            Ingredient(name: "Parmesan Cheese", quantity: 2, unit: "tbsp", category: .chilledAndDairy)
        ]

        let l2 = Menu(name: "Quick Fried Rice", category: .main)
        l2.ingredients = [
            Ingredient(name: "Pre-cooked Rice Pack", quantity: 1, unit: "pc", category: .pantryAndGrain),
            Ingredient(name: "Egg", quantity: 1, unit: "pc", category: .chilledAndDairy),
            Ingredient(name: "Frozen Mixed Veggies", quantity: 0.5, unit: "cup", category: .produce)
        ]

        let l3 = Menu(name: "Tomato Pasta", category: .main)
        l3.ingredients = [
            Ingredient(name: "Pasta", quantity: 100, unit: "g", category: .pantryAndGrain),
            Ingredient(name: "Jarred Tomato Sauce", quantity: 0.5, unit: "cup", category: .pantryAndGrain)
        ]

        let l4 = Menu(name: "Frozen Gyoza Set", category: .main)
        l4.ingredients = [
            Ingredient(name: "Frozen Gyoza", quantity: 6, unit: "pcs", category: .meatAndFish),
            Ingredient(name: "Pre-cooked Rice Pack", quantity: 1, unit: "pc", category: .pantryAndGrain)
        ]

        let l5 = Menu(name: "Tuna Tomato Spaghetti", category: .main)
        l5.ingredients = [
            Ingredient(name: "Spaghetti", quantity: 100, unit: "g", category: .pantryAndGrain),
            Ingredient(name: "Canned Tuna", quantity: 1, unit: "can", category: .pantryAndGrain),
            Ingredient(name: "Canned Tomato Sauce", quantity: 0.5, unit: "cup", category: .pantryAndGrain)
        ]

        let l6 = Menu(name: "Egg & Rice Bowl", category: .main)
        l6.ingredients = [
            Ingredient(name: "Pre-cooked Rice Pack", quantity: 1, unit: "pc", category: .pantryAndGrain),
            Ingredient(name: "Egg", quantity: 2, unit: "pcs", category: .chilledAndDairy),
            Ingredient(name: "Soy Sauce", quantity: 1, unit: "tbsp", category: .pantryAndGrain)
        ]

        let l7 = Menu(name: "Instant Ramen with Veggies", category: .main)
        l7.ingredients = [
            Ingredient(name: "Instant Ramen Pack", quantity: 1, unit: "pc", category: .pantryAndGrain),
            Ingredient(name: "Frozen Vegetables", quantity: 0.5, unit: "cup", category: .produce),
            Ingredient(name: "Hard-boiled Egg", quantity: 1, unit: "pc", category: .chilledAndDairy)
        ]

        // Dinner Menus
        let d1 = Menu(name: "Japanese Curry Rice", category: .main)
        d1.ingredients = [
            Ingredient(name: "Curry Roux", quantity: 2, unit: "cubes", category: .pantryAndGrain),
            Ingredient(name: "Pork Slice", quantity: 150, unit: "g", category: .meatAndFish),
            Ingredient(name: "Onion", quantity: 1, unit: "pc", category: .produce),
            Ingredient(name: "Rice", quantity: 1, unit: "cup", category: .pantryAndGrain)
        ]

        let d2 = Menu(name: "Quick Stir-fried Pork", category: .main)
        d2.ingredients = [
            Ingredient(name: "Pork Belly Slices", quantity: 200, unit: "g", category: .meatAndFish),
            Ingredient(name: "Cabbage", quantity: 0.25, unit: "head", category: .produce),
            Ingredient(name: "Soy Sauce", quantity: 1, unit: "tbsp", category: .pantryAndGrain)
        ]

        let d3 = Menu(name: "Consommé Vegetable Stew", category: .main)
        d3.ingredients = [
            Ingredient(name: "Consommé Cube", quantity: 1, unit: "pc", category: .pantryAndGrain),
            Ingredient(name: "Frozen Veggie Mix", quantity: 1, unit: "cup", category: .produce),
            Ingredient(name: "Sausages", quantity: 2, unit: "pcs", category: .meatAndFish)
        ]

        let d4 = Menu(name: "One-Pan Bolognese Pasta", category: .main)
        d4.ingredients = [
            Ingredient(name: "Pasta", quantity: 100, unit: "g", category: .pantryAndGrain),
            Ingredient(name: "Ground Pork", quantity: 150, unit: "g", category: .meatAndFish),
            Ingredient(name: "Jarred Bolognese Sauce", quantity: 0.5, unit: "cup", category: .pantryAndGrain)
        ]

        let d5 = Menu(name: "Quick Chicken Rice", category: .main)
        d5.ingredients = [
            Ingredient(name: "Pre-cooked Rice Pack", quantity: 1, unit: "pc", category: .pantryAndGrain),
            Ingredient(name: "Chicken Thigh Slices", quantity: 150, unit: "g", category: .meatAndFish),
            Ingredient(name: "Ketchup", quantity: 2, unit: "tbsp", category: .pantryAndGrain)
        ]

        let d6 = Menu(name: "Easy Pork & Cabbage Fry", category: .main)
        d6.ingredients = [
            Ingredient(name: "Pork Shoulder Slices", quantity: 200, unit: "g", category: .meatAndFish),
            Ingredient(name: "Cut Cabbage Bag", quantity: 1, unit: "bag", category: .produce)
        ]

        let d7 = Menu(name: "Quick Hayashi Rice", category: .main)
        d7.ingredients = [
            Ingredient(name: "Hayashi Rice Roux", quantity: 2, unit: "cubes", category: .pantryAndGrain),
            Ingredient(name: "Sliced Beef", quantity: 150, unit: "g", category: .meatAndFish),
            Ingredient(name: "Onion", quantity: 1, unit: "pc", category: .produce),
            Ingredient(name: "Rice", quantity: 1, unit: "cup", category: .pantryAndGrain)
        ]

        let allMenus = [
            b1, b2, b3, b4, b5, b6, b7,
            l1, l2, l3, l4, l5, l6, l7,
            d1, d2, d3, d4, d5, d6, d7
        ]
        allMenus.forEach { context.insert($0) }

        let pattern = KondatePattern(name: "Quick Weekly Rotation", durationDays: 7, isActive: true)
        context.insert(pattern)

        let breakfasts = [b1, b2, b3, b4, b5, b6, b7]
        let lunches = [l1, l2, l3, l4, l5, l6, l7]
        let dinners = [d1, d2, d3, d4, d5, d6, d7]

        let days = (0..<7).map { index in
            PatternDay(
                dayIndex: index,
                breakfastMenus: [breakfasts[index]],
                lunchMenus: [lunches[index]],
                dinnerMenus: [dinners[index]]
            )
        }
        days.forEach {
            $0.pattern = pattern
            context.insert($0)
        }
    }

    // MARK: - 3. Japanese Home
    private static func insertJapanseHome(context: ModelContext) {
        let stockItems = [
            // Pantry
            StockItem(name: "パン", category: .pantry),
            StockItem(name: "ヨーグルト", category: .pantry),
            StockItem(name: "豆乳", category: .pantry),
            StockItem(name: "牛乳", category: .pantry),
            StockItem(name: "チーズ", category: .pantry),
            StockItem(name: "バナナ", category: .pantry),
            StockItem(name: "プチトマト", category: .pantry),
            StockItem(name: "バター", category: .pantry),
            StockItem(name: "昆布", category: .pantry),
            StockItem(name: "粉チーズ", category: .pantry),
            StockItem(name: "フレークチーズ", category: .pantry),
            StockItem(name: "小麦粉", category: .pantry),
            StockItem(name: "片栗粉", category: .pantry),
            StockItem(name: "パン粉", category: .pantry),
            StockItem(name: "お好み焼き粉", category: .pantry),

            // Seasoning
            StockItem(name: "酒", category: .seasoning),
            StockItem(name: "みりん", category: .seasoning),
            StockItem(name: "醤油", category: .seasoning),
            StockItem(name: "ごま油", category: .seasoning),
            StockItem(name: "オリーブオイル", category: .seasoning),
            StockItem(name: "油", category: .seasoning),
            StockItem(name: "テーブルソルト", category: .seasoning),
            StockItem(name: "こしょう", category: .seasoning),
            StockItem(name: "ラー油", category: .seasoning),
            StockItem(name: "唐辛子", category: .seasoning),
            StockItem(name: "七味", category: .seasoning),
            StockItem(name: "バジル", category: .seasoning),
            StockItem(name: "白ワイン", category: .seasoning),
            StockItem(name: "砂糖", category: .seasoning),
            StockItem(name: "塩", category: .seasoning),
            StockItem(name: "はちみつ", category: .seasoning),
            StockItem(name: "白だし", category: .seasoning),
            StockItem(name: "めんつゆ", category: .seasoning),
            StockItem(name: "しょうが", category: .seasoning),
            StockItem(name: "にんにく", category: .seasoning),
            StockItem(name: "お好みソース", category: .seasoning),
            StockItem(name: "玉ねぎドレッシング", category: .seasoning),
            StockItem(name: "みそ", category: .seasoning),
            StockItem(name: "ケチャップ", category: .seasoning),
            StockItem(name: "コチュジャン", category: .seasoning),
            StockItem(name: "コンソメ", category: .seasoning),
            StockItem(name: "鶏ガラスープ", category: .seasoning),

            // Household
            StockItem(name: "クレラップ", category: .household),
            StockItem(name: "ラップ（小）", category: .household),
            StockItem(name: "ゴミ袋", category: .household),
            StockItem(name: "ビニール袋", category: .household),
            StockItem(name: "ハンドソープ", category: .household),
            StockItem(name: "食器洗い洗剤", category: .household),
            StockItem(name: "アルコールスプレー", category: .household),
            StockItem(name: "ティッシュ", category: .household),
            StockItem(name: "トイレットペーパー", category: .household),
            StockItem(name: "洗濯洗剤", category: .household),
            StockItem(name: "お風呂洗剤", category: .household)
        ]
        stockItems.forEach { context.insert($0) }

        // MARK: - Menu Creation Cache
        var menuCache: [String: Menu] = [:]
        func getOrCreateMenu(name: String, category: MenuCategory) -> Menu {
            let key = "\(name)_\(category.rawValue)"
            if let existing = menuCache[key] {
                return existing
            }
            let menu = Menu(name: name, category: category)
            context.insert(menu)
            menuCache[key] = menu
            return menu
        }

        // MARK: - Ingredients Mapping
        struct RawIngredient {
            let menuName: String
            let name: String
            let quantity: Double
            let unit: String
        }

        let rawIngredients: [RawIngredient] = [
            RawIngredient(menuName: "鮭とキノコのクリーム煮", name: "生鮭", quantity: 3, unit: "切"),
            RawIngredient(menuName: "鮭とキノコのクリーム煮", name: "しめじ", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "鮭とキノコのクリーム煮", name: "ほうれん草", quantity: 0.3, unit: "束"),
            RawIngredient(menuName: "鮭とキノコのクリーム煮", name: "牛乳", quantity: 280, unit: "g"),
            RawIngredient(menuName: "チキンソテー（トマト）", name: "鶏もも肉", quantity: 300, unit: "g"),
            RawIngredient(menuName: "チキンソテー（トマト）", name: "トマト缶", quantity: 0.5, unit: "パック"),
            RawIngredient(menuName: "チキンソテー（トマト）", name: "玉ねぎ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "麻婆豆腐", name: "合いびき肉", quantity: 300, unit: "g"),
            RawIngredient(menuName: "麻婆豆腐", name: "長ネギ", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "麻婆豆腐", name: "豆腐", quantity: 300, unit: "g"),
            RawIngredient(menuName: "豚肉トマト煮込み", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "豚肉トマト煮込み", name: "豚ロース肉", quantity: 200, unit: "g"),
            RawIngredient(menuName: "豚肉トマト煮込み", name: "トマト缶", quantity: 0.5, unit: "パック"),
            RawIngredient(menuName: "照り焼きチキン", name: "鶏もも肉", quantity: 500, unit: "g"),
            RawIngredient(menuName: "豚肉とトマト重ね蒸し", name: "豚ロース肉", quantity: 200, unit: "g"),
            RawIngredient(menuName: "豚肉とトマト重ね蒸し", name: "トマト", quantity: 2, unit: "個"),
            RawIngredient(menuName: "豚肉とトマト重ね蒸し", name: "えのき", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "豚肉とトマト重ね蒸し", name: "青じそ", quantity: 10, unit: "枚"),
            RawIngredient(menuName: "簡単トマト煮込みハンバーグ", name: "合いびき肉", quantity: 320, unit: "g"),
            RawIngredient(menuName: "簡単トマト煮込みハンバーグ", name: "玉ねぎ", quantity: 1, unit: "個"),
            RawIngredient(menuName: "簡単トマト煮込みハンバーグ", name: "しめじ", quantity: 0.5, unit: "パック"),
            RawIngredient(menuName: "簡単トマト煮込みハンバーグ", name: "トマト缶", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "簡単トマト煮込みハンバーグ", name: "卵", quantity: 1, unit: "個"),
            RawIngredient(menuName: "豚生姜焼き（さくなし）", name: "豚こま肉", quantity: 200, unit: "g"),
            RawIngredient(menuName: "野菜たっぷりカレーライス", name: "豚こま肉", quantity: 200, unit: "g"),
            RawIngredient(menuName: "野菜たっぷりカレーライス", name: "玉ねぎ", quantity: 1, unit: "個"),
            RawIngredient(menuName: "野菜たっぷりカレーライス", name: "にんじん", quantity: 1, unit: "本"),
            RawIngredient(menuName: "野菜たっぷりカレーライス", name: "じゃがいも", quantity: 2, unit: "個"),
            RawIngredient(menuName: "野菜たっぷりカレーライス", name: "カレールー", quantity: 80, unit: "g"),
            RawIngredient(menuName: "野菜たっぷりカレーライス", name: "トマト缶", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "大葉とチーズのミルフィーユカツ", name: "豚ロース肉", quantity: 250, unit: "g"),
            RawIngredient(menuName: "大葉とチーズのミルフィーユカツ", name: "スライスチーズ", quantity: 4, unit: "枚"),
            RawIngredient(menuName: "大葉とチーズのミルフィーユカツ", name: "青じそ", quantity: 4, unit: "枚"),
            RawIngredient(menuName: "鶏の唐揚げ", name: "鶏もも肉(切)", quantity: 400, unit: "g"),
            RawIngredient(menuName: "ユーリンチー", name: "鶏もも肉", quantity: 300, unit: "g"),
            RawIngredient(menuName: "ユーリンチー", name: "長ネギ", quantity: 0.25, unit: "本"),
            RawIngredient(menuName: "ぶりの照り焼き", name: "ぶり", quantity: 3, unit: "切"),
            RawIngredient(menuName: "豆腐入り月見つくね", name: "鶏ひき肉", quantity: 200, unit: "g"),
            RawIngredient(menuName: "豆腐入り月見つくね", name: "豆腐", quantity: 75, unit: "g"),
            RawIngredient(menuName: "豆腐入り月見つくね", name: "卵", quantity: 3, unit: "個"),
            RawIngredient(menuName: "肉じゃが", name: "牛薄切り肉", quantity: 150, unit: "g"),
            RawIngredient(menuName: "肉じゃが", name: "玉ねぎ", quantity: 1, unit: "個"),
            RawIngredient(menuName: "肉じゃが", name: "じゃがいも", quantity: 4, unit: "個"),
            RawIngredient(menuName: "肉じゃが", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "たらのムニエル", name: "たら", quantity: 3, unit: "切"),
            RawIngredient(menuName: "プルコギ", name: "牛薄切り肉", quantity: 300, unit: "g"),
            RawIngredient(menuName: "プルコギ", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "プルコギ", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "プルコギ", name: "ニラ", quantity: 0.5, unit: "束"),
            RawIngredient(menuName: "ローストビーフ", name: "牛もも肉（塊）", quantity: 300, unit: "g"),
            RawIngredient(menuName: "ステーキ", name: "牛ステーキ肉", quantity: 300, unit: "g"),
            RawIngredient(menuName: "メンチカツ", name: "合いびき肉", quantity: 250, unit: "g"),
            RawIngredient(menuName: "メンチカツ", name: "玉ねぎ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "メンチカツ", name: "卵", quantity: 1, unit: "個"),
            RawIngredient(menuName: "スペアリブの煮込み", name: "スペアリブ肉", quantity: 400, unit: "g"),
            RawIngredient(menuName: "スペアリブの煮込み", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "豚の角煮", name: "豚肩ロース（塊）", quantity: 800, unit: "g"),
            RawIngredient(menuName: "豚の角煮", name: "ネギの青い部分", quantity: 1, unit: "本"),
            RawIngredient(menuName: "餃子", name: "冷凍餃子", quantity: 1, unit: "袋"),
            RawIngredient(menuName: "スコップコロッケ", name: "合いびき肉", quantity: 200, unit: "g"),
            RawIngredient(menuName: "スコップコロッケ", name: "じゃがいも", quantity: 4, unit: "個"),
            RawIngredient(menuName: "スコップコロッケ", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "ひじきの煮物", name: "芽ひじき", quantity: 11, unit: "g"),
            RawIngredient(menuName: "ひじきの煮物", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "ひじきの煮物", name: "ちくわ", quantity: 1, unit: "本"),
            RawIngredient(menuName: "アンチョビキャベツ", name: "キャペツ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "アンチョビキャベツ", name: "アンチョビ", quantity: 3, unit: "枚"),
            RawIngredient(menuName: "トマトサラダ", name: "トマト", quantity: 1, unit: "個"),
            RawIngredient(menuName: "トマトサラダ", name: "玉ねぎ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "ほうれん草としらすのおひたし", name: "ほうれん草", quantity: 1, unit: "束"),
            RawIngredient(menuName: "ほうれん草としらすのおひたし", name: "しらす", quantity: 20, unit: "g"),
            RawIngredient(menuName: "にんじんしりしり", name: "にんじん", quantity: 1, unit: "本"),
            RawIngredient(menuName: "にんじんしりしり", name: "ツナ", quantity: 1, unit: "缶"),
            RawIngredient(menuName: "なす味噌炒め", name: "なす", quantity: 5, unit: "個"),
            RawIngredient(menuName: "きんぴらごぼう", name: "ごぼう", quantity: 1, unit: "本"),
            RawIngredient(menuName: "きんぴらごぼう", name: "にんじん", quantity: 1, unit: "本"),
            RawIngredient(menuName: "かぼちゃの煮物", name: "かぼちゃ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "エビサラダ", name: "レタス", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "エビサラダ", name: "冷凍エビ", quantity: 0.25, unit: "袋"),
            RawIngredient(menuName: "切り干し大根の煮物", name: "切り干し大根", quantity: 35, unit: "g"),
            RawIngredient(menuName: "切り干し大根の煮物", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "切り干し大根の煮物", name: "ちくわ", quantity: 2, unit: "本"),
            RawIngredient(menuName: "ブロッコリーとしらすのおかか和え", name: "ブロッコリー", quantity: 1, unit: "個"),
            RawIngredient(menuName: "ブロッコリーとしらすのおかか和え", name: "しらす", quantity: 20, unit: "g"),
            RawIngredient(menuName: "カプレーゼ", name: "トマト", quantity: 1, unit: "個"),
            RawIngredient(menuName: "カプレーゼ", name: "モッツァレラ", quantity: 1, unit: "個"),
            RawIngredient(menuName: "焼きびたし", name: "なす", quantity: 3, unit: "個"),
            RawIngredient(menuName: "ほうれん草とにんじんのナムル", name: "ほうれん草", quantity: 1, unit: "束"),
            RawIngredient(menuName: "ほうれん草とにんじんのナムル", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "豆苗とツナの和風炒め", name: "豆苗", quantity: 1, unit: "袋"),
            RawIngredient(menuName: "豆苗とツナの和風炒め", name: "ツナ", quantity: 1, unit: "缶"),
            RawIngredient(menuName: "アンチョビブロッコリー", name: "ブロッコリー", quantity: 1, unit: "個"),
            RawIngredient(menuName: "アンチョビブロッコリー", name: "アンチョビ", quantity: 3, unit: "枚"),
            RawIngredient(menuName: "レタスオイスター炒め", name: "レタス", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "牛すじの煮込み", name: "牛すじ", quantity: 500, unit: "g"),
            RawIngredient(menuName: "牛すじの煮込み", name: "こんにゃく", quantity: 1, unit: "枚"),
            RawIngredient(menuName: "牛すじの煮込み", name: "ネギの青い部分", quantity: 1, unit: "本"),
            RawIngredient(menuName: "トマト卵炒め", name: "トマト", quantity: 1, unit: "個"),
            RawIngredient(menuName: "トマト卵炒め", name: "卵", quantity: 2, unit: "個"),
            RawIngredient(menuName: "鶏と大根の煮物", name: "鶏もも肉(切)", quantity: 120, unit: "g"),
            RawIngredient(menuName: "鶏と大根の煮物", name: "大根", quantity: 250, unit: "g"),
            RawIngredient(menuName: "和風しいたけマヨ", name: "しいたけ", quantity: 1, unit: "袋"),
            RawIngredient(menuName: "トマトのマリネサラダ", name: "トマト", quantity: 3, unit: "個"),
            RawIngredient(menuName: "オムライス", name: "鶏もも肉(切)", quantity: 80, unit: "g"),
            RawIngredient(menuName: "オムライス", name: "玉ねぎ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "オムライス", name: "にんじん", quantity: 0.2, unit: "本"),
            RawIngredient(menuName: "オムライス", name: "卵", quantity: 5, unit: "個"),
            RawIngredient(menuName: "ポークケチャップ", name: "豚こま肉", quantity: 200, unit: "g"),
            RawIngredient(menuName: "ポークケチャップ", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "ミートソースパスタ", name: "合いびき肉", quantity: 250, unit: "g"),
            RawIngredient(menuName: "ミートソースパスタ", name: "玉ねぎ", quantity: 1, unit: "個"),
            RawIngredient(menuName: "ミートソースパスタ", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "ミートソースパスタ", name: "スパゲッティ", quantity: 300, unit: "g"),
            RawIngredient(menuName: "ミートソースパスタ", name: "トマト缶", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "チヂミ", name: "ニラ", quantity: 1, unit: "束"),
            RawIngredient(menuName: "チヂミ", name: "豚バラ肉", quantity: 100, unit: "g"),
            RawIngredient(menuName: "チヂミ", name: "キムチ", quantity: 1, unit: "袋"),
            RawIngredient(menuName: "カオマンガイ", name: "鶏もも肉", quantity: 500, unit: "g"),
            RawIngredient(menuName: "カオマンガイ", name: "長ネギ", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "ささみユッケ丼", name: "ささみ", quantity: 6, unit: "本"),
            RawIngredient(menuName: "ささみユッケ丼", name: "卵", quantity: 2, unit: "個"),
            RawIngredient(menuName: "ツナトマトパスタ", name: "スパゲッティ", quantity: 300, unit: "g"),
            RawIngredient(menuName: "ツナトマトパスタ", name: "ツナ", quantity: 1, unit: "缶"),
            RawIngredient(menuName: "ツナトマトパスタ", name: "トマト缶", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "お好み焼き", name: "お好み焼き粉", quantity: 100, unit: "g"),
            RawIngredient(menuName: "お好み焼き", name: "キャペツ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "お好み焼き", name: "豚バラ肉", quantity: 100, unit: "g"),
            RawIngredient(menuName: "お好み焼き", name: "冷凍エビ", quantity: 0.25, unit: "袋"),
            RawIngredient(menuName: "親子丼", name: "鶏もも肉(切)", quantity: 240, unit: "g"),
            RawIngredient(menuName: "親子丼", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "親子丼", name: "卵", quantity: 2, unit: "個"),
            RawIngredient(menuName: "炒飯", name: "卵", quantity: 1, unit: "個"),
            RawIngredient(menuName: "炒飯", name: "ハム", quantity: 70, unit: "g"),
            RawIngredient(menuName: "炒飯", name: "長ネギ", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "ガパオライス", name: "鶏ひき肉", quantity: 300, unit: "g"),
            RawIngredient(menuName: "ガパオライス", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "ガパオライス", name: "ピーマン", quantity: 1, unit: "個"),
            RawIngredient(menuName: "ガパオライス", name: "卵", quantity: 3, unit: "個"),
            RawIngredient(menuName: "リゾット", name: "トマト缶", quantity: 0.5, unit: "パック"),
            RawIngredient(menuName: "リゾット", name: "玉ねぎ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "リゾット", name: "しめじ", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "リゾット", name: "ベーコン", quantity: 1, unit: "袋"),
            RawIngredient(menuName: "ビビンバ", name: "合いびき肉", quantity: 250, unit: "g"),
            RawIngredient(menuName: "ビビンバ", name: "ほうれん草", quantity: 1, unit: "束"),
            RawIngredient(menuName: "ビビンバ", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "ビビンバ", name: "もやし", quantity: 1, unit: "袋"),
            RawIngredient(menuName: "よだれどり", name: "鶏むね肉", quantity: 400, unit: "g"),
            RawIngredient(menuName: "よだれどり", name: "長ネギ", quantity: 0.25, unit: "本"),
            RawIngredient(menuName: "マカロニグラタン", name: "マカロニ", quantity: 100, unit: "g"),
            RawIngredient(menuName: "マカロニグラタン", name: "鶏もも肉", quantity: 125, unit: "g"),
            RawIngredient(menuName: "マカロニグラタン", name: "玉ねぎ", quantity: 1, unit: "個"),
            RawIngredient(menuName: "マカロニグラタン", name: "牛乳", quantity: 400, unit: "g"),
            RawIngredient(menuName: "きのこの和風パスタ", name: "スパゲッティ", quantity: 280, unit: "g"),
            RawIngredient(menuName: "きのこの和風パスタ", name: "しめじ", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "きのこの和風パスタ", name: "ツナ", quantity: 2, unit: "缶"),
            RawIngredient(menuName: "塩焼きそば", name: "焼きそば麺", quantity: 3, unit: "袋"),
            RawIngredient(menuName: "塩焼きそば", name: "豚ロース肉", quantity: 100, unit: "g"),
            RawIngredient(menuName: "塩焼きそば", name: "キャペツ", quantity: 0.1, unit: "個"),
            RawIngredient(menuName: "塩焼きそば", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "ポトフ", name: "白菜", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "ポトフ", name: "じゃがいも", quantity: 2, unit: "個"),
            RawIngredient(menuName: "ポトフ", name: "ソーセージ", quantity: 8, unit: "本"),
            RawIngredient(menuName: "ラザニエッテ", name: "合いびき肉", quantity: 200, unit: "g"),
            RawIngredient(menuName: "鮭とかぼちゃのグラタン", name: "生鮭", quantity: 2, unit: "切"),
            RawIngredient(menuName: "鮭とかぼちゃのグラタン", name: "かぼちゃ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "鮭とかぼちゃのグラタン", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "鮭とかぼちゃのグラタン", name: "牛乳", quantity: 300, unit: "g"),
            RawIngredient(menuName: "かぼちゃのポタージュ", name: "牛乳", quantity: 300, unit: "g"),
            RawIngredient(menuName: "かぼちゃのポタージュ", name: "玉ねぎ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "かぼちゃのポタージュ", name: "かぼちゃ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "じゃがいものポタージュ", name: "牛乳", quantity: 400, unit: "g"),
            RawIngredient(menuName: "じゃがいものポタージュ", name: "長ネギ", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "じゃがいものポタージュ", name: "じゃがいも", quantity: 1, unit: "個"),
            RawIngredient(menuName: "ほうれん草のすまし汁", name: "ほうれん草", quantity: 0.5, unit: "束"),
            RawIngredient(menuName: "ほうれん草のすまし汁", name: "しめじ", quantity: 0.5, unit: "パック"),
            RawIngredient(menuName: "にんじんのポタージュ", name: "玉ねぎ", quantity: 0.25, unit: "個"),
            RawIngredient(menuName: "にんじんのポタージュ", name: "にんじん", quantity: 1, unit: "本"),
            RawIngredient(menuName: "さつまいもの味噌汁", name: "さつまいも", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "さつまいもの味噌汁", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "さつまいもの味噌汁", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "ミネストローネ", name: "玉ねぎ", quantity: 0.5, unit: "個"),
            RawIngredient(menuName: "ミネストローネ", name: "にんじん", quantity: 0.5, unit: "本"),
            RawIngredient(menuName: "ミネストローネ", name: "じゃがいも", quantity: 1, unit: "個"),
            RawIngredient(menuName: "ミネストローネ", name: "トマト缶", quantity: 1, unit: "パック"),
            RawIngredient(menuName: "豆腐とわかめの味噌汁", name: "豆腐", quantity: 150, unit: "g"),
            RawIngredient(menuName: "豆腐とわかめの味噌汁", name: "わかめ", quantity: 1, unit: "g"),
            RawIngredient(menuName: "トマトと卵のスープ", name: "トマト", quantity: 1, unit: "個"),
            RawIngredient(menuName: "トマトと卵のスープ", name: "卵", quantity: 2, unit: "個"),
            RawIngredient(menuName: "コーンポタージュ", name: "牛乳", quantity: 200, unit: "ml"),
            RawIngredient(menuName: "コーンポタージュ", name: "コーンパック", quantity: 1, unit: "個")
        ]

        // MARK: - Patterns Setup
        struct DayData {
            let lunchMain: String
            let lunchSide: String?
            let lunchSoup: String?
            let dinnerMain: String
            let dinnerSide: String?
            let dinnerSoup: String?
        }

        let patternDefinitions: [(name: String, days: [DayData])] = [
            ("Pattern A", [
                DayData(lunchMain: "オムライス", lunchSide: nil, lunchSoup: nil, dinnerMain: "プルコギ", dinnerSide: "アンチョビキャベツ", dinnerSoup: nil),
                DayData(lunchMain: "ポークケチャップ", lunchSide: nil, lunchSoup: "かぼちゃのポタージュ", dinnerMain: "チキンソテー（トマト）", dinnerSide: "ひじきの煮物", dinnerSoup: nil),
                DayData(lunchMain: "カオマンガイ", lunchSide: nil, lunchSoup: nil, dinnerMain: "麻婆豆腐", dinnerSide: "トマトサラダ", dinnerSoup: nil),
                DayData(lunchMain: "チヂミ", lunchSide: nil, lunchSoup: "じゃがいものポタージュ", dinnerMain: "豚肉トマト煮込み", dinnerSide: "ほうれん草としらすのおひたし", dinnerSoup: nil)
            ]),
            ("Pattern B", [
                DayData(lunchMain: "ミートソースパスタ", lunchSide: nil, lunchSoup: nil, dinnerMain: "スコップコロッケ", dinnerSide: "なす味噌炒め", dinnerSoup: nil),
                DayData(lunchMain: "ささみユッケ丼", lunchSide: nil, lunchSoup: "にんじんのポタージュ", dinnerMain: "豚肉とトマト重ね蒸し", dinnerSide: "にんじんしりしり", dinnerSoup: nil),
                DayData(lunchMain: "ツナトマトパスタ", lunchSide: "外食・テイクアウト", lunchSoup: nil, dinnerMain: "簡単トマト煮込みハンバーグ", dinnerSide: "かぼちゃの煮物", dinnerSoup: nil),
                DayData(lunchMain: "お好み焼き", lunchSide: nil, lunchSoup: "コーンポタージュ", dinnerMain: "豚生姜焼き", dinnerSide: "トマトのマリネサラダ", dinnerSoup: nil)
            ]),
            ("Pattern C", [
                DayData(lunchMain: "親子丼", lunchSide: nil, lunchSoup: nil, dinnerMain: "野菜たっぷりカレーライス", dinnerSide: "エビサラダ", dinnerSoup: nil),
                DayData(lunchMain: "炒飯", lunchSide: nil, lunchSoup: "ミネストローネ", dinnerMain: "大葉とチーズのミルフィーユカツ", dinnerSide: "ブロッコリーとしらすのおかか和え", dinnerSoup: nil),
                DayData(lunchMain: "ガパオライス", lunchSide: nil, lunchSoup: nil, dinnerMain: "鶏の唐揚げ", dinnerSide: "カプレーゼ", dinnerSoup: nil),
                DayData(lunchMain: "リゾット", lunchSide: nil, lunchSoup: "豆腐とわかめの味噌汁", dinnerMain: "ユーリンチー", dinnerSide: "切り干し大根の煮物", dinnerSoup: nil)
            ]),
            ("Pattern D", [
                DayData(lunchMain: "ビビンバ", lunchSide: nil, lunchSoup: nil, dinnerMain: "肉じゃが", dinnerSide: "豆苗とツナの和風炒め", dinnerSoup: nil),
                DayData(lunchMain: "よだれどり", lunchSide: nil, lunchSoup: "トマトと卵のスープ", dinnerMain: "豆腐入り月見つくね", dinnerSide: "焼きびたし", dinnerSoup: nil),
                DayData(lunchMain: "マカロニグラタン", lunchSide: nil, lunchSoup: nil, dinnerMain: "たらのムニエル", dinnerSide: "アンチョビブロッコリー", dinnerSoup: nil),
                DayData(lunchMain: "外食・テイクアウト", lunchSide: nil, lunchSoup: "外食・テイクアウト", dinnerMain: "外食・テイクアウト", dinnerSide: "ほうれん草とにんじんのナムル", dinnerSoup: nil)
            ])
        ]

        // 1. Create and Cache Menus based on Patterns
        for pDef in patternDefinitions {
            for dayData in pDef.days {
                _ = getOrCreateMenu(name: dayData.lunchMain, category: .main)
                if let side = dayData.lunchSide { _ = getOrCreateMenu(name: side, category: .side) }
                if let soup = dayData.lunchSoup { _ = getOrCreateMenu(name: soup, category: .soup) }

                _ = getOrCreateMenu(name: dayData.dinnerMain, category: .main)
                if let side = dayData.dinnerSide { _ = getOrCreateMenu(name: side, category: .side) }
                if let soup = dayData.dinnerSoup { _ = getOrCreateMenu(name: soup, category: .soup) }
            }
        }

        // 2. Attach Ingredients to Cache-registered or New Menus
        for rawIng in rawIngredients {
            // Search existing cached menu or create default as .main if not cached yet
            let targetMenu: Menu
            if let existing = menuCache.values.first(where: { $0.name == rawIng.menuName }) {
                targetMenu = existing
            } else {
                targetMenu = getOrCreateMenu(name: rawIng.menuName, category: .main)
            }

            let ingredient = Ingredient(
                name: rawIng.name,
                quantity: rawIng.quantity,
                unit: rawIng.unit,
                category: .produce // Assign default category as needed
            )
            
            targetMenu.ingredients.append(ingredient)
        }

        // 3. Build KondatePatterns and PatternDays
        for (patternIndex, pDef) in patternDefinitions.enumerated() {
            let pattern = KondatePattern(name: pDef.name, durationDays: 4, isActive: (patternIndex == 0))
            context.insert(pattern)

            for (dayIndex, dayData) in pDef.days.enumerated() {
                var lunchMenus: [Menu] = [getOrCreateMenu(name: dayData.lunchMain, category: .main)]
                if let side = dayData.lunchSide {
                    lunchMenus.append(getOrCreateMenu(name: side, category: .side))
                }
                if let soup = dayData.lunchSoup {
                    lunchMenus.append(getOrCreateMenu(name: soup, category: .soup))
                }

                var dinnerMenus: [Menu] = [getOrCreateMenu(name: dayData.dinnerMain, category: .main)]
                if let side = dayData.dinnerSide {
                    dinnerMenus.append(getOrCreateMenu(name: side, category: .side))
                }
                if let soup = dayData.dinnerSoup {
                    dinnerMenus.append(getOrCreateMenu(name: soup, category: .soup))
                }

                let patternDay = PatternDay(
                    dayIndex: dayIndex,
                    breakfastMenus: [],
                    lunchMenus: lunchMenus,
                    dinnerMenus: dinnerMenus
                )
                patternDay.pattern = pattern
                context.insert(patternDay)
            }
        }
    }
}
