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

        // 21 distinct menus for 7 days x 3 meals
        // Breakfast
        let b1 = Menu(name: "Overnight Oats", category: .main)
        let b2 = Menu(name: "Scrambled Eggs & Toast", category: .main)
        let b3 = Menu(name: "Berry Smoothie", category: .main)
        let b4 = Menu(name: "Pancakes with Maple Syrup", category: .main)
        let b5 = Menu(name: "Avocado Toast with Poached Egg", category: .main)
        let b6 = Menu(name: "Greek Yogurt Parfait", category: .main)
        let b7 = Menu(name: "Full English Breakfast Plate", category: .main)

        // Lunch
        let l1 = Menu(name: "Chicken Caesar Wrap", category: .main)
        let l2 = Menu(name: "Turkey & Avocado Sandwich", category: .main)
        let l3 = Menu(name: "Quinoa Salad Bowl", category: .main)
        let l4 = Menu(name: "Grilled Cheese & Tomato Soup", category: .main)
        let l5 = Menu(name: "BLT Sandwich", category: .main)
        let l6 = Menu(name: "Cobb Salad", category: .main)
        let l7 = Menu(name: "Tuna Melt Sandwich", category: .main)

        // Dinner
        let d1 = Menu(name: "Sheet Pan Salmon & Veggies", category: .main)
        let d2 = Menu(name: "Classic Spaghetti Bolognese", category: .main)
        let d3 = Menu(name: "Beef Tacos", category: .main)
        let d4 = Menu(name: "Grilled Chicken & Sweet Potatoes", category: .main)
        let d5 = Menu(name: "Homemade Pepperoni Pizza", category: .main)
        let d6 = Menu(name: "Shepherd's Pie", category: .main)
        let d7 = Menu(name: "Roast Beef Dinner", category: .main)

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

        // 21 distinct quick menus for 7 days x 3 meals
        let b1 = Menu(name: "Quick Granola & Yogurt", category: .main)
        let b2 = Menu(name: "Tuna Toast", category: .main)
        let b3 = Menu(name: "Scrambled Eggs & Sausage", category: .main)
        let b4 = Menu(name: "Instant Miso & Rice", category: .main)
        let b5 = Menu(name: "Cheese Toast", category: .main)
        let b6 = Menu(name: "Banana Smoothie & Toast", category: .main)
        let b7 = Menu(name: "Fried Egg on Toast", category: .main)

        let l1 = Menu(name: "Pasta Carbonara", category: .main)
        let l2 = Menu(name: "Quick Fried Rice", category: .main)
        let l3 = Menu(name: "Tomato Pasta", category: .main)
        let l4 = Menu(name: "Frozen Gyoza Set", category: .main)
        let l5 = Menu(name: "Tuna Tomato Spaghetti", category: .main)
        let l6 = Menu(name: "Egg & Rice Bowl", category: .main)
        let l7 = Menu(name: "Instant Ramen with Veggies", category: .main)

        let d1 = Menu(name: "Japanese Curry Rice", category: .main)
        let d2 = Menu(name: "Quick Stir-fried Pork", category: .main)
        let d3 = Menu(name: "Consommé Vegetable Stew", category: .main)
        let d4 = Menu(name: "One-Pan Bolognese Pasta", category: .main)
        let d5 = Menu(name: "Quick Chicken Rice", category: .main)
        let d6 = Menu(name: "Easy Pork & Cabbage Fry", category: .main)
        let d7 = Menu(name: "Quick Hayashi Rice", category: .main)

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

        // Menu
        let b1 = Menu(name: "卵かけご飯セット", category: .main)
        let b2 = Menu(name: "納豆トースト＆バナナ", category: .main)
        let b3 = Menu(name: "鮭の塩焼き定食", category: .main)
        let b4 = Menu(name: "和風だし巻き卵定食", category: .main)
        let b5 = Menu(name: "具だくさん味噌汁＆おにぎり", category: .main)
        let b6 = Menu(name: "バタートースト＆ヨーグルト", category: .main)
        let b7 = Menu(name: "やさしいたまご雑炊", category: .main)

        let l1 = Menu(name: "鶏の照り焼き丼", category: .main)
        let l2 = Menu(name: "きつねうどん", category: .main)
        let l3 = Menu(name: "豚の生姜焼き定食", category: .main)
        let l4 = Menu(name: "おうちカレーライス", category: .main)
        let l5 = Menu(name: "昔ながらのオムライス", category: .main)
        let l6 = Menu(name: "天ぷらそば", category: .main)
        let l7 = Menu(name: "カツ丼", category: .main)

        let d1 = Menu(name: "サクサクとんかつ", category: .main)
        let d2 = Menu(name: "ほっこり肉じゃが", category: .main)
        let d3 = Menu(name: "本格麻婆豆腐", category: .main)
        let d4 = Menu(name: "鯖の塩焼き", category: .main)
        let d5 = Menu(name: "チキン南蛮", category: .main)
        let d6 = Menu(name: "すき焼き風煮込み", category: .main)
        let d7 = Menu(name: "旬の天ぷら盛り合わせ", category: .main)

        let allMenus = [
            b1, b2, b3, b4, b5, b6, b7,
            l1, l2, l3, l4, l5, l6, l7,
            d1, d2, d3, d4, d5, d6, d7
        ]
        allMenus.forEach { context.insert($0) }

        let pattern = KondatePattern(name: "Japanese Home", durationDays: 7, isActive: true)
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
}
