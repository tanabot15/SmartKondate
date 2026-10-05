//
//  StockCheckListView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData

struct StockCheckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockItem.name) private var stockItems: [StockItem]

    @State private var searchText = ""
    @State private var selectedCategory: StockCategory? = nil
    @State private var showOnlyOut = false

    @State private var isShowingAddSheet = false
    @State private var newItemName = ""
    @State private var newItemCategory: StockCategory = .pantry

    // MARK: - Filtered Stock Items
    private var filteredStockItems: [StockItem] {
        stockItems.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedStandardContains(searchText)
            let matchesCategory = (selectedCategory == nil) || (item.category == selectedCategory)
            let matchesStatus = !showOnlyOut || item.isOut
            return matchesSearch && matchesCategory && matchesStatus
        }
    }

    var body: some View {
        Group {
            if stockItems.isEmpty {
                ContentUnavailableView {
                    Label("No Stock Items", systemImage: "archivebox")
                } description: {
                    Text("Tap + to add stock items to manage in your pantry.")
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 0) {
                    // MARK: - Category Filter & Status Toggle
                    VStack(spacing: 8) {
                        Picker("Category", selection: $selectedCategory) {
                            Text("All").tag(Optional<StockCategory>.none)
                            ForEach(StockCategory.allCases) { category in
                                Text(category.rawValue).tag(Optional(category))
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            Toggle(isOn: $showOnlyOut) {
                                Label("Need to Buy Only", systemImage: "cart.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(showOnlyOut ? .orange : .secondary)
                            }
                            .toggleStyle(.button)
                            .buttonStyle(.bordered)
                            .tint(showOnlyOut ? .orange : .gray)

                            Spacer()

                            Text("\(filteredStockItems.count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    // MARK: - List / Search Results
                    if filteredStockItems.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        List {
                            ForEach(StockCategory.allCases) { category in
                                let itemsInCategory = filteredStockItems.filter { $0.category == category }
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
                    }
                }
            }
        }
        .navigationTitle("Stock Checklist")
        .searchable(text: $searchText, prompt: "Search stock items")
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
