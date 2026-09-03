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
                    isShowingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Item Info")) {
                        TextField("Item Name (e.g. Soy Sauce)", text: $newItemName)
                        
                        Picker("Category", selection: $newItemCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
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
        
        let item = StockItem(name: trimmed, category: newItemCategory)
        modelContext.insert(item)
        resetInput()
    }

    private func resetInput() {
        newItemName = ""
        newItemCategory = "Pantry"
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
        for: StockItem.self,
        configurations: config
    )
    let context = container.mainContext

    let items = [
        StockItem(name: "Soy Sauce", category: "Seasoning", isOut: false),
        StockItem(name: "Mirin", category: "Seasoning", isOut: false),
        StockItem(name: "Miso Paste", category: "Seasoning", isOut: true),
        StockItem(name: "Rice", category: "Pantry", isOut: false),
        StockItem(name: "Flour", category: "Pantry", isOut: true),
        StockItem(name: "Milk", category: "Household", isOut: false),
        StockItem(name: "Tofu", category: "Household", isOut: true)
    ]

    items.forEach { context.insert($0) }

    return NavigationStack {
        StockCheckListView()
    }
    .modelContainer(container)
}
