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
    var id: UUID = UUID()
    var name: String = ""
    var category: String = "Main" // ex: "Main", "Side", "Soup"
    var memo: String = ""
    var createdAt: Date = Date()
    
    // メニュー削除時、紐づく食材データも連動して削除
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.menu)
    var ingredients: [Ingredient] = []

    init(name: String, category: String = "Main", memo: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.memo = memo
        self.createdAt = Date()
    }
}
