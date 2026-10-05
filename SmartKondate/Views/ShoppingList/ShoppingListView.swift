//
//  ShoppingListView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

enum ShoppingCheckMode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case unbuyable = "Unbuyable"
    
    var id: String { rawValue }
}

struct ShoppingListView: View {
    let config: ShoppingListConfig

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \KondatePattern.createdAt, order: .reverse) private var allPatterns: [KondatePattern]
    @Query private var allStockItems: [StockItem]

    @State private var checkMode: ShoppingCheckMode = .standard
    @State private var checkedIngredientKeys: Set<String> = []
    @State private var customQuantities: [String: Double] = [:]
    @State private var showCopiedToast = false
    @State private var toastMessage = ""

    // MARK: - Save Dialog State
    @State private var showSaveAlert = false
    @State private var inputListTitle = ""

    private var activePattern: KondatePattern? {
        allPatterns.first { $0.queueOrder == 0 } ?? allPatterns.first { $0.isActive }
    }

    private var outOfStockItems: [StockItem] {
        allStockItems.filter { $0.isOut }
    }

    private var rawIngredientItems: [(ingredient: Ingredient, menuName: String, isModified: Bool, dayIndex: Int?)] {
        var result: [(Ingredient, String, Bool, Int?)] = []

        if let pattern = config.selectedPattern {
            for dayIndex in config.selectedDayIndices {
                guard let patternDay = pattern.days.first(where: { $0.dayIndex == dayIndex }) else { continue }
                let meals = [patternDay.breakfastMenus, patternDay.lunchMenus, patternDay.dinnerMenus]
                
                for menus in meals {
                    for menu in menus {
                        for ingredient in menu.ingredients {
                            result.append((ingredient, "Day \(dayIndex + 1): \(menu.name)", false, dayIndex))
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
                            result.append((ingredient, "[\(dateLabel)] \(menu.name)", res.isModified, nil))
                        }
                    }
                }

            case .pattern(let pattern):
                for day in pattern.days {
                    for menu in day.breakfastMenus + day.lunchMenus + day.dinnerMenus {
                        for ingredient in menu.ingredients {
                            result.append((ingredient, "[\(pattern.name) Day \(day.dayIndex + 1)] \(menu.name)", false, day.dayIndex))
                        }
                    }
                }

            case .patternDay(let name, let dayIndex, let day):
                for menu in day.breakfastMenus + day.lunchMenus + day.dinnerMenus {
                    for ingredient in menu.ingredients {
                        result.append((ingredient, "[\(name) Day \(dayIndex + 1)] \(menu.name)", false, dayIndex))
                    }
                }

            case .menu(let menu):
                for ingredient in menu.ingredients {
                    result.append((ingredient, "[Extra] \(menu.name)", false, nil))
                }
            }
        }

        return result
    }

    private var aggregatedItems: [ShoppingIngredientItem] {
        let stockedNames = Set(allStockItems.filter { !$0.isOut }.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() })
        var groupedDict: [String: (name: String, quantity: Double, unit: String, category: IngredientCategory, menus: Set<String>, isModified: Bool, dayIndex: Int?)] = [:]

        for item in rawIngredientItems {
            let name = item.ingredient.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            
            let unit = item.ingredient.unit.trimmingCharacters(in: .whitespaces)
            let groupKey = "\(name.lowercased())_\(unit.lowercased())_\(item.ingredient.category.rawValue)_\(item.isModified)"

            if var existing = groupedDict[groupKey] {
                existing.quantity += item.ingredient.quantity
                existing.menus.insert(item.menuName)
                if existing.dayIndex == nil {
                    existing.dayIndex = item.dayIndex
                }
                groupedDict[groupKey] = existing
            } else {
                groupedDict[groupKey] = (name, item.ingredient.quantity, unit, item.ingredient.category, [item.menuName], item.isModified, item.dayIndex)
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
                isModifiedMeal: value.isModified,
                dayIndex: value.dayIndex
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

    private var formattedTextForSharing: String {
            var text = "[Shopping List]\n"
            if let pattern = config.selectedPattern {
                text += "Target: \(pattern.name) (\(config.selectedDayIndices.count) days)\n"
            }
            text += "\n"

            if !outOfStockItems.isEmpty {
                text += "■ Stock Items (Refill Needed)\n"
                for category in StockCategory.allCases {
                    let itemsInCategory = outOfStockItems.filter { $0.category == category }
                    if !itemsInCategory.isEmpty {
                        text += " [\(category.rawValue)]\n"
                        for stock in itemsInCategory {
                            text += " - \(stock.name)\n"
                        }
                    }
                }
                text += "\n"
            }

            let validModifiedItems = modifiedItems.filter { $0.quantity > 0 }
            if !validModifiedItems.isEmpty {
                text += "■ Modified / Added Meal Ingredients\n"
                for item in validModifiedItems {
                    let qtyStr = formatQuantity(item.quantity)
                    let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                    text += "- \(item.ingredientName): \(qtyStr)\(unitStr)\n"
                }
                text += "\n"
            }

            let validStandardGroup = standardItemsByCategory.compactMap { group -> ShoppingCategoryGroup? in
                let filtered = group.items.filter { $0.quantity > 0 }
                guard !filtered.isEmpty else { return nil }
                return ShoppingCategoryGroup(category: group.category, items: filtered)
            }

            if !validStandardGroup.isEmpty {
                text += "■ Ingredients\n"
                for group in validStandardGroup {
                    text += " [\(group.category.rawValue)]\n"
                    for item in group.items {
                        let qtyStr = formatQuantity(item.quantity)
                        let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                        text += " - \(item.ingredientName): \(qtyStr)\(unitStr)\n"
                    }
                }
                text += "\n"
            }

            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

    private var uncheckedItemsFormattedText: String {
        var text = "[Pending Items List] \n"

        let uncheckedModified = modifiedItems.filter { !checkedIngredientKeys.contains($0.id) && $0.quantity > 0 }
        if !uncheckedModified.isEmpty {
            text += "■ Recipe Ingredients\n"
            for item in uncheckedModified {
                let qtyStr = formatQuantity(item.quantity)
                let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                text += "- \(item.ingredientName) \(qtyStr)\(unitStr)\n"
            }
            text += "\n"
        }

        for group in standardItemsByCategory {
            let uncheckedGroupItems = group.items.filter { !checkedIngredientKeys.contains($0.id) && $0.quantity > 0 }
            if !uncheckedGroupItems.isEmpty {
                text += "■ \(group.category.rawValue)\n"
                for item in uncheckedGroupItems {
                    let qtyStr = formatQuantity(item.quantity)
                    let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                    text += "- \(item.ingredientName) \(qtyStr)\(unitStr)\n"
                }
                text += "\n"
            }
        }

        let result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result == "[Pending Items List]" {
            return "[Pending Items List]\nAll items have been purchased."
        }
        return result
    }

    private var unbuyableItemsFormattedText: String {
        var text = "[Unbuyable Items]\n"
        let unbuyableItems = aggregatedItems.filter { checkedIngredientKeys.contains($0.id) && $0.quantity > 0 }
        
        if unbuyableItems.isEmpty {
            return "[Unbuyable Items]\nNo items marked as unbuyable."
        }

        for item in unbuyableItems {
            let qtyStr = formatQuantity(item.quantity)
            let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
            text += "- \(item.ingredientName) \(qtyStr)\(unitStr)\n"
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            List {
                modeSelectionSection
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
                toastView(message: toastMessage, icon: "checkmark.circle.fill", color: .green)
            }
        }
        .navigationTitle("Shopping List")
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                if !checkedIngredientKeys.isEmpty {
                    Button {
                        checkedIngredientKeys.removeAll()
                    } label: {
                        Image(systemName: "checkmark.circle.badge.xmark")
                        Text("Clear")
                    }
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    prepareAndShowSaveAlert()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }

                ShareLink(item: formattedTextForSharing) {
                    Image(systemName: "square.and.arrow.up")
                }

                Button {
                    if checkMode == .standard {
                        copyToClipboard(text: uncheckedItemsFormattedText, message: "Copied pending items")
                    } else {
                        copyToClipboard(text: unbuyableItemsFormattedText, message: "Copied unbuyable items")
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
        .alert("Save Shopping List", isPresented: $showSaveAlert) {
            TextField("List Title", text: $inputListTitle)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveCurrentShoppingList(with: inputListTitle)
            }
        } message: {
            Text("Please enter a title.")
        }
    }

    private func prepareAndShowSaveAlert() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateString = formatter.string(from: Date())
        
        let patternName = config.selectedPattern?.name ?? "Shopping List"
        let defaultTitle = "\(dateString) \(patternName)"
        
        inputListTitle = defaultTitle
        showSaveAlert = true
    }

    private func saveCurrentShoppingList(with title: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateString = formatter.string(from: Date())
        let fallbackTitle = "\(dateString)  \(config.selectedPattern?.name ?? "Shopping List")"

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? fallbackTitle : trimmedTitle
        
        do {
            // 既存のリストおよびアイテムを削除
            let existingLists = try modelContext.fetch(FetchDescriptor<SavedShoppingList>())
            for list in existingLists {
                modelContext.delete(list)
            }
            
            // 1. 新しいリスト（親）を作成してコンテキストに挿入
            let newList = SavedShoppingList(title: finalTitle, items: [])
            modelContext.insert(newList)

            // 2. レシピ由来のアイテムを生成＆挿入
            var allNewItems: [SavedIngredientItem] = []
            
            for item in aggregatedItems.filter({ $0.quantity > 0 }) {
                let savedItem = SavedIngredientItem(
                    name: item.ingredientName,
                    quantity: item.quantity,
                    unit: item.unit,
                    category: item.category,
                    stockCategory: nil,
                    isChecked: checkedIngredientKeys.contains(item.id),
                    isOutOfStock: false,
                    dayIndex: item.dayIndex,
                    menuDetails: item.menuDetails,
                    list: newList
                )
                modelContext.insert(savedItem)
                allNewItems.append(savedItem)
            }

            // 3. 在庫切れアイテムを生成＆挿入
            for stock in outOfStockItems {
                let savedItem = SavedIngredientItem(
                    name: stock.name,
                    quantity: 0.0,
                    unit: "",
                    category: .other,
                    stockCategory: stock.category,
                    isChecked: false,
                    isOutOfStock: true,
                    dayIndex: nil,
                    list: newList
                )
                modelContext.insert(savedItem)
                allNewItems.append(savedItem)
            }

            // 4. 明示的にリレーションをセットして保存
            newList.items = allNewItems
            try modelContext.save()

            toastMessage = "Shopping list saved"
            withAnimation { showCopiedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showCopiedToast = false }
            }
        } catch {
            print("Failed to save shopping list: \(error)")
        }
    }

    private func copyToClipboard(text: String, message: String) {
        UIPasteboard.general.string = text
        toastMessage = message
        withAnimation { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showCopiedToast = false }
        }
    }

    // MARK: - Subviews
    private var modeSelectionSection: some View {
        Section {
            VStack(spacing: 10) {
                Picker("Check Mode", selection: $checkMode) {
                    ForEach(ShoppingCheckMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    if checkMode == .standard {
                        Text("Check items as you buy them")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Check items that are unbuyable")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Spacer()
                    
                    Button(checkedIngredientKeys.isEmpty ? "Select All" : "Deselect All") {
                        if checkedIngredientKeys.isEmpty {
                            checkedIngredientKeys = Set(aggregatedItems.map { $0.id })
                        } else {
                            checkedIngredientKeys.removeAll()
                        }
                    }
                    .font(.caption)
                }
            }
            .padding(.vertical, 4)
        }
    }

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
            ForEach(StockCategory.allCases) { category in
                let itemsInCategory = outOfStockItems.filter { $0.category == category }
                if !itemsInCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(itemsInCategory) { stockItem in
                            Button {
                                stockItem.isOut = false
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "circle")
                                        .font(.title3)
                                        .foregroundStyle(Color.secondary)

                                    Text(stockItem.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)

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
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Image(systemName: "archivebox.fill")
                    .foregroundStyle(.orange)
                Text("Stock Items")
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
        Section {
            ForEach(standardItemsByCategory) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.category.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider()
                        }
                        ingredientRow(for: item, isModified: false)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Ingredients")
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.bold)
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
            isUnbuyableMode: checkMode == .unbuyable,
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
    let dayIndex: Int?
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
