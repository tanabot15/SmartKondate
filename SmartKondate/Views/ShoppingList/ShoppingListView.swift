//
//  ShoppingListView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    let config: ShoppingListConfig

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KondatePattern.createdAt, order: .reverse) private var allPatterns: [KondatePattern]
    @Query private var allStockItems: [StockItem]

    @State private var checkedIngredientKeys: Set<String> = []
    @State private var customQuantities: [String: Double] = [:]

    private var activePattern: KondatePattern? {
        allPatterns.first { $0.queueOrder == 0 } ?? allPatterns.first { $0.isActive }
    }

    private var outOfStockItems: [StockItem] {
        allStockItems.filter { $0.isOut }
    }

    // MARK: - Combined Ingredient Extraction Logic
    private var rawIngredientItems: [(ingredient: Ingredient, menuName: String, isModified: Bool)] {
        var result: [(Ingredient, String, Bool)] = []

        // 1. Base Pattern Extraction
        if let pattern = config.selectedPattern {
            for dayIndex in 0..<pattern.durationDays {
                guard config.selectedDayIndices.contains(dayIndex) else { continue }
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

        // 2. Extra Sources Extraction
        for source in config.extraSources {
            switch source {
            case .date(let date):
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M/d"
                let dateLabel = dateFormatter.string(from: date)

                let diffResults = DiffCalculator.calculateDiff(
                    for: date,
                    pattern: activePattern,
                    startDate: activePattern?.startDate ?? activePattern?.createdAt ?? Date(),
                    customBreakfast: nil,
                    customLunch: nil,
                    customDinner: nil
                )

                for res in diffResults {
                    for menu in res.effectiveMenus {
                        for ingredient in menu.ingredients {
                            let label = "[\(dateLabel)] \(menu.name)"
                            result.append((ingredient, label, res.isModified))
                        }
                    }
                }

            case .pattern(let pattern):
                for patternDay in pattern.days {
                    let allMenus = patternDay.breakfastMenus + patternDay.lunchMenus + patternDay.dinnerMenus
                    for menu in allMenus {
                        for ingredient in menu.ingredients {
                            let label = "[\(pattern.name) Day \(patternDay.dayIndex + 1)] \(menu.name)"
                            result.append((ingredient, label, false))
                        }
                    }
                }

            case .patternDay(let patternName, let dayIndex, let patternDay):
                let allMenus = patternDay.breakfastMenus + patternDay.lunchMenus + patternDay.dinnerMenus
                for menu in allMenus {
                    for ingredient in menu.ingredients {
                        let label = "[\(patternName) Day \(dayIndex + 1)] \(menu.name)"
                        result.append((ingredient, label, false))
                    }
                }

            case .menu(let menu):
                for ingredient in menu.ingredients {
                    let label = "[Extra] \(menu.name)"
                    result.append((ingredient, label, false))
                }
            }
        }

        return result
    }

    private var aggregatedItems: [ShoppingIngredientItem] {
        let stockedNames = Set(allStockItems.filter { !$0.isOut }.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() })
        var groupedDict: [String: (name: String, quantity: Double, unit: String, category: IngredientCategory, menus: Set<String>, isModified: Bool)] = [:]

        for item in rawIngredientItems {
            let name = item.ingredient.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            
            let unit = item.ingredient.unit.trimmingCharacters(in: .whitespaces)
            let groupKey = "\(name.lowercased())_\(unit.lowercased())_\(item.ingredient.category.rawValue)_\(item.isModified)"

            if var existing = groupedDict[groupKey] {
                existing.quantity += item.ingredient.quantity
                existing.menus.insert(item.menuName)
                groupedDict[groupKey] = existing
            } else {
                groupedDict[groupKey] = (
                    name: name,
                    quantity: item.ingredient.quantity,
                    unit: unit,
                    category: item.ingredient.category,
                    menus: [item.menuName],
                    isModified: item.isModified
                )
            }
        }

        return groupedDict.compactMap { (key, value) in
            let sortedMenus = value.menus.sorted().joined(separator: ", ")

            var initialQuantity = value.quantity
            if stockedNames.contains(value.name.lowercased()) {
                initialQuantity = max(0, initialQuantity - 1)
            }

            let finalQuantity = customQuantities[key] ?? initialQuantity

            return ShoppingIngredientItem(
                id: key,
                ingredientName: value.name,
                quantity: finalQuantity,
                unit: value.unit,
                category: value.category,
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

    private var standardItemsByCategory: [(category: IngredientCategory, items: [ShoppingIngredientItem])] {
        let grouped = Dictionary(grouping: standardItems, by: { $0.category })
        return IngredientCategory.allCases.compactMap { category in
            if let items = grouped[category], !items.isEmpty {
                return (category: category, items: items)
            }
            return nil
        }
    }

    var body: some View {
        List {
            // MARK: - Selected Conditions Summary
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    if let pattern = config.selectedPattern {
                        Label("\(pattern.name) (\(config.selectedDayIndices.count) days)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !config.extraSources.isEmpty {
                        Label("\(config.extraSources.count) extra additions included", systemImage: "plus.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Target Target Criteria")
            }

            // MARK: - Out of Stock Items
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

            // MARK: - Aggregated Ingredients List
            if aggregatedItems.isEmpty && outOfStockItems.isEmpty {
                ContentUnavailableView {
                    Label("No Ingredients Needed", systemImage: "cart")
                } description: {
                    Text("No ingredients match the selected setup.")
                        .foregroundStyle(.secondary)
                }
            } else {
                if !modifiedItems.isEmpty {
                    Section {
                        ForEach(modifiedItems) { item in
                            DiffIngredientRow(
                                ingredientName: item.ingredientName,
                                quantity: item.quantity,
                                unit: item.unit,
                                menuDetails: item.menuDetails,
                                isModifiedMeal: true,
                                isChecked: checkedIngredientKeys.contains(item.id),
                                onToggle: { toggleCheck(for: item.id) },
                                onQuantityChange: { newQty in
                                    customQuantities[item.id] = newQty
                                }
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

                ForEach(standardItemsByCategory, id: \.category) { section in
                    Section(header: Text(section.category.rawValue)) {
                        ForEach(section.items) { item in
                            DiffIngredientRow(
                                ingredientName: item.ingredientName,
                                quantity: item.quantity,
                                unit: item.unit,
                                menuDetails: item.menuDetails,
                                isModifiedMeal: false,
                                isChecked: checkedIngredientKeys.contains(item.id),
                                onToggle: { toggleCheck(for: item.id) },
                                onQuantityChange: { newQty in
                                    customQuantities[item.id] = newQty
                                }
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Shopping List")
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
    let quantity: Double
    let unit: String
    let category: IngredientCategory
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

    // Create Pattern & Days
    let pattern = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true, queueOrder: 0)
    context.insert(pattern)

    let ing1 = Ingredient(name: "Chicken Thigh", quantity: 300, unit: "g", category: .meatAndFish)
    let ing2 = Ingredient(name: "Onion", quantity: 2, unit: "pcs", category: .produce)
    let ing3 = Ingredient(name: "Egg", quantity: 4, unit: "pcs", category: .chilledAndDairy)
    let ing4 = Ingredient(name: "Soy Sauce", quantity: 2, unit: "tbsp", category: .pantryAndGrain)
    
    let menu1 = Menu(name: "Chicken Teriyaki Bowl", category: .main)
    menu1.ingredients = [ing1, ing2, ing4]

    let menu2 = Menu(name: "Omelette", category: .main)
    menu2.ingredients = [ing3]

    [menu1, menu2].forEach { context.insert($0) }

    let day1 = PatternDay(dayIndex: 0, breakfastMenus: [], lunchMenus: [menu1], dinnerMenus: [menu2])
    day1.pattern = pattern
    context.insert(day1)

    // Stock Item
    let stock1 = StockItem(name: "Black Pepper", category: .seasoning, isOut: true)
    context.insert(stock1)

    // ShoppingListConfig setup
    let shoppingConfig = ShoppingListConfig(
        selectedPattern: pattern,
        selectedDayIndices: [0],
        extraSources: [.menu(menu1)]
    )

    return NavigationStack {
        ShoppingListView(config: shoppingConfig)
    }
    .modelContainer(container)
}
