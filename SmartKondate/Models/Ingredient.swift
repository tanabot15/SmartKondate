//
//  Ingredient.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

// MARK: - Ingredient Category Enum
enum IngredientCategory: String, Codable, CaseIterable, Identifiable {
    case produce = "Produce"
    case meatAndFish = "Meat & Fish"
    case chilledAndDairy = "Chilled & Dairy"
    case pantryAndGrain = "Pantry & Grain"
    case other = "Other"

    var id: String { rawValue }
}

// MARK: - Ingredient Model
@Model
final class Ingredient {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var quantity: Double = 0.0
    var unit: String = ""
    var category: IngredientCategory = IngredientCategory.other
    
    var menu: Menu?

    var amountText: String {
        guard quantity > 0 else { return "" }
        let formattedQuantity = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity)
            : String(format: "%.1f", quantity)
        return "\(formattedQuantity)\(unit)"
    }

    init(
        name: String,
        quantity: Double = 0.0,
        unit: String = "",
        category: IngredientCategory = .other
    ) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
    }
}
