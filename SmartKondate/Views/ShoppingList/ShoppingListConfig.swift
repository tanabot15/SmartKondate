//
//  ShoppingListConfig.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/09/17.
//

import Foundation

enum ExtraSourceType: String, CaseIterable, Identifiable {
    case date = "Date"
    case pattern = "Pattern"
    case patternDay = "Pattern Day"
    case menu = "Menu"

    var id: String { rawValue }
}

enum ExtraSourceItem: Hashable, Identifiable {
    case date(Date)
    case pattern(KondatePattern)
    case patternDay(patternName: String, dayIndex: Int, day: PatternDay)
    case menu(Menu)

    var id: String {
        switch self {
        case .date(let date):
            return "date_\(date.timeIntervalSince1970)"
        case .pattern(let pattern):
            return "pattern_\(pattern.id.uuidString)"
        case .patternDay(let patternName, let dayIndex, _):
            return "day_\(patternName)_\(dayIndex)"
        case .menu(let menu):
            return "menu_\(menu.id.uuidString)"
        }
    }

    var displayTitle: String {
        switch self {
        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        case .pattern(let pattern):
            return "Pattern: \(pattern.name)"
        case .patternDay(let patternName, let dayIndex, _):
            return "\(patternName) - Day \(dayIndex + 1)"
        case .menu(let menu):
            return "Menu: \(menu.name)"
        }
    }

    var iconName: String {
        switch self {
        case .date: return "calendar"
        case .pattern: return "arrow.triangle.2.circlepath"
        case .patternDay: return "square.stack"
        case .menu: return "fork.knife"
        }
    }
}

struct ShoppingListConfig {
    var selectedPattern: KondatePattern?
    var selectedDayIndices: Set<Int> = []
    var extraSources: [ExtraSourceItem] = []
}
