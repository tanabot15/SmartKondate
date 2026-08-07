//
//  PatternDay.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import SwiftData

@Model
final class PatternDay {
    var id: UUID = UUID()
    var dayIndex: Int = 0 // 0-based: 0 = Day 1, 1 = Day 2...
    
    // 親パターンへの参照（親側の inverse と対になる設定）
    @Relationship(deleteRule: .nullify)
    var pattern: KondatePattern?
    
    // 各食のメニュー（オプショナル参照）
    var breakfastMenu: Menu?
    var lunchMenu: Menu?
    var dinnerMenu: Menu?

    init(dayIndex: Int, breakfastMenu: Menu? = nil, lunchMenu: Menu? = nil, dinnerMenu: Menu? = nil) {
        self.id = UUID()
        self.dayIndex = dayIndex
        self.breakfastMenu = breakfastMenu
        self.lunchMenu = lunchMenu
        self.dinnerMenu = dinnerMenu
    }
}
