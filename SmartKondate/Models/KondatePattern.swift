//
//  KondatePattern.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

@Model
final class KondatePattern {
    var id: UUID = UUID()
    var name: String = ""
    var durationDays: Int = 7
    var isActive: Bool = false
    var createdAt: Date = Date()
    
    // パターン削除時、紐づく PatternDay 群も一括削除
    @Relationship(deleteRule: .cascade, inverse: \PatternDay.pattern)
    var days: [PatternDay] = []

    init(name: String, durationDays: Int = 7, isActive: Bool = false) {
        self.id = UUID()
        self.name = name
        self.durationDays = durationDays
        self.isActive = isActive
        self.createdAt = Date()
    }
}
