//
//  SavedShoppingView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

struct SavedShoppingView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \SavedShoppingList.createdAt, order: .reverse) private var savedLists: [SavedShoppingList]

    @State private var selectedCategories: Set<IngredientCategory> = Set(IngredientCategory.allCases)
    @State private var selectedDayIndices: Set<Int> = []
    @State private var isFilterExpanded: Bool = false

    @State private var showCopiedToast = false
    @State private var toastMessage = ""

    private var currentList: SavedShoppingList? {
        savedLists.first
    }

    private var navigationTitleText: String {
        currentList?.title ?? "Saved List"
    }

    private var allItemsInList: [SavedIngredientItem] {
        currentList?.items ?? []
    }

    private var availableDayIndices: [Int] {
        let indices = allItemsInList.compactMap { $0.dayIndex }
        return Array(Set(indices)).sorted()
    }

    private var filteredItems: [SavedIngredientItem] {
        allItemsInList.filter { item in
            let matchesDay: Bool
            if selectedDayIndices.isEmpty {
                matchesDay = true
            } else if let dayIndex = item.dayIndex {
                matchesDay = selectedDayIndices.contains(dayIndex)
            } else {
                matchesDay = true
            }

            let matchesCategory = item.isOutOfStock ? true : selectedCategories.contains(item.category)
            return matchesDay && matchesCategory
        }
    }

    private var stockItems: [SavedIngredientItem] {
        filteredItems.filter { $0.isOutOfStock }
    }

    private var recipeItems: [SavedIngredientItem] {
        filteredItems.filter { !$0.isOutOfStock }
    }

    private var groupedRecipeItems: [IngredientCategory: [SavedIngredientItem]] {
        Dictionary(grouping: recipeItems, by: { $0.category })
    }

    // MARK: - Formatted Text for Sharing & Copying
    private var formattedTextForSharing: String {
        var text = "[\(navigationTitleText)]\n\n"

        // MARK: - Stock Items (カテゴリー別)
        if !stockItems.isEmpty {
            text += "■ Stock Items (Refill Needed)\n"
            for category in StockCategory.allCases {
                let categoryStockItems = stockItems.filter { $0.stockCategory == category }
                if !categoryStockItems.isEmpty {
                    text += "[\(category.rawValue)]\n"
                    for item in categoryStockItems {
                        text += "- \(item.name)\n"
                    }
                    text += "\n"
                }
            }
        }

        // MARK: - Ingredients (カテゴリー別)
        let validRecipeItems = recipeItems.filter { $0.quantity > 0 }
        if !validRecipeItems.isEmpty {
            let validGrouped = Dictionary(grouping: validRecipeItems, by: { $0.category })
            text += "■ Ingredients\n"
            for category in IngredientCategory.allCases {
                if let items = validGrouped[category], !items.isEmpty {
                    text += "[\(category.rawValue)]\n"
                    for item in items {
                        let qtyStr = formatQuantity(item.quantity)
                        let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                        text += "- \(item.name) \(qtyStr)\(unitStr)\n"
                    }
                    text += "\n"
                }
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var uncheckedItemsFormattedText: String {
        var text = "[Pending Items List]\n\n"
        let uncheckedRecipeItems = recipeItems.filter { !$0.isChecked && $0.quantity > 0 }

        if uncheckedRecipeItems.isEmpty && stockItems.filter({ !$0.isChecked }).isEmpty {
            return "[Pending Items List]\nAll items have been purchased."
        }

        for category in IngredientCategory.allCases {
            let items = uncheckedRecipeItems.filter { $0.category == category }
            if !items.isEmpty {
                text += "■ \(category.rawValue)\n"
                for item in items {
                    let qtyStr = formatQuantity(item.quantity)
                    let unitStr = item.unit.isEmpty ? "" : " \(item.unit)"
                    text += "- \(item.name) \(qtyStr)\(unitStr)\n"
                }
                text += "\n"
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Group {
                if savedLists.isEmpty {
                    ContentUnavailableView {
                        Label("No Saved List", systemImage: "cart")
                    } description: {
                        Text("You can save a shopping list using the save button on the Shopping List screen.")
                    }
                } else {
                    List {
                        // MARK: - Filter Section
                        Section {
                            DisclosureGroup(isExpanded: $isFilterExpanded) {
                                VStack(alignment: .leading, spacing: 14) {
                                    if !availableDayIndices.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text("Day Filter")
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                Spacer()
                                                if !selectedDayIndices.isEmpty {
                                                    Button("Reset") {
                                                        selectedDayIndices.removeAll()
                                                    }
                                                    .font(.caption)
                                                }
                                            }

                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(availableDayIndices, id: \.self) { dayIndex in
                                                        let isSelected = selectedDayIndices.contains(dayIndex)
                                                        Button {
                                                            if isSelected {
                                                                selectedDayIndices.remove(dayIndex)
                                                            } else {
                                                                selectedDayIndices.insert(dayIndex)
                                                            }
                                                        } label: {
                                                            Text("Day \(dayIndex + 1)")
                                                                .font(.caption)
                                                                .padding(.horizontal, 12)
                                                                .padding(.vertical, 6)
                                                                .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
                                                                .foregroundStyle(isSelected ? .white : .primary)
                                                                .clipShape(Capsule())
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                }
                                            }
                                        }

                                        Divider()
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Category")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            Spacer()
                                            Button(selectedCategories.count == IngredientCategory.allCases.count ? "Deselect All" : "Select All") {
                                                if selectedCategories.count == IngredientCategory.allCases.count {
                                                    selectedCategories.removeAll()
                                                } else {
                                                    selectedCategories = Set(IngredientCategory.allCases)
                                                }
                                            }
                                            .font(.caption)
                                        }

                                        FlowLayout(spacing: 6) {
                                            ForEach(IngredientCategory.allCases, id: \.self) { category in
                                                let isSelected = selectedCategories.contains(category)
                                                Button {
                                                    if isSelected {
                                                        selectedCategories.remove(category)
                                                    } else {
                                                        selectedCategories.insert(category)
                                                    }
                                                } label: {
                                                    Text(category.rawValue)
                                                        .font(.caption)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 5)
                                                        .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemFill))
                                                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                                                        )
                                                        .clipShape(Capsule())
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            } label: {
                                HStack {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .foregroundStyle(Color.accentColor)
                                    Text("Filter Items")
                                        .fontWeight(.medium)
                                    Spacer()
                                    if !selectedDayIndices.isEmpty || selectedCategories.count != IngredientCategory.allCases.count {
                                        Text("Active Filters")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // MARK: - Items List
                        if filteredItems.isEmpty {
                            ContentUnavailableView {
                                Label("No Matching Items", systemImage: "magnifyingglass")
                            } description: {
                                Text("Try adjusting your filters to show saved items.")
                            }
                        } else {
                            // MARK: Stock Items Section
                            if !stockItems.isEmpty {
                                Section {
                                    ForEach(StockCategory.allCases) { category in
                                        let categoryStockItems = stockItems.filter { $0.stockCategory == category }
                                        if !categoryStockItems.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(category.rawValue)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.secondary)

                                                ForEach(categoryStockItems) { item in
                                                    savedItemRow(item)
                                                }
                                            }
                                            .padding(.vertical, 2)
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

                            // MARK: Ingredients Section
                            if !recipeItems.isEmpty {
                                Section {
                                    ForEach(IngredientCategory.allCases, id: \.self) { category in
                                        if selectedCategories.contains(category), let items = groupedRecipeItems[category], !items.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(category.rawValue)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.secondary)

                                                ForEach(items) { item in
                                                    savedItemRow(item)
                                                }
                                            }
                                            .padding(.vertical, 2)
                                        }
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
                        }
                    }
                }
            }

            if showCopiedToast {
                toastView(message: toastMessage, icon: "checkmark.circle.fill", color: .green)
            }
        }
        .navigationTitle(navigationTitleText)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: formattedTextForSharing) {
                    Image(systemName: "square.and.arrow.up")
                }

                Button {
                    copyToClipboard(text: formattedTextForSharing, message: "Copied shopping list")
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
    }

    @ViewBuilder
    private func savedItemRow(_ item: SavedIngredientItem) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    item.isChecked.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(item.isChecked ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)

                    // MARK: - 料理名称・Day情報の表示
                    if let menuDetails = item.menuDetails, !menuDetails.isEmpty {
                        Text(menuDetails)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if let dayIndex = item.dayIndex {
                        Text("Day \(dayIndex + 1)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 16)

                if item.isOutOfStock {
                    Text("Refill Needed")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                } else if item.quantity > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(formatQuantity(item.quantity))
                            .font(.callout)
                            .fontWeight(.semibold)
                            .fontDesign(.monospaced)
                        Text(item.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                }
            }
            .padding(.vertical, 8)

            Divider()
                .padding(.leading, 32)
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

// MARK: - FlowLayout Helper for Chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
        height = y + maxHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}

// MARK: - Preview
#Preview {
    @MainActor
    func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: SavedShoppingList.self, SavedIngredientItem.self,
            configurations: config
        )

        let context = container.mainContext

        let sampleList = SavedShoppingList(
            title: "Latest Saved List",
            createdAt: Date()
        )
        context.insert(sampleList)

        let sampleItem1 = SavedIngredientItem(name: "Onion", quantity: 2, unit: "pcs", category: .produce, dayIndex: 0)
        let sampleItem2 = SavedIngredientItem(name: "Pork Belly", quantity: 300, unit: "g", category: .meatAndFish, isChecked: true, dayIndex: 1)
        let sampleItem3 = SavedIngredientItem(name: "Soy Sauce", quantity: 0, unit: "", category: .other, stockCategory: .seasoning, isChecked: false, isOutOfStock: true)
        
        [sampleItem1, sampleItem2, sampleItem3].forEach { context.insert($0) }
        sampleList.items = [sampleItem1, sampleItem2, sampleItem3]

        return container
    }

    return NavigationStack {
        SavedShoppingView()
    }
    .modelContainer(makeContainer())
}
