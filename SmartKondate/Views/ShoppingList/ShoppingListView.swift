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

    // 選択されたモード（Date / Pattern）に応じて食材リストを構築
    private var ingredientItems: [ShoppingIngredientItem] {
        var items: [ShoppingIngredientItem] = []

        switch shoppingMode {
        case .date:
            // 1日分の集計（DashboardViewと同様にDiffCalculatorを利用）
            let diffResults = DiffCalculator.calculateDiff(
                for: targetDate,
                pattern: activePattern,
                startDate: activePattern?.startDate ?? activePattern?.createdAt ?? Date(),
                customBreakfast: nil,
                customLunch: nil,
                customDinner: nil
            )

            for result in diffResults {
                for menu in result.effectiveMenus {
                    for ingredient in menu.ingredients {
                        let key = "date_\(result.mealType.rawValue)_\(menu.id.uuidString)_\(ingredient.id.uuidString)"
                        items.append(
                            ShoppingIngredientItem(
                                id: key,
                                ingredientName: ingredient.name,
                                amount: ingredient.amount,
                                menuName: menu.name,
                                mealType: result.mealType,
                                isModifiedMeal: result.isModified
                            )
                        )
                    }
                }
            }

        case .pattern:
            // パターン全体の全日数分を集計
            guard let pattern = selectedPattern else { break }

            for dayIndex in 0..<pattern.durationDays {
                guard let patternDay = pattern.days.first(where: { $0.dayIndex == dayIndex }) else { continue }

                let meals: [(MealType, [Menu])] = [
                    (.breakfast, patternDay.breakfastMenus),
                    (.lunch, patternDay.lunchMenus),
                    (.dinner, patternDay.dinnerMenus)
                ]

                for (mealType, menus) in meals {
                    for menu in menus {
                        for ingredient in menu.ingredients {
                            let key = "pattern_\(pattern.id.uuidString)_day\(dayIndex)_\(mealType.rawValue)_\(menu.id.uuidString)_\(ingredient.id.uuidString)"
                            items.append(
                                ShoppingIngredientItem(
                                    id: key,
                                    ingredientName: ingredient.name,
                                    amount: ingredient.amount,
                                    menuName: "Day \(dayIndex + 1): \(menu.name)",
                                    mealType: mealType,
                                    isModifiedMeal: false
                                )
                            )
                        }
                    }
                }
            }
        }

        return items
    }

    private var modifiedItems: [ShoppingIngredientItem] {
        ingredientItems.filter { $0.isModifiedMeal }
    }

    private var standardItems: [ShoppingIngredientItem] {
        ingredientItems.filter { !$0.isModifiedMeal }
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

                                    Text(stockItem.category)
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

            // MARK: - 2. Ingredients List
            if ingredientItems.isEmpty && outOfStockItems.isEmpty {
                ContentUnavailableView {
                    Label("No Ingredients Needed", systemImage: "cart")
                } description: {
                    Text(shoppingMode == .date
                         ? "No menus set for this date, and no stock items marked as out."
                         : "No menus set for the selected pattern, and no stock items marked as out.")
                        .foregroundStyle(.secondary)
                }
            } else {
                // 変更・追加メニューの食材（Date モードのみ該当）
                if !modifiedItems.isEmpty {
                    Section {
                        ForEach(modifiedItems) { item in
                            DiffIngredientRow(
                                ingredientName: item.ingredientName,
                                amount: item.amount,
                                menuName: item.menuName,
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

                // 通常の予定食材
                if !standardItems.isEmpty {
                    Section(header: Text(shoppingMode == .date ? "Standard Meal Ingredients" : "Pattern Ingredients")) {
                        ForEach(standardItems) { item in
                            DiffIngredientRow(
                                ingredientName: item.ingredientName,
                                amount: item.amount,
                                menuName: item.menuName,
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

// 注文表の表示用内部構造体
struct ShoppingIngredientItem: Identifiable {
    let id: String
    let ingredientName: String
    let amount: String
    let menuName: String
    let mealType: MealType
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

    let ing1 = Ingredient(name: "Chicken Thigh", amount: "300g")
    let ing2 = Ingredient(name: "Onion", amount: "2 pcs")
    let ing3 = Ingredient(name: "Egg", amount: "4 pcs")
    
    let menu1 = Menu(name: "Chicken Teriyaki Bowl", category: "Main")
    menu1.ingredients = [ing1, ing2]

    let menu2 = Menu(name: "Omelette", category: "Main")
    menu2.ingredients = [ing3]

    let menus = [menu1, menu2]
    menus.forEach { context.insert($0) }

    let day1 = PatternDay(dayIndex: 0, breakfastMenus: [], lunchMenus: [menu1], dinnerMenus: [menu2])
    day1.pattern = pattern
    context.insert(day1)

    let stock1 = StockItem(name: "Egg", category: "Pantry", isOut: false)
    let stock2 = StockItem(name: "Soy Sauce", category: "Seasoning", isOut: true)

    let stocks = [stock1, stock2]
    stocks.forEach { context.insert($0) }

    return NavigationStack {
        ShoppingListView()
    }
    .modelContainer(container)
}
