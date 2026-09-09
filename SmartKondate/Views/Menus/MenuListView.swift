//
//  MenuListView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct MenuListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Menu.createdAt, order: .reverse) private var menus: [Menu]
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var isShowingEditor = false
    @State private var selectedMenuForEdit: Menu?
    
    private let categories = ["All", "Main", "Side", "Soup", "Other"]
    
    var filteredMenus: [Menu] {
        menus.filter { menu in
            let matchesCategory = (selectedCategory == "All") || (menu.category == selectedCategory)
            let matchesSearch = searchText.isEmpty || menu.name.localizedStandardContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { cat in
                    Text(cat).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if filteredMenus.isEmpty {
                ContentUnavailableView {
                    Label("No Menus Found", systemImage: "fork.knife")
                } description: {
                    Text("Tap + to register a new menu item.")
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(filteredMenus) { menu in
                        Button {
                            selectedMenuForEdit = menu
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(menu.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    if !menu.ingredients.isEmpty {
                                        Text(menu.ingredients.map { "\($0.name)\($0.amountText.isEmpty ? "" : " (\($0.amountText))")" }.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    if !menu.source.trimmingCharacters(in: .whitespaces).isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "bookmark")
                                                .font(.caption2)
                                            Text(menu.source)
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(menu.category)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteMenus)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Menus")
        .searchable(text: $searchText, prompt: "Search recipes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            NavigationStack {
                MenuDetailEditorView()
            }
        }
        .sheet(item: $selectedMenuForEdit) { menu in
            NavigationStack {
                MenuDetailEditorView(menuToEdit: menu)
            }
        }
    }

    private func deleteMenus(offsets: IndexSet) {
        for index in offsets {
            let menuToDelete = filteredMenus[index]
            modelContext.delete(menuToDelete)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Menu.self, Ingredient.self,
        configurations: config
    )
    let context = container.mainContext

    let menu1 = Menu(
        name: "Toast & Fried Eggs",
        category: "Breakfast",
        source: "Breakfast Cookbook p.15"
    )
    let ing1 = Ingredient(name: "Bread", quantity: 2, unit: "slices")
    let ing2 = Ingredient(name: "Egg", quantity: 2, unit: "pcs")
    menu1.ingredients = [ing1, ing2]

    let menu2 = Menu(
        name: "Chicken Teriyaki Bowl",
        category: "Main",
        source: "https://example.com/recipes/teriyaki"
    )
    let ing3 = Ingredient(name: "Chicken Thigh", quantity: 150, unit: "g")
    let ing4 = Ingredient(name: "Rice", quantity: 1, unit: "bowl")
    menu2.ingredients = [ing3, ing4]

    [menu1, menu2].forEach { context.insert($0) }

    return NavigationStack {
        MenuListView()
    }
    .modelContainer(container)
}
