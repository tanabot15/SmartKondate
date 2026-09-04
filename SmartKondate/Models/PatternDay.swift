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
    @Attribute(.unique) var id: UUID = UUID()
    var dayIndex: Int = 0
    
    var pattern: KondatePattern?
    
    var breakfastMenus: [Menu] = []
    var lunchMenus: [Menu] = []
    var dinnerMenus: [Menu] = []

    init(
        dayIndex: Int,
        breakfastMenus: [Menu] = [],
        lunchMenus: [Menu] = [],
        dinnerMenus: [Menu] = []
    ) {
        self.id = UUID()
        self.dayIndex = dayIndex
        self.breakfastMenus = breakfastMenus
        self.lunchMenus = lunchMenus
        self.dinnerMenus = dinnerMenus
    }
}
