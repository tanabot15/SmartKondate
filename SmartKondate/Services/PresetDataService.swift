//
//  PresetDataService.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

struct PresetDataService {
    
    /// 初回起動時のプリセットデータ（メニュー、調味料/在庫、パターン）を一括生成して保存
    static func insertPresetDataIfNeeded(context: ModelContext) {
        // 既にデータが存在する場合はスキップ
        let descriptor = FetchDescriptor<KondatePattern>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return
        }
        
        // 1. プリセット調味料・常備品の作成
        let seasonings = [
            StockItem(name: "Soy Sauce", category: "Seasoning"),
            StockItem(name: "Miso", category: "Seasoning"),
            StockItem(name: "Mirin", category: "Seasoning"),
            StockItem(name: "Cooking Sake", category: "Seasoning"),
            StockItem(name: "Olive Oil", category: "Seasoning"),
            StockItem(name: "Salt & Pepper", category: "Seasoning")
        ]
        seasonings.forEach { context.insert($0) }
        
        // 2. プリセットメニューと食材の作成
        let menu1 = Menu(name: "Grilled Salmon & Miso Soup", category: "Main")
        let ing1_1 = Ingredient(name: "Salmon Fillet", amount: "2 pcs")
        let ing1_2 = Ingredient(name: "Tofu", amount: "1/2 block")
        menu1.ingredients = [ing1_1, ing1_2]
        
        let menu2 = Menu(name: "Pork Ginger", category: "Main")
        let ing2_1 = Ingredient(name: "Pork Slice", amount: "200g")
        let ing2_2 = Ingredient(name: "Onion", amount: "1/2 pc")
        menu2.ingredients = [ing2_1, ing2_2]
        
        let menu3 = Menu(name: "Japanese Curry", category: "Main")
        let ing3_1 = Ingredient(name: "Curry Roux", amount: "1/2 box")
        let ing3_2 = Ingredient(name: "Potato", amount: "2 pcs")
        let ing3_3 = Ingredient(name: "Carrot", amount: "1 pc")
        menu3.ingredients = [ing3_1, ing3_2, ing3_3]
        
        let menu4 = Menu(name: "Toast & Eggs", category: "Breakfast")
        let ing4_1 = Ingredient(name: "Bread", amount: "2 slices")
        let ing4_2 = Ingredient(name: "Egg", amount: "2 pcs")
        menu4.ingredients = [ing4_1, ing4_2]
        
        [menu1, menu2, menu3, menu4].forEach { context.insert($0) }
        
        // 3. プリセット献立パターンの作成（7日間サイクル）
        let standardPattern = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
        context.insert(standardPattern)
        
        let day0 = PatternDay(dayIndex: 0, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu1)
        let day1 = PatternDay(dayIndex: 1, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu2)
        let day2 = PatternDay(dayIndex: 2, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu3)
        let day3 = PatternDay(dayIndex: 3, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu1)
        let day4 = PatternDay(dayIndex: 4, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu2)
        let day5 = PatternDay(dayIndex: 5, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu3)
        let day6 = PatternDay(dayIndex: 6, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu1)
        
        [day0, day1, day2, day3, day4, day5, day6].forEach { day in
            day.pattern = standardPattern
            context.insert(day)
        }
        
        // 4. ショートサイクルパターン（3日間サイクル）
        let shortPattern = KondatePattern(name: "3-Day Quick Rotation", durationDays: 3, isActive: false)
        context.insert(shortPattern)
        
        let sDay0 = PatternDay(dayIndex: 0, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu1)
        let sDay1 = PatternDay(dayIndex: 1, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu2)
        let sDay2 = PatternDay(dayIndex: 2, breakfastMenu: menu4, lunchMenu: nil, dinnerMenu: menu3)
        
        [sDay0, sDay1, sDay2].forEach { day in
            day.pattern = shortPattern
            context.insert(day)
        }
        
        try? context.save()
    }
}
