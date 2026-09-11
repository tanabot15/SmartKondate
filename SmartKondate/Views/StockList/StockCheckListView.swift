//
//  StockCheckListView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct StockCheckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockItem.name) private var stockItems: [StockItem]

    @State private var isShowingAddSheet = false
    @State private var newItemName = ""
    @State private var newItemCategory: StockCategory = .pantry // String から StockCategory へ変更

    var body: some View {
        List {
            // MARK: - Shopping List Navigation Section
            Section {
                NavigationLink {
                    ShoppingListView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "cart.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Shopping List")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Check ingredients needed for scheduled meals")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // MARK: - Stock Items Section
            ForEach(StockCategory.allCases) { category in
                let itemsInCategory = stockItems.filter { $0.category == category }
                if !itemsInCategory.isEmpty {
                    Section(header: Text(category.rawValue)) {
                        ForEach(itemsInCategory) { item in
                            Button {
                                toggleStockStatus(item)
                            } label: {
                                HStack {
                                    Image(systemName: item.isOut ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isOut ? Color.accentColor : .secondary)
                                        .font(.title3)

                                    Text(item.name)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if item.isOut {
                                        Text("Need to Buy")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .foregroundStyle(.orange)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            deleteItems(at: offsets, in: itemsInCategory)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Stock")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    NavigationLink {
                        ShoppingListView()
                    } label: {
                        Image(systemName: "cart")
                    }

                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Item Info")) {
                        TextField("Item Name (e.g. Soy Sauce)", text: $newItemName)
                        
                        Picker("Category", selection: $newItemCategory) {
                            ForEach(StockCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                    }
                }
                .navigationTitle("Add Stock Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetInput()
                            isShowingAddSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addStockItem()
                            isShowingAddSheet = false
                        }
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func toggleStockStatus(_ item: StockItem) {
        item.isOut.toggle()
    }

    private func addStockItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // newItemCategory (StockCategory) をそのまま渡す
        let item = StockItem(name: trimmed, category: newItemCategory, isOut: true)
        modelContext.insert(item)
        resetInput()
    }

    private func resetInput() {
        newItemName = ""
        newItemCategory = .pantry
    }

    private func deleteItems(at offsets: IndexSet, in categoryItems: [StockItem]) {
        for index in offsets {
            let itemToDelete = categoryItems[index]
            modelContext.delete(itemToDelete)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: StockItem.self, KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self,
        configurations: config
    )
    let context = container.mainContext

    let items = [
        StockItem(name: "Soy Sauce", category: .seasoning, isOut: false),
        StockItem(name: "Mirin", category: .seasoning, isOut: false),
        StockItem(name: "Miso Paste", category: .seasoning, isOut: true),
        StockItem(name: "Rice", category: .pantry, isOut: false),
        StockItem(name: "Flour", category: .pantry, isOut: true),
        StockItem(name: "Milk", category: .pantry, isOut: false),
        StockItem(name: "Tofu", category: .pantry, isOut: true)
    ]

    items.forEach { context.insert($0) }

    return NavigationStack {
        StockCheckListView()
    }
    .modelContainer(container)
}
