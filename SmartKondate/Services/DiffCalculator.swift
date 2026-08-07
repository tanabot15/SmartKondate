//
//  DiffCalculator.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation

/// 食事の区分（朝食・昼食・夕食）
enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    
    var id: String { rawValue }
}

/// パターン標準とユーザー個別指定の比較結果
struct MealDiffResult {
    let mealType: MealType
    let defaultMenu: Menu?
    let customMenu: Menu?
    
    /// ユーザーによって個別変更（上書きまたはクリア）されているか
    var isModified: Bool {
        defaultMenu?.id != customMenu?.id
    }
    
    /// 最終的に採用されるメニュー
    var effectiveMenu: Menu? {
        customMenu ?? defaultMenu
    }
}

struct DiffCalculator {
    
    /// 日付とサイクル開始日に基づいて、パターン内の何日目（0-based index）に該当するかを計算
    /// - Parameters:
    ///   - targetDate: 判定対象の日付
    ///   - startDate: パターンの運用開始日
    ///   - durationDays: パターンのサイクル日数（例: 7日）
    /// - Returns: パターン内の dayIndex (0 ..< durationDays)
    static func calculateDayIndex(for targetDate: Date, startDate: Date, durationDays: Int) -> Int {
        guard durationDays > 0 else { return 0 }
        
        let calendar = Calendar.current
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let startOfBase = calendar.startOfDay(for: startDate)
        
        let components = calendar.dateComponents([.day], from: startOfBase, to: startOfTarget)
        let dayDifference = components.day ?? 0
        
        // マイナス日付にも対応する剰余計算
        let remainder = dayDifference % durationDays
        return remainder >= 0 ? remainder : remainder + durationDays
    }
    
    /// 特定の日（targetDate）における「パターンデフォルト」と「個別カスタマイズ」の差分一覧を算出
    /// - Parameters:
    ///   - targetDate: 対象日付
    ///   - pattern: 適用中の献立パターン
    ///   - startDate: パターンの運用開始日
    ///   - customBreakfast: ユーザーが個別に上書き指定した朝食メニュー（未指定なら nil）
    ///   - customLunch: ユーザーが個別に上書き指定した昼食メニュー（未指定なら nil）
    ///   - customDinner: ユーザーが個別に上書き指定した夕食メニュー（未指定なら nil）
    /// - Returns: MealTypeごとの差分判定結果の配列
    static func calculateDiff(
        for targetDate: Date,
        pattern: KondatePattern?,
        startDate: Date,
        customBreakfast: Menu? = nil,
        customLunch: Menu? = nil,
        customDinner: Menu? = nil
    ) -> [MealDiffResult] {
        
        guard let pattern = pattern, pattern.durationDays > 0 else {
            return [
                MealDiffResult(mealType: .breakfast, defaultMenu: nil, customMenu: customBreakfast),
                MealDiffResult(mealType: .lunch, defaultMenu: nil, customMenu: customLunch),
                MealDiffResult(mealType: .dinner, defaultMenu: nil, customMenu: customDinner)
            ]
        }
        
        let dayIndex = calculateDayIndex(for: targetDate, startDate: startDate, durationDays: pattern.durationDays)
        let patternDay = pattern.days.first(where: { $0.dayIndex == dayIndex })
        
        return [
            MealDiffResult(
                mealType: .breakfast,
                defaultMenu: patternDay?.breakfastMenu,
                customMenu: customBreakfast
            ),
            MealDiffResult(
                mealType: .lunch,
                defaultMenu: patternDay?.lunchMenu,
                customMenu: customLunch
            ),
            MealDiffResult(
                mealType: .dinner,
                defaultMenu: patternDay?.dinnerMenu,
                customMenu: customDinner
            )
        ]
    }
}
