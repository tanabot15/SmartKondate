//
//  SavedShoppingListView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/09/18.
//

import SwiftUI
import SwiftData

struct SavedShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedShoppingList.createdAt, order: .reverse) private var savedLists: [SavedShoppingList]

    var body: some View {
        Group {
            if savedLists.isEmpty {
                ContentUnavailableView {
                    Label("No Saved Lists", systemImage: "square.and.arrow.down")
                } description: {
                    Text("Saved shopping lists will appear here.")
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(savedLists) { list in
                        NavigationLink {
                            SavedShoppingDetailView(shoppingList: list)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(list.title)
                                    .font(.headline)

                                HStack {
                                    Text(list.createdAt.formatted(date: .numeric, time: .shortened))
                                    Spacer()
                                    Text("\(list.items.count) items")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete(perform: deleteLists)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Saved Lists")
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            let listToDelete = savedLists[index]
            modelContext.delete(listToDelete)
        }
    }
}

#Preview("List View with Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: SavedShoppingList.self, SavedIngredientItem.self, StockItem.self,
        configurations: config
    )
    let context = container.mainContext

    let list1 = SavedShoppingList(title: "週末の買い物（9/20〜）")
    list1.createdAt = Date()
    
    let item1 = SavedIngredientItem(name: "豚バラ肉", quantity: 300, unit: "g", categoryRawValue: "肉・魚", menuDetails: "豚キムチ", isChecked: false)
    let item2 = SavedIngredientItem(name: "キャベツ", quantity: 0.5, unit: "個", categoryRawValue: "野菜・果物", menuDetails: "回鍋肉", isChecked: true)
    list1.items = [item1, item2]

    let list2 = SavedShoppingList(title: "常備菜・調味料まとめ買い")
    list2.createdAt = Date().addingTimeInterval(-86400 * 3)
    let item3 = SavedIngredientItem(name: "醤油", quantity: 1, unit: "本", categoryRawValue: "調味料・穀物", menuDetails: "", isChecked: false)
    list2.items = [item3]

    context.insert(list1)
    context.insert(list2)

    return NavigationStack {
        SavedShoppingListView()
    }
    .modelContainer(container)
}

#Preview("List View - Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: SavedShoppingList.self, SavedIngredientItem.self, StockItem.self,
        configurations: config
    )

    return NavigationStack {
        SavedShoppingListView()
    }
    .modelContainer(container)
}
