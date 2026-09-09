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

    @Query(sort: \StockItem.name) private var stockItems: [StockItem]
    @Query(sort: \Ingredient.name) private var existingIngredients: [Ingredient]

    var menuToEdit: Menu?

    @State private var name: String = ""
    @State private var category: String = "Main"
    @State private var source: String = ""
    @State private var memo: String = ""
    
    struct TempIngredient: Identifiable {
        let id: UUID
        var name: String
        var quantity: Double
        var unit: String

        init(id: UUID = UUID(), name: String, quantity: Double, unit: String) {
            self.id = id
            self.name = name
            self.quantity = quantity
            self.unit = unit
        }

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
    
    @State private var editingIngredientID: UUID?

    private let categories = ["Main", "Side", "Soup", "Other"]
    private let commonUnits = ["pcs", "g", "ml", "tbsp", "tsp", "block", "can", "slice", "bundle", "head"]

    private var isAddDisabled: Bool {
        newIngredientName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var autocompleteSuggestions: [(name: String, defaultUnit: String)] {
        let trimmedInput = newIngredientName.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmedInput.isEmpty else { return [] }

        var suggestionsDict: [String: String] = [:]

        for item in stockItems {
            if item.name.lowercased().contains(trimmedInput) {
                suggestionsDict[item.name] = ""
            }
        }

        for ing in existingIngredients {
            if ing.name.lowercased().contains(trimmedInput) {
                if suggestionsDict[ing.name] == nil || suggestionsDict[ing.name]?.isEmpty == true {
                    suggestionsDict[ing.name] = ing.unit
                }
            }
        }

        return suggestionsDict
            .map { (name: $0.key, defaultUnit: $0.value) }
            .sorted { $0.name < $1.name }
    }

    init(menuToEdit: Menu? = nil) {
        self.menuToEdit = menuToEdit
        if let menu = menuToEdit {
            _name = State(initialValue: menu.name)
            _category = State(initialValue: menu.category)
            _source = State(initialValue: menu.source)
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

                TextField("Source (e.g. Book p.12, URL)", text: $source)
            }

            Section(header: Text("Ingredients")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("Item (e.g. Onion)", text: $newIngredientName)
                        
                        TextField("Qty (e.g. 2)", text: $newIngredientQuantity)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                        
                        TextField("Unit", text: $newIngredientUnit)
                            .frame(width: 60)
                        
                        Button {
                            addOrUpdateIngredient()
                        } label: {
                            Image(systemName: editingIngredientID != nil ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(isAddDisabled ? Color(.systemGray4) : Color.accentColor)
                        }
                        .disabled(isAddDisabled)
                    }

                    if !autocompleteSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(autocompleteSuggestions, id: \.name) { suggestion in
                                    Button {
                                        selectSuggestion(suggestion)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "magnifyingglass")
                                                .font(.caption2)
                                            Text(suggestion.name)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                            if !suggestion.defaultUnit.isEmpty {
                                                Text("(\(suggestion.defaultUnit))")
                                                    .font(.caption2)
                                                    .opacity(0.8)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.accentColor.opacity(0.12))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Text("Units:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            ForEach(commonUnits, id: \.self) { unit in
                                Button {
                                    newIngredientUnit = unit
                                } label: {
                                    Text(unit)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(newIngredientUnit == unit ? Color.accentColor : Color(.tertiarySystemFill))
                                        .foregroundStyle(newIngredientUnit == unit ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)

                ForEach(ingredientsList) { item in
                    Button {
                        startEditing(item)
                    } label: {
                        HStack {
                            Text(item.name)
                                .foregroundStyle(.primary)
                                .fontWeight(editingIngredientID == item.id ? .bold : .regular)
                            
                            if editingIngredientID == item.id {
                                Text("(Editing)")
                                    .font(.caption2)
                                    .foregroundStyle(Color.accentColor)
                            }
                            
                            Spacer()
                            
                            Text(item.amountText)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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

    private func selectSuggestion(_ suggestion: (name: String, defaultUnit: String)) {
        newIngredientName = suggestion.name
        if !suggestion.defaultUnit.isEmpty {
            newIngredientUnit = suggestion.defaultUnit
        }
    }

    private func startEditing(_ item: TempIngredient) {
        editingIngredientID = item.id
        newIngredientName = item.name
        newIngredientQuantity = item.quantity > 0 ? (item.quantity.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", item.quantity) : String(format: "%.1f", item.quantity)) : ""
        newIngredientUnit = item.unit
    }

    private func addOrUpdateIngredient() {
        let trimmedName = newIngredientName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let qtyDouble = Double(newIngredientQuantity.trimmingCharacters(in: .whitespaces)) ?? 0.0
        let trimmedUnit = newIngredientUnit.trimmingCharacters(in: .whitespaces)

        if let editingID = editingIngredientID, let index = ingredientsList.firstIndex(where: { $0.id == editingID }) {
            ingredientsList[index].name = trimmedName
            ingredientsList[index].quantity = qtyDouble
            ingredientsList[index].unit = trimmedUnit
        } else {
            let newItem = TempIngredient(name: trimmedName, quantity: qtyDouble, unit: trimmedUnit)
            ingredientsList.append(newItem)
        }
        
        clearInputFields()
    }

    private func clearInputFields() {
        editingIngredientID = nil
        newIngredientName = ""
        newIngredientQuantity = ""
        newIngredientUnit = ""
    }

    private func removeIngredient(at offsets: IndexSet) {
        for index in offsets {
            if ingredientsList[index].id == editingIngredientID {
                clearInputFields()
            }
        }
        ingredientsList.remove(atOffsets: offsets)
    }

    private func saveMenu() {
        let targetMenu: Menu
        if let existing = menuToEdit {
            targetMenu = existing
            targetMenu.name = name
            targetMenu.category = category
            targetMenu.source = source
            targetMenu.memo = memo
            
            for item in targetMenu.ingredients {
                modelContext.delete(item)
            }
            targetMenu.ingredients.removeAll()
        } else {
            targetMenu = Menu(name: name, category: category, source: source, memo: memo)
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
    .modelContainer(for: [Menu.self, Ingredient.self, StockItem.self], inMemory: true)
}

#Preview("Edit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Menu.self, Ingredient.self, StockItem.self,
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
