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
    var dayIndex: Int = 0 // 0-based: 0 = Day 1 (or Sunday/Monday), 1 = Day 2...
    
    // 親パターンへの参照
    @Relationship(deleteRule: .nullify)
    var pattern: KondatePattern?
    
    // 各食のメニュー（メニュー自体が削除されてもパターン日は残すため nullify）
    @Relationship(deleteRule: .nullify)
    var breakfastMenu: Menu?
    
    @Relationship(deleteRule: .nullify)
    var lunchMenu: Menu?
    
    @Relationship(deleteRule: .nullify)
    var dinnerMenu: Menu?

    init(dayIndex: Int, breakfastMenu: Menu? = nil, lunchMenu: Menu? = nil, dinnerMenu: Menu? = nil) {
        self.id = UUID()
        self.dayIndex = dayIndex
        self.breakfastMenu = breakfastMenu
        self.lunchMenu = lunchMenu
        self.dinnerMenu = dinnerMenu
    }
}
