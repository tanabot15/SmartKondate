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
    
    @Relationship(deleteRule: .cascade, inverse: \SavedIngredientItem.list)
    var items: [SavedIngredientItem]

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
    var stockCategoryRawValue: String?
    var isChecked: Bool
    var isOutOfStock: Bool
    var dayIndex: Int?
    
    var list: SavedShoppingList?

    var category: IngredientCategory {
        get { IngredientCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var stockCategory: StockCategory {
        get {
            guard let raw = stockCategoryRawValue else { return .pantry }
            return StockCategory(rawValue: raw) ?? .pantry
        }
        set { stockCategoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 0.0,
        unit: String = "",
        category: IngredientCategory = .other,
        categoryRawValue: String? = nil,
        stockCategory: StockCategory? = nil,
        isChecked: Bool = false,
        isOutOfStock: Bool = false,
        dayIndex: Int? = nil,
        list: SavedShoppingList? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.categoryRawValue = categoryRawValue ?? category.rawValue
        self.stockCategoryRawValue = stockCategory?.rawValue
        self.isChecked = isChecked
        self.isOutOfStock = isOutOfStock
        self.dayIndex = dayIndex
        self.list = list
    }
}
