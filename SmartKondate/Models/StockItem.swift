//
//  StockItem.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

enum StockCategory: String, Codable, CaseIterable, Identifiable {
    case pantry = "Pantry"
    case seasoning = "Seasoning"
    case household = "Household"
    case other = "Other"

    var id: String { rawValue }
}

@Model
final class StockItem {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var category: StockCategory = StockCategory.pantry
    var isOut: Bool = false
    var memo: String = ""
    
    init(name: String, category: StockCategory = .pantry, isOut: Bool = false, memo: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isOut = isOut
        self.memo = memo
    }
}
