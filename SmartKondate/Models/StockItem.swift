//
//  StockItem.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

@Model
final class StockItem {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var category: String = "Pantry"
    var isOut: Bool = false
    var memo: String = ""
    
    init(name: String, category: String = "Pantry", isOut: Bool = false, memo: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isOut = isOut
        self.memo = memo
    }
}
