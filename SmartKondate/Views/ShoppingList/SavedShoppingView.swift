//
//  SavedShoppingView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

struct SavedShoppingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedShoppingList.createdAt, order: .reverse) private var savedLists: [SavedShoppingList]

    // MARK: - Filter States
    @State private var selectedCategories: Set<IngredientCategory> = Set(IngredientCategory.allCases)
    @State private var selectedDayIndices: Set<Int> = []
    @State private var isFilterExpanded: Bool = false

    // 表示用のタイトル（保存リストのタイトル、無ければデフォルト名）
    private var navigationTitleText: String {
        savedLists.first?.title ?? "Saved List"
    }

    // 保存されているアイテムに含まれる全 dayIndex のリスト（昇順）
    private var availableDayIndices: [Int] {
        let allItems = savedLists.flatMap { $0.items }
        let indices = allItems.compactMap { $0.dayIndex }
        return Array(Set(indices)).sorted()
    }

    // dayIndex フィルターおよび Category フィルターに合致するアイテム群
    private var filteredItems: [SavedIngredientItem] {
        let allItems = savedLists.flatMap { $0.items }
        
        return allItems.filter { item in
            // 1. Day Index Filter (選択が空の場合は全件表示)
            let matchesDay: Bool
            if selectedDayIndices.isEmpty {
                matchesDay = true
            } else if let dayIndex = item.dayIndex {
                matchesDay = selectedDayIndices.contains(dayIndex)
            } else {
                // dayIndex が nil のアイテム（全体追加分など）は常に含める仕様
                matchesDay = true
            }

            // 2. Category Filter
            let matchesCategory = selectedCategories.contains(item.category)

            return matchesDay && matchesCategory
        }
    }

    private var groupedItems: [IngredientCategory: [SavedIngredientItem]] {
        Dictionary(grouping: filteredItems, by: { $0.category })
    }

    var body: some View {
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
                                // 1. Day Filter (Multi-selection)
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

                                // 2. Category Filter (Multi-selection)
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
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            if selectedCategories.contains(category), let items = groupedItems[category], !items.isEmpty {
                                Section(header: Text(category.rawValue)) {
                                    ForEach(items) { item in
                                        HStack {
                                            Button {
                                                item.isChecked.toggle()
                                            } label: {
                                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                                    .foregroundStyle(item.isChecked ? Color.accentColor : Color.secondary)
                                            }
                                            .buttonStyle(.plain)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .strikethrough(item.isChecked)
                                                    .foregroundStyle(item.isChecked ? .secondary : .primary)

                                                if let dayIndex = item.dayIndex {
                                                    Text("Day \(dayIndex + 1)")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }

                                            Spacer()

                                            Text("\(formatQuantity(item.quantity)) \(item.unit)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(navigationTitleText)
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

    [sampleItem1, sampleItem2].forEach { context.insert($0) }
    sampleList.items = [sampleItem1, sampleItem2]

    return NavigationStack {
        SavedShoppingView()
    }
    .modelContainer(container)
}
