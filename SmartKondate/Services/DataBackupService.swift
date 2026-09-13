//
//  DataBackupService.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/09/13.
//

import Foundation
import SwiftData

@MainActor
enum DataBackupService {
    
    // MARK: - Export Data to JSON Data
    static func exportJSON(context: ModelContext) throws -> Data {
        let patternDescriptor = FetchDescriptor<KondatePattern>()
        let menuDescriptor = FetchDescriptor<Menu>()
        let stockDescriptor = FetchDescriptor<StockItem>()
        
        let patterns = (try? context.fetch(patternDescriptor)) ?? []
        let menus = (try? context.fetch(menuDescriptor)) ?? []
        let stockItems = (try? context.fetch(stockDescriptor)) ?? []

        let menuDTOs = menus.map { menu in
            MenuDTO(
                id: menu.id,
                name: menu.name,
                category: menu.category,
                source: menu.source,
                memo: menu.memo,
                createdAt: menu.createdAt,
                ingredients: menu.ingredients.map { ing in
                    IngredientDTO(
                        id: ing.id,
                        name: ing.name,
                        quantity: ing.quantity,
                        unit: ing.unit,
                        category: ing.category
                    )
                }
            )
        }

        let patternDTOs = patterns.map { pattern in
            KondatePatternDTO(
                id: pattern.id,
                name: pattern.name,
                durationDays: pattern.durationDays,
                isActive: pattern.isActive,
                queueOrder: pattern.queueOrder,
                startDate: pattern.startDate,
                createdAt: pattern.createdAt,
                days: pattern.days.map { day in
                    PatternDayDTO(
                        id: day.id,
                        dayIndex: day.dayIndex,
                        breakfastMenuIDs: day.breakfastMenus.map { $0.id },
                        lunchMenuIDs: day.lunchMenus.map { $0.id },
                        dinnerMenuIDs: day.dinnerMenus.map { $0.id }
                    )
                }
            )
        }

        let stockDTOs = stockItems.map { stock in
            StockItemDTO(
                id: stock.id,
                name: stock.name,
                category: stock.category,
                isOut: stock.isOut,
                memo: stock.memo
            )
        }

        let backupData = KondateBackupData(
            version: 1.0,
            exportedAt: Date(),
            patterns: patternDTOs,
            menus: menuDTOs,
            stockItems: stockDTOs
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(backupData)
    }

    // MARK: - Import Data from JSON Data
    static func importJSON(data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(KondateBackupData.self, from: data)

        // 1. delete current data
        try context.delete(model: KondatePattern.self)
        try context.delete(model: PatternDay.self)
        try context.delete(model: Menu.self)
        try context.delete(model: Ingredient.self)
        try context.delete(model: StockItem.self)

        // 2. Menu and Ingredient
        var menuMap: [UUID: Menu] = [:]
        for menuDTO in backup.menus {
            let menu = Menu(
                name: menuDTO.name,
                category: menuDTO.category,
                source: menuDTO.source,
                memo: menuDTO.memo
            )
            menu.id = menuDTO.id
            menu.createdAt = menuDTO.createdAt

            let ingredients = menuDTO.ingredients.map { ingDTO -> Ingredient in
                let ing = Ingredient(
                    name: ingDTO.name,
                    quantity: ingDTO.quantity,
                    unit: ingDTO.unit,
                    category: ingDTO.category
                )
                ing.id = ingDTO.id
                ing.menu = menu
                return ing
            }
            menu.ingredients = ingredients
            context.insert(menu)
            menuMap[menu.id] = menu
        }

        // 3. KondatePattern and PatternDay
        for patternDTO in backup.patterns {
            let pattern = KondatePattern(
                name: patternDTO.name,
                durationDays: patternDTO.durationDays,
                isActive: patternDTO.isActive,
                queueOrder: patternDTO.queueOrder,
                startDate: patternDTO.startDate
            )
            pattern.id = patternDTO.id
            pattern.createdAt = patternDTO.createdAt

            let patternDays = patternDTO.days.map { dayDTO -> PatternDay in
                let day = PatternDay(dayIndex: dayDTO.dayIndex)
                day.id = dayDTO.id
                day.pattern = pattern
                day.breakfastMenus = dayDTO.breakfastMenuIDs.compactMap { menuMap[$0] }
                day.lunchMenus = dayDTO.lunchMenuIDs.compactMap { menuMap[$0] }
                day.dinnerMenus = dayDTO.dinnerMenuIDs.compactMap { menuMap[$0] }
                return day
            }
            pattern.days = patternDays
            context.insert(pattern)
        }

        // 4. StockItem
        for stockDTO in backup.stockItems {
            let stock = StockItem(
                name: stockDTO.name,
                category: stockDTO.category,
                isOut: stockDTO.isOut,
                memo: stockDTO.memo
            )
            stock.id = stockDTO.id
            context.insert(stock)
        }

        try context.save()
    }
}
