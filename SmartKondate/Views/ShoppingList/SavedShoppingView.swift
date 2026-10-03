//
//  SavedShoppingView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

struct SavedShoppingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedShoppingList.createdAt, order: .reverse) private var savedLists: [SavedShoppingList]

    var body: some View {
        List {
            if savedLists.isEmpty {
                ContentUnavailableView {
                    Label("No Saved Lists", systemImage: "cart")
                } description: {
                    Text("You can save a shopping list using the save button on the Shopping List screen.")
                }
            } else {
                ForEach(savedLists) { list in
                    NavigationLink(destination: SavedShoppingDetailView(shoppingList: list)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(list.title)
                                .font(.headline)
                            Text(list.createdAt.formatted(date: .numeric, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(list.items.count) item(s)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteLists)
            }
        }
        .navigationTitle("Saved Lists")
    }

    private func deleteLists(offsets: IndexSet) {
        for index in offsets {
            let list = savedLists[index]
            modelContext.delete(list)
        }
    }
}

struct SavedShoppingDetailView: View {
    @Bindable var shoppingList: SavedShoppingList

    private var groupedItems: [IngredientCategory: [SavedIngredientItem]] {
        Dictionary(grouping: shoppingList.items, by: { $0.category })
    }

    var body: some View {
        List {
            ForEach(IngredientCategory.allCases, id: \.self) { category in
                if let items = groupedItems[category], !items.isEmpty {
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

                                Text(item.name)
                                    .strikethrough(item.isChecked)
                                    .foregroundStyle(item.isChecked ? .secondary : .primary)

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
        .navigationTitle(shoppingList.title)
    }

    private func formatQuantity(_ val: Double) -> String {
        val.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", val) : String(format: "%.1f", val)
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

    // Sample List 1
    let sampleList1 = SavedShoppingList(
        title: "Weekly Grocery - Plan A",
        createdAt: Date()
    )
    context.insert(sampleList1)

    let sampleItem1 = SavedIngredientItem(name: "Onion", quantity: 2, unit: "pcs", category: .produce)
    let sampleItem2 = SavedIngredientItem(name: "Pork Belly", quantity: 300, unit: "g", category: .meatAndFish, isChecked: true)
    let sampleItem3 = SavedIngredientItem(name: "Soy Sauce", quantity: 1, unit: "tbsp", category: .pantryAndGrain)
    
    [sampleItem1, sampleItem2, sampleItem3].forEach { context.insert($0) }
    sampleList1.items = [sampleItem1, sampleItem2, sampleItem3]

    // Sample List 2
    let sampleList2 = SavedShoppingList(
        title: "Weekend BBQ",
        createdAt: Date().addingTimeInterval(-86400 * 2)
    )
    context.insert(sampleList2)

    let sampleItem4 = SavedIngredientItem(name: "Beef Ribs", quantity: 500, unit: "g", category: .meatAndFish)
    let sampleItem5 = SavedIngredientItem(name: "Lettuce", quantity: 1, unit: "head", category: .produce)
    
    [sampleItem4, sampleItem5].forEach { context.insert($0) }
    sampleList2.items = [sampleItem4, sampleItem5]

    return NavigationStack {
        SavedShoppingView()
    }
    .modelContainer(container)
}
