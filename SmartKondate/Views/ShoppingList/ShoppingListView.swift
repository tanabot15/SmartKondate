//
//  ShoppingListView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    let config: ShoppingListConfig

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \KondatePattern.createdAt, order: .reverse) private var allPatterns: [KondatePattern]
    @Query private var allStockItems: [StockItem]

    @State private var checkedIngredientKeys: Set<String> = []
    @State private var customQuantities: [String: Double] = [:]
    @State private var showCopiedToast = false
    @State private var showSavedToast = false

    private var activePattern: KondatePattern? {
        allPatterns.first { $0.queueOrder == 0 } ?? allPatterns.first { $0.isActive }
    }

    private var outOfStockItems: [StockItem] {
        allStockItems.filter { $0.isOut }
    }

    // Extract raw ingredients based on configuration
    private var rawIngredientItems: [(ingredient: Ingredient, menuName: String, isModified: Bool)] {
        var result: [(Ingredient, String, Bool)] = []

        if let pattern = config.selectedPattern {
            for dayIndex in config.selectedDayIndices {
                guard let patternDay = pattern.days.first(where: { $0.dayIndex == dayIndex }) else { continue }
                let meals = [patternDay.breakfastMenus, patternDay.lunchMenus, patternDay.dinnerMenus]
                
                for menus in meals {
                    for menu in menus {
                        for ingredient in menu.ingredients {
                            result.append((ingredient, "Day \(dayIndex + 1): \(menu.name)", false))
                        }
                    }
                }
            }
        }

        for source in config.extraSources {
            switch source {
            case .date(let date):
                let dateLabel = date.formatted(.dateTime.month().day())
                let diffResults = DiffCalculator.calculateDiff(
                    for: date,
                    pattern: activePattern,
                    startDate: activePattern?.startDate ?? activePattern?.createdAt ?? Date(),
                    customBreakfast: nil, customLunch: nil, customDinner: nil
                )
                for res in diffResults {
                    for menu in res.effectiveMenus {
                        for ingredient in menu.ingredients {
                            result.append((ingredient, "[\(dateLabel)] \(menu.name)", res.isModified))
                        }
                    }
                }

            case .pattern(let pattern):
                for day in pattern.days {
                    for menu in day.breakfastMenus + day.lunchMenus + day.dinnerMenus {
                        for ingredient in menu.ingredients {
                            result.append((ingredient, "[\(pattern.name) Day \(day.dayIndex + 1)] \(menu.name)", false))
                        }
                    }
                }

            case .patternDay(let name, let dayIndex, let day):
                for menu in day.breakfastMenus + day.lunchMenus + day.dinnerMenus {
                    for ingredient in menu.ingredients {
                        result.append((ingredient, "[\(name) Day \(dayIndex + 1)] \(menu.name)", false))
                    }
                }

            case .menu(let menu):
                for ingredient in menu.ingredients {
                    result.append((ingredient, "[Extra] \(menu.name)", false))
                }
            }
        }

        return result
    }

    // Aggregate ingredients by name and unit
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
                groupedDict[groupKey] = (name, item.ingredient.quantity, unit, item.ingredient.category, [item.menuName], item.isModified)
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

    private var modifiedItems: [ShoppingIngredientItem] { aggregatedItems.filter { $0.isModifiedMeal } }
    private var standardItems: [ShoppingIngredientItem] { aggregatedItems.filter { !$0.isModifiedMeal } }

    private var standardItemsByCategory: [ShoppingCategoryGroup] {
        let grouped = Dictionary(grouping: standardItems, by: { $0.category })
        return IngredientCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return ShoppingCategoryGroup(category: category, items: items)
        }
    }

    // Export text generation
    private var formattedTextForSharing: String {
        var text = "【買い物リスト】\n"
        if let pattern = config.selectedPattern {
            text += "対象: \(pattern.name) (\(config.selectedDayIndices.count)日分)\n"
        }
        text += "\n"

        if !outOfStockItems.isEmpty {
            text += "■ 不足中の在庫 (要補充)\n"
            for stock in outOfStockItems { text += "・\(stock.name)\n" }
            text += "\n"
        }

        if !modifiedItems.isEmpty {
            text += "■ 変更・追加メニュー分\n"
            for item in modifiedItems {
                let qtyStr = formatQuantity(item.quantity)
                let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                text += "・\(item.ingredientName): \(qtyStr)\(unitStr)\n"
            }
            text += "\n"
        }

        for group in standardItemsByCategory {
            text += "■ \(group.category.rawValue)\n"
            for item in group.items {
                let qtyStr = formatQuantity(item.quantity)
                let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                text += "・\(item.ingredientName): \(qtyStr)\(unitStr)\n"
            }
            text += "\n"
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            List {
                summarySection
                
                if !outOfStockItems.isEmpty {
                    outOfStockSection
                }

                if aggregatedItems.isEmpty && outOfStockItems.isEmpty {
                    emptyStateSection
                } else {
                    if !modifiedItems.isEmpty {
                        modifiedItemsSection
                    }
                    standardItemsSections
                }
            }
            .listStyle(.insetGrouped)

            if showCopiedToast {
                toastView(message: "Copied to clipboard", icon: "checkmark.circle.fill", color: .green)
            } else if showSavedToast {
                toastView(message: "Saved to Shopping Lists", icon: "square.and.arrow.down.fill", color: .blue)
            }
        }
        .navigationTitle("Shopping List")
        .toolbar {
            if !checkedIngredientKeys.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { checkedIngredientKeys.removeAll() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: saveShoppingList) {
                    Image(systemName: "square.and.arrow.down")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: formattedTextForSharing) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: copyToClipboard) {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = formattedTextForSharing
        withAnimation { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showCopiedToast = false }
        }
    }

    private func saveShoppingList() {
        let titleName = config.selectedPattern?.name ?? "Shopping List"
        let title = "\(titleName) (\(Date().formatted(date: .numeric, time: .omitted)))"
        let savedList = SavedShoppingList(title: title)
        modelContext.insert(savedList)
        
        for item in aggregatedItems {
            let savedItem = SavedIngredientItem(
                name: item.ingredientName,
                quantity: item.quantity,
                unit: item.unit,
                categoryRawValue: item.category.rawValue,
                menuDetails: item.menuDetails,
                isChecked: checkedIngredientKeys.contains(item.id),
                isModifiedMeal: item.isModifiedMeal
            )
            modelContext.insert(savedItem)
            savedItem.shoppingList = savedList
        }
        
        do {
            try modelContext.save()
            print(" Successfully saved shopping list to SwiftData.")
            
            withAnimation { showSavedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showSavedToast = false }
            }
        } catch {
            print(" Failed to save shopping list: \(error)")
        }
    }

    // MARK: - Subviews
    private var summarySection: some View {
        Section(header: Text("Target Criteria")) {
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
        }
    }

    private var outOfStockSection: some View {
        Section {
            ForEach(outOfStockItems) { stockItem in
                Button {
                    stockItem.isOut = false
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

    private var emptyStateSection: some View {
        ContentUnavailableView {
            Label("No Ingredients Needed", systemImage: "cart")
        } description: {
            Text("No ingredients match the selected setup.")
                .foregroundStyle(.secondary)
        }
    }

    private var modifiedItemsSection: some View {
        Section {
            ForEach(modifiedItems) { item in
                ingredientRow(for: item, isModified: true)
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

    private var standardItemsSections: some View {
        ForEach(standardItemsByCategory) { group in
            Section(header: Text(group.category.rawValue)) {
                ForEach(group.items) { item in
                    ingredientRow(for: item, isModified: false)
                }
            }
        }
    }

    private func ingredientRow(for item: ShoppingIngredientItem, isModified: Bool) -> some View {
        DiffIngredientRow(
            ingredientName: item.ingredientName,
            quantity: item.quantity,
            unit: item.unit,
            menuDetails: item.menuDetails,
            isModifiedMeal: isModified,
            isChecked: checkedIngredientKeys.contains(item.id),
            onToggle: {
                if checkedIngredientKeys.contains(item.id) {
                    checkedIngredientKeys.remove(item.id)
                } else {
                    checkedIngredientKeys.insert(item.id)
                }
            },
            onQuantityChange: { newQty in customQuantities[item.id] = newQty }
        )
    }

    private func toastView(message: String, icon: String, color: Color) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(color)
                Text(message).font(.subheadline).fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func formatQuantity(_ val: Double) -> String {
        val.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", val) : String(format: "%.1f", val)
    }
}

// MARK: - Helper Models
struct ShoppingCategoryGroup: Identifiable {
    var id: String { category.rawValue }
    let category: IngredientCategory
    let items: [ShoppingIngredientItem]
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
