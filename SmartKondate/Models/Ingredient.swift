//
//  Ingredient.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID = UUID()
    var name: String = ""
    var amount: String = "" // 例: "200g", "1 tbsp", "2 pcs"
    
    // 親となるメニューへの参照（削除時はNull化）
    @Relationship(deleteRule: .nullify)
    var menu: Menu?

    init(name: String, amount: String = "") {
        self.id = UUID()
        self.name = name
        self.amount = amount
    }
}
