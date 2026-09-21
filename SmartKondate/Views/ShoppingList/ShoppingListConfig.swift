//
//  ShoppingListConfig.swift
//  SmartKondate
//

import Foundation

// Additional source options for shopping list generation
enum ExtraSourceType: String, CaseIterable, Identifiable {
    case date = "Date"
    case pattern = "Pattern"
    case patternDay = "Day"
    case menu = "Menu"

    var id: String { rawValue }
}

// Representing an added extra menu or pattern item
enum ExtraSourceItem: Hashable, Identifiable {
    case date(Date)
    case pattern(KondatePattern)
    case patternDay(patternName: String, dayIndex: Int, day: PatternDay)
    case menu(Menu)

    var id: String {
        switch self {
        case .date(let date): return "date_\(date.timeIntervalSince1970)"
        case .pattern(let pattern): return "pattern_\(pattern.id.uuidString)"
        case .patternDay(let name, let index, _): return "day_\(name)_\(index)"
        case .menu(let menu): return "menu_\(menu.id.uuidString)"
        }
    }

    var displayTitle: String {
        switch self {
        case .date(let date):
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        case .pattern(let pattern):
            return "Pattern: \(pattern.name)"
        case .patternDay(let name, let index, _):
            return "\(name) - Day \(index + 1)"
        case .menu(let menu):
            return "Menu: \(menu.name)"
        }
    }
}

// Configuration passed into ShoppingListView
struct ShoppingListConfig {
    var selectedPattern: KondatePattern?
    var selectedDayIndices: Set<Int> = []
    var extraSources: [ExtraSourceItem] = []
}
