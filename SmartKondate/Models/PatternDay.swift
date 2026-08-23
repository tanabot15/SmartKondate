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
    var dayIndex: Int = 0
    
    var pattern: KondatePattern?
    
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
