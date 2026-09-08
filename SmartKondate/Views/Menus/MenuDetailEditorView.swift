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
    
    struct TempIngredient: Identifiable {
        let id = UUID()
        var name: String
        var quantity: Double
        var unit: String

        var amountText: String {
            guard quantity > 0 else { return "" }
            let formattedQuantity = quantity.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", quantity)
                : String(format: "%.1f", quantity)
            return "\(formattedQuantity)\(unit)"
        }
    }
    
    @State private var ingredientsList: [TempIngredient] = []
    @State private var newIngredientName: String = ""
    @State private var newIngredientQuantity: String = ""
    @State private var newIngredientUnit: String = ""

    private let categories = ["Main", "Side", "Soup", "Other"]

    init(menuToEdit: Menu? = nil) {
        self.menuToEdit = menuToEdit
        if let menu = menuToEdit {
            _name = State(initialValue: menu.name)
            _category = State(initialValue: menu.category)
            _memo = State(initialValue: menu.memo)
            
            let initialIngredients = menu.ingredients.map {
                TempIngredient(name: $0.name, quantity: $0.quantity, unit: $0.unit)
            }
            _ingredientsList = State(initialValue: initialIngredients)
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
                VStack(spacing: 8) {
                    HStack {
                        TextField("Item (e.g. Onion)", text: $newIngredientName)
                        
                        TextField("Qty (e.g. 2)", text: $newIngredientQuantity)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                        
                        TextField("Unit (e.g. pcs)", text: $newIngredientUnit)
                            .frame(width: 70)
                        
                        Button {
                            addIngredient()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                        .disabled(newIngredientName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                ForEach(ingredientsList) { item in
                    HStack {
                        Text(item.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(item.amountText)
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
        
        let qtyDouble = Double(newIngredientQuantity.trimmingCharacters(in: .whitespaces)) ?? 0.0
        let trimmedUnit = newIngredientUnit.trimmingCharacters(in: .whitespaces)

        let newItem = TempIngredient(name: trimmedName, quantity: qtyDouble, unit: trimmedUnit)
        ingredientsList.append(newItem)
        
        newIngredientName = ""
        newIngredientQuantity = ""
        newIngredientUnit = ""
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
            
            for item in targetMenu.ingredients {
                modelContext.delete(item)
            }
            targetMenu.ingredients.removeAll()
        } else {
            targetMenu = Menu(name: name, category: category, memo: memo)
            modelContext.insert(targetMenu)
        }

        for temp in ingredientsList {
            let ingredient = Ingredient(name: temp.name, quantity: temp.quantity, unit: temp.unit)
            ingredient.menu = targetMenu
            modelContext.insert(ingredient)
        }

        dismiss()
    }
}

#Preview("New") {
    NavigationStack {
        MenuDetailEditorView()
    }
    .modelContainer(for: [Menu.self, Ingredient.self], inMemory: true)
}

#Preview("Edit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Menu.self, Ingredient.self,
        configurations: config
    )
    let context = container.mainContext

    let sampleMenu = Menu(
        name: "Japanese Curry Rice",
        category: "Main",
        memo: "Simmer on low heat for 20 minutes after adding roux."
    )
    let ing1 = Ingredient(name: "Pork", quantity: 300, unit: "g")
    let ing2 = Ingredient(name: "Onion", quantity: 2, unit: "pcs")
    let ing3 = Ingredient(name: "Carrot", quantity: 1, unit: "pc")
    
    ing1.menu = sampleMenu
    ing2.menu = sampleMenu
    ing3.menu = sampleMenu

    context.insert(sampleMenu)

    return NavigationStack {
        MenuDetailEditorView(menuToEdit: sampleMenu)
    }
    .modelContainer(container)
}
