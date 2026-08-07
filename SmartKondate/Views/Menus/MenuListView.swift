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
            // Category Filter Picker
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
                                        Text(menu.ingredients.map { $0.name }.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
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
    NavigationStack {
        MenuListView()
    }
    .modelContainer(for: [Menu.self, Ingredient.self], inMemory: true)
}
