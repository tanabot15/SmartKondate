//
//  ShoppingListView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

enum ShoppingMode: String, CaseIterable, Identifiable {
    case pattern = "Pattern"
    case date = "Date"
    
    var id: String { self.rawValue }
}

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \KondatePattern.createdAt, order: .reverse) private var allPatterns: [KondatePattern]
    @Query(filter: #Predicate<StockItem> { $0.isOut == true }) private var outOfStockItems: [StockItem]
    
    @State private var shoppingMode: ShoppingMode = .pattern
    @State private var targetDate: Date = Date()
    @State private var selectedPatternID: UUID?
    @State private var checkedIngredientKeys: Set<String> = []

    private var activePattern: KondatePattern? {
        allPatterns.first { $0.queueOrder == 0 } ?? allPatterns.first { $0.isActive }
    }

    private var selectedPattern: KondatePattern? {
        if let id = selectedPatternID {
            return allPatterns.first { $0.id == id }
        }
        return activePattern ?? allPatterns.first
    }

    private var rawIngredientItems: [(ingredient: Ingredient, menuName: String, isModified: Bool)] {
        var result: [(Ingredient, String, Bool)] = []

        switch shoppingMode {
        case .date:
            let diffResults = DiffCalculator.calculateDiff(
                for: targetDate,
                pattern: activePattern,
                startDate: activePattern?.startDate ?? activePattern?.createdAt ?? Date(),
                customBreakfast: nil,
                customLunch: nil,
                customDinner: nil
            )

            for res in diffResults {
                for menu in res.effectiveMenus {
                    for ingredient in menu.ingredients {
                        result.append((ingredient, menu.name, res.isModified))
                    }
                }
            }

        case .pattern:
            guard let pattern = selectedPattern else { break }

            for dayIndex in 0..<pattern.durationDays {
                guard let patternDay = pattern.days.first(where: { $0.dayIndex == dayIndex }) else { continue }

                let meals: [(MealType, [Menu])] = [
                    (.breakfast, patternDay.breakfastMenus),
                    (.lunch, patternDay.lunchMenus),
                    (.dinner, patternDay.dinnerMenus)
                ]

                for (_, menus) in meals {
                    for menu in menus {
                        for ingredient in menu.ingredients {
                            let label = "Day \(dayIndex + 1): \(menu.name)"
                            result.append((ingredient, label, false))
                        }
                    }
                }
            }
        }

        return result
    }

    // MARK: - 同じ材料・単位を足し合わせるグループ化プロパティ
    private var aggregatedItems: [ShoppingIngredientItem] {
        var groupedDict: [String: (name: String, quantity: Double, unit: String, menus: Set<String>, isModified: Bool)] = [:]

        for item in rawIngredientItems {
            let name = item.ingredient.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            
            let unit = item.ingredient.unit.trimmingCharacters(in: .whitespaces)
            let groupKey = "\(name.lowercased())_\(unit.lowercased())_\(item.isModified)"

            if var existing = groupedDict[groupKey] {
                existing.quantity += item.ingredient.quantity
                existing.menus.insert(item.menuName)
                groupedDict[groupKey] = existing
            } else {
                groupedDict[groupKey] = (
                    name: name,
                    quantity: item.ingredient.quantity,
                    unit: unit,
                    menus: [item.menuName],
                    isModified: item.isModified
                )
            }
        }

        return groupedDict.map { (key, value) in
            let tempIng = Ingredient(name: value.name, quantity: value.quantity, unit: value.unit)
            let sortedMenus = value.menus.sorted().joined(separator: ", ")

            return ShoppingIngredientItem(
                id: key,
                ingredientName: value.name,
                amountText: tempIng.amountText,
                menuDetails: sortedMenus,
                isModifiedMeal: value.isModified
            )
        }
        .sorted { $0.ingredientName < $1.ingredientName }
    }

    private var modifiedItems: [ShoppingIngredientItem] {
        aggregatedItems.filter { $0.isModifiedMeal }
    }

    private var standardItems: [ShoppingIngredientItem] {
        aggregatedItems.filter { !$0.isModifiedMeal }
    }

    var body: some View {
        List {
            // MARK: - Shopping Period Selector
            Section {
                Picker("Target Mode", selection: $shoppingMode) {
                    ForEach(ShoppingMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if shoppingMode == .date {
                    DatePicker("Target Date", selection: $targetDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                } else {
                    if allPatterns.isEmpty {
                        Text("No patterns available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Target Pattern", selection: $selectedPatternID) {
                            ForEach(allPatterns) { pattern in
                                HStack {
                                    Text(pattern.name)
                                    if pattern.queueOrder == 0 {
                                        Text("(Active)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(Optional(pattern.id))
                            }
                        }
                    }
                }
            } header: {
                Text("Shopping Period")
            }

            // MARK: - 1. Out of Stock Items
            if !outOfStockItems.isEmpty {
                Section {
                    ForEach(outOfStockItems) { stockItem in
                        Button {
                            toggleStockBought(stockItem)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundStyle(Color.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stockItem.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)

                                    Text(stockItem.category.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("Stock Out")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Out of Stock (Refill Needed)")
                            .foregroundStyle(.orange)
                            .fontWeight(.bold)
                    }
                }
            }

            // MARK: - 2. Aggregated Ingredients List
            if aggregatedItems.isEmpty && outOfStockItems.isEmpty {
                ContentUnavailableView {
                    Label("No Ingredients Needed", systemImage: "cart")
                } description: {
                    Text(shoppingMode == .date
                         ? "No menus set for this date, and no stock items marked as out."
                         : "No menus set for the selected pattern, and no stock items marked as out.")
                        .foregroundStyle(.secondary)
                }
            } else {
                if !modifiedItems.isEmpty {
                    Section {
                        ForEach(modifiedItems) { item in
                            DiffIngredientRow(
                                ingredientName: item.ingredientName,
                                amountText: item.amountText,
                                menuDetails: item.menuDetails,
                                isModifiedMeal: true,
                                isChecked: checkedIngredientKeys.contains(item.id),
                                onToggle: { toggleCheck(for: item.id) }
                            )
                        }
                    } header: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.accentColor)
                            Text("Modified / Added Meal Ingredients")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.bold)
                        }
                    }
                }

                if !standardItems.isEmpty {
                    Section(header: Text(shoppingMode == .date ? "Standard Meal Ingredients" : "Pattern Ingredients")) {
                        ForEach(standardItems) { item in
                            DiffIngredientRow(
                                ingredientName: item.ingredientName,
                                amountText: item.amountText,
                                menuDetails: item.menuDetails,
                                isModifiedMeal: false,
                                isChecked: checkedIngredientKeys.contains(item.id),
                                onToggle: { toggleCheck(for: item.id) }
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Shopping List")
        .onAppear {
            if selectedPatternID == nil {
                selectedPatternID = activePattern?.id ?? allPatterns.first?.id
            }
        }
        .toolbar {
            if !checkedIngredientKeys.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear Checks") {
                        checkedIngredientKeys.removeAll()
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private func toggleCheck(for key: String) {
        if checkedIngredientKeys.contains(key) {
            checkedIngredientKeys.remove(key)
        } else {
            checkedIngredientKeys.insert(key)
        }
    }

    private func toggleStockBought(_ item: StockItem) {
        item.isOut = false
    }
}

struct ShoppingIngredientItem: Identifiable {
    let id: String
    let ingredientName: String
    let amountText: String
    let menuDetails: String
    let isModifiedMeal: Bool
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self,
        configurations: config
    )
    let context = container.mainContext

    let pattern = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true, queueOrder: 0)
    context.insert(pattern)

    let ing1 = Ingredient(name: "Chicken Thigh", quantity: 300, unit: "g")
    let ing2 = Ingredient(name: "Onion", quantity: 2, unit: "pcs")
    let ing3 = Ingredient(name: "Egg", quantity: 4, unit: "pcs")
    
    // category を Enum 型 (MenuCategory) に変更
    let menu1 = Menu(name: "Chicken Teriyaki Bowl", category: .main)
    menu1.ingredients = [ing1, ing2]

    let menu2 = Menu(name: "Omelette", category: .main)
    menu2.ingredients = [ing3]

    let menus = [menu1, menu2]
    menus.forEach { context.insert($0) }

    let day1 = PatternDay(dayIndex: 0, breakfastMenus: [], lunchMenus: [menu1], dinnerMenus: [menu2])
    day1.pattern = pattern
    context.insert(day1)

    // category を Enum 型 (StockCategory) に変更
    let stock1 = StockItem(name: "Egg", category: .pantry, isOut: false)
    let stock2 = StockItem(name: "Soy Sauce", category: .seasoning, isOut: true)

    let stocks = [stock1, stock2]
    stocks.forEach { context.insert($0) }

    return NavigationStack {
        ShoppingListView()
    }
    .modelContainer(container)
}
