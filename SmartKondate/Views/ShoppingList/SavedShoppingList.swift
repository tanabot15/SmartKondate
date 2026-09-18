//
//  SavedShoppingList.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/09/18.
//

import Foundation
import SwiftData

@Model
final class SavedShoppingList {
    var id: UUID
    var createdAt: Date
    var title: String
    
    @Relationship(deleteRule: .cascade, inverse: \SavedIngredientItem.shoppingList)
    var items: [SavedIngredientItem] = []

    init(id: UUID = UUID(), createdAt: Date = Date(), title: String, items: [SavedIngredientItem] = []) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.items = items
    }
}

@Model
final class SavedIngredientItem {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var categoryRawValue: String
    var menuDetails: String
    var isChecked: Bool
    var isModifiedMeal: Bool
    
    var shoppingList: SavedShoppingList?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        categoryRawValue: String,
        menuDetails: String,
        isChecked: Bool = false,
        isModifiedMeal: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.categoryRawValue = categoryRawValue
        self.menuDetails = menuDetails
        self.isChecked = isChecked
        self.isModifiedMeal = isModifiedMeal
    }
}
