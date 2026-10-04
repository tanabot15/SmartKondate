//
//  SavedShoppingList.swift
//  SmartKondate
//

import Foundation
import SwiftData

@Model
final class SavedShoppingList {
    var id: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var items: [SavedIngredientItem]

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), items: [SavedIngredientItem] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
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
    var isChecked: Bool
    var dayIndex: Int?

    var category: IngredientCategory {
        get { IngredientCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        category: IngredientCategory,
        isChecked: Bool = false,
        dayIndex: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.categoryRawValue = category.rawValue
        self.isChecked = isChecked
        self.dayIndex = dayIndex
    }
}
