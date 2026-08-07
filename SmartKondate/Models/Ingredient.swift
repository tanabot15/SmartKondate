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
    var amount: String = ""
    
    // 親 Menu への参照（@Relationship アノテーションは削除）
    var menu: Menu?

    init(name: String, amount: String = "") {
        self.id = UUID()
        self.name = name
        self.amount = amount
    }
}
