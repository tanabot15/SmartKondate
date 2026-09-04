//
//  DiffCalculator.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    
    var id: String { rawValue }
}

struct MealDiffResult {
    let mealType: MealType
    let defaultMenus: [Menu]
    let customMenus: [Menu]?
    
    // カスタム指定（個別変更）があるかどうか
    var isModified: Bool {
        customMenus != nil
    }
    
    // カスタム指定があればそれを返し、なければデフォルトのパターンメニューを返す
    var effectiveMenus: [Menu] {
        customMenus ?? defaultMenus
    }
}

struct DiffCalculator {
    static func calculateDayIndex(for targetDate: Date, startDate: Date, durationDays: Int) -> Int {
        guard durationDays > 0 else { return 0 }
        
        let calendar = Calendar.current
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let startOfBase = calendar.startOfDay(for: startDate)
        
        let components = calendar.dateComponents([.day], from: startOfBase, to: startOfTarget)
        let dayDifference = components.day ?? 0
        
        let remainder = dayDifference % durationDays
        return remainder >= 0 ? remainder : remainder + durationDays
    }
    
    static func calculateDiff(
        for targetDate: Date,
        pattern: KondatePattern?,
        startDate: Date,
        customBreakfast: [Menu]? = nil,
        customLunch: [Menu]? = nil,
        customDinner: [Menu]? = nil
    ) -> [MealDiffResult] {
        
        guard let pattern = pattern, pattern.durationDays > 0 else {
            return [
                MealDiffResult(mealType: .breakfast, defaultMenus: [], customMenus: customBreakfast),
                MealDiffResult(mealType: .lunch, defaultMenus: [], customMenus: customLunch),
                MealDiffResult(mealType: .dinner, defaultMenus: [], customMenus: customDinner)
            ]
        }
        
        let dayIndex = calculateDayIndex(for: targetDate, startDate: startDate, durationDays: pattern.durationDays)
        let patternDay = pattern.days.first(where: { $0.dayIndex == dayIndex })
        
        return [
            MealDiffResult(
                mealType: .breakfast,
                defaultMenus: patternDay?.breakfastMenus ?? [],
                customMenus: customBreakfast
            ),
            MealDiffResult(
                mealType: .lunch,
                defaultMenus: patternDay?.lunchMenus ?? [],
                customMenus: customLunch
            ),
            MealDiffResult(
                mealType: .dinner,
                defaultMenus: patternDay?.dinnerMenus ?? [],
                customMenus: customDinner
            )
        ]
    }
}
