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

    @State private var isShowingAddItemAlert = false
    @State private var newItemName = ""
    @State private var newItemCategory = "Pantry"

    private let categories = ["Pantry", "Seasoning", "Household", "Other"]

    var body: some View {
        List {
            ForEach(categories, id: \.self) { category in
                let itemsInCategory = stockItems.filter { $0.category == category }
                if !itemsInCategory.isEmpty {
                    Section(header: Text(category)) {
                        ForEach(itemsInCategory) { item in
                            Button {
                                toggleStockStatus(item)
                            } label: {
                                HStack {
                                    Image(systemName: item.isOut ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isOut ? .red : .secondary)
                                        .font(.title3)

                                    Text(item.name)
                                        .foregroundStyle(item.isOut ? .secondary : .primary)
                                        .strikethrough(item.isOut)

                                    Spacer()

                                    if item.isOut {
                                        Text("Buy")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.1))
                                            .foregroundStyle(.red)
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
                Button {
                    isShowingAddItemAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Add Stock Item", isPresented: $isShowingAddItemAlert) {
            TextField("Item Name", text: $newItemName)
            Button("Cancel", role: .cancel) {
                newItemName = ""
            }
            Button("Add") {
                addStockItem()
            }
            .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func toggleStockStatus(_ item: StockItem) {
        item.isOut.toggle()
    }

    private func addStockItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let item = StockItem(name: trimmed, category: newItemCategory)
        modelContext.insert(item)
        newItemName = ""
    }

    private func deleteItems(at offsets: IndexSet, in categoryItems: [StockItem]) {
        for index in offsets {
            let itemToDelete = categoryItems[index]
            modelContext.delete(itemToDelete)
        }
    }
}

#Preview {
    NavigationStack {
        StockCheckListView()
    }
    .modelContainer(for: [StockItem.self], inMemory: true)
}
