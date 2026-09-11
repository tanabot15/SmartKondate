//
//  Menu.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

enum MenuCategory: String, Codable, CaseIterable, Identifiable {
    case main = "Main"
    case side = "Side"
    case soup = "Soup"
    case other = "Other"

    var id: String { rawValue }
}

@Model
final class Menu {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var category: MenuCategory = MenuCategory.main
    var source: String = ""
    var memo: String = ""
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.menu)
    var ingredients: [Ingredient] = []

    @Relationship(inverse: \PatternDay.breakfastMenus)
    var breakfastPatternDays: [PatternDay] = []
    
    @Relationship(inverse: \PatternDay.lunchMenus)
    var lunchPatternDays: [PatternDay] = []
    
    @Relationship(inverse: \PatternDay.dinnerMenus)
    var dinnerPatternDays: [PatternDay] = []

    init(name: String, category: MenuCategory = .main, source: String = "", memo: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.source = source
        self.memo = memo
        self.createdAt = Date()
        self.ingredients = []
    }
}
