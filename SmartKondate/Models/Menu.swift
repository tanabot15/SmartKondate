//
//  Menu.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

@Model
final class Menu {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var category: String = "Main"
    var memo: String = ""
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.menu)
    var ingredients: [Ingredient] = []

    @Relationship(inverse: \PatternDay.breakfastMenu)
    var breakfastPatternDays: [PatternDay] = []
    
    @Relationship(inverse: \PatternDay.lunchMenu)
    var lunchPatternDays: [PatternDay] = []
    
    @Relationship(inverse: \PatternDay.dinnerMenu)
    var dinnerPatternDays: [PatternDay] = []

    init(name: String, category: String = "Main", memo: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.memo = memo
        self.createdAt = Date()
        self.ingredients = []
    }
}
