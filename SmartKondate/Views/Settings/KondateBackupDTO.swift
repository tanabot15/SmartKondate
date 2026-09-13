//
//  KondateBackupDTO.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/09/13.
//

import Foundation

// MARK: - Root Backup Payload
struct KondateBackupData: Codable {
    let version: Double
    let exportedAt: Date
    let patterns: [KondatePatternDTO]
    let menus: [MenuDTO]
    let stockItems: [StockItemDTO]
}

// MARK: - Kondate Pattern DTO
struct KondatePatternDTO: Codable {
    let id: UUID
    let name: String
    let durationDays: Int
    let isActive: Bool
    let queueOrder: Int?
    let startDate: Date?
    let createdAt: Date
    let days: [PatternDayDTO]
}

// MARK: - Pattern Day DTO
struct PatternDayDTO: Codable {
    let id: UUID
    let dayIndex: Int
    let breakfastMenuIDs: [UUID]
    let lunchMenuIDs: [UUID]
    let dinnerMenuIDs: [UUID]
}

// MARK: - Menu DTO
struct MenuDTO: Codable {
    let id: UUID
    let name: String
    let category: MenuCategory
    let source: String
    let memo: String
    let createdAt: Date
    let ingredients: [IngredientDTO]
}

// MARK: - Ingredient DTO
struct IngredientDTO: Codable {
    let id: UUID
    let name: String
    let quantity: Double
    let unit: String
    let category: IngredientCategory
}

// MARK: - Stock Item DTO
struct StockItemDTO: Codable {
    let id: UUID
    let name: String
    let category: StockCategory
    let isOut: Bool
    let memo: String
}
