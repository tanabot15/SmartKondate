//
//  MenuDetailEditorView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct MenuDetailEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var menuToEdit: Menu?

    @State private var name: String = ""
    @State private var category: String = "Main"
    @State private var memo: String = ""
    
    // 編集用ローカル食材構造体
    struct TempIngredient: Identifiable {
        let id = UUID()
        var name: String
        var amount: String
    }
    
    @State private var ingredientsList: [TempIngredient] = []
    @State private var newIngredientName: String = ""
    @State private var newIngredientAmount: String = ""

    private let categories = ["Main", "Side", "Soup", "Other"]

    init(menuToEdit: Menu? = nil) {
        self.menuToEdit = menuToEdit
        if let menu = menuToEdit {
            _name = State(initialValue: menu.name)
            _category = State(initialValue: menu.category)
            _memo = State(initialValue: menu.memo)
            _ingredientsList = State(initialValue: menu.ingredients.map {
                TempIngredient(name: $0.name, amount: $0.amount)
            })
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Menu Name (e.g. Curry)", text: $name)
                
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
            }

            Section(header: Text("Ingredients")) {
                HStack {
                    TextField("Item (e.g. Onion)", text: $newIngredientName)
                    TextField("Amount (e.g. 1/2)", text: $newIngredientAmount)
                        .frame(width: 100)
                    
                    Button {
                        addIngredient()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(newIngredientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                ForEach(ingredientsList) { item in
                    HStack {
                        Text(item.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(item.amount)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: removeIngredient)
            }

            Section(header: Text("Memo")) {
                TextField("Notes, recipes, or links...", text: $memo, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(menuToEdit == nil ? "New Menu" : "Edit Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveMenu()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addIngredient() {
        let trimmedName = newIngredientName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let newItem = TempIngredient(name: trimmedName, amount: newIngredientAmount.trimmingCharacters(in: .whitespaces))
        ingredientsList.append(newItem)
        newIngredientName = ""
        newIngredientAmount = ""
    }

    private func removeIngredient(at offsets: IndexSet) {
        ingredientsList.remove(atOffsets: offsets)
    }

    private func saveMenu() {
        let targetMenu: Menu
        if let existing = menuToEdit {
            targetMenu = existing
            targetMenu.name = name
            targetMenu.category = category
            targetMenu.memo = memo
            
            // 既存の Ingredient を削除して新しく同期
            for item in targetMenu.ingredients {
                modelContext.delete(item)
            }
            targetMenu.ingredients.removeAll()
        } else {
            targetMenu = Menu(name: name, category: category, memo: memo)
            modelContext.insert(targetMenu)
        }

        // 新しい Ingredient オブジェクトを構築して関連付け
        for temp in ingredientsList {
            let ingredient = Ingredient(name: temp.name, amount: temp.amount)
            ingredient.menu = targetMenu
            modelContext.insert(ingredient)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        MenuDetailEditorView()
    }
    .modelContainer(for: [Menu.self, Ingredient.self], inMemory: true)
}
