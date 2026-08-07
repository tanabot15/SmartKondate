//
//  ShoppingListView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<KondatePattern> { $0.isActive }) private var activePatterns: [KondatePattern]
    
    @State private var targetDate: Date = Date()
    @State private var checkedIngredientKeys: Set<String> = []

    private var activePattern: KondatePattern? {
        activePatterns.first
    }

    // 今日の朝・昼・夕のメニュー差分計算
    private var diffResults: [MealDiffResult] {
        DiffCalculator.calculateDiff(
            for: targetDate,
            pattern: activePattern,
            startDate: activePattern?.createdAt ?? Date(),
            customBreakfast: nil,
            customLunch: nil,
            customDinner: nil
        )
    }

    // 各食のメニューから食材アイテム（モデル識別用キー付き）を展開
    private var ingredientItems: [ShoppingIngredientItem] {
        var items: [ShoppingIngredientItem] = []
        for result in diffResults {
            guard let menu = result.effectiveMenu else { continue }
            for ingredient in menu.ingredients {
                let key = "\(result.mealType.rawValue)_\(menu.id.uuidString)_\(ingredient.id.uuidString)"
                items.append(
                    ShoppingIngredientItem(
                        id: key,
                        ingredientName: ingredient.name,
                        amount: ingredient.amount,
                        menuName: menu.name,
                        mealType: result.mealType,
                        isModifiedMeal: result.isModified
                    )
                )
            }
        }
        return items
    }

    private var modifiedItems: [ShoppingIngredientItem] {
        ingredientItems.filter { $0.isModifiedMeal }
    }

    private var standardItems: [ShoppingIngredientItem] {
        ingredientItems.filter { !$0.isModifiedMeal }
    }

    var body: some View {
        List {
            // 日付選択セクション
            Section {
                DatePicker("Target Date", selection: $targetDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
            } header: {
                Text("Shopping Period")
            }

            if ingredientItems.isEmpty {
                ContentUnavailableView {
                    Label("No Ingredients Needed", systemImage: "cart")
                } description: {
                    Text("No menus set for this date, or menus contain no ingredients.")
                        .foregroundStyle(.secondary)
                }
            } else {
                // 1. 変更・追加メニューの食材（ハイライトセクション）
                if !modifiedItems.isEmpty {
                    Section {
                        ForEach(modifiedItems) { item in
                            DiffIngredientRow(
                                ingredientName: item.ingredientName,
                                amount: item.amount,
                                menuName: item.menuName,
                                isModifiedMeal: true,
                                isChecked: checkedIngredientKeys.contains(item.id),
                                onToggle: { toggleCheck(for: item.id) }
                            )
                        }
                    } header: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.accentColor)
                            Text("Modified / Added Ingredients")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.bold)
                        }
                    }
                }

                // 2. パターン通りの通常食材
                if !standardItems.isEmpty {
                    Section(header: Text("Standard Ingredients")) {
                        ForEach(standardItems) { item in
                            DiffIngredientRow(
                                ingredientName: item.ingredientName,
                                amount: item.amount,
                                menuName: item.menuName,
                                isModifiedMeal: false,
                                isChecked: checkedIngredientKeys.contains(item.id),
                                onToggle: { toggleCheck(for: item.id) }
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Shopping List")
        .toolbar {
            if !checkedIngredientKeys.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear Checks") {
                        checkedIngredientKeys.removeAll()
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private func toggleCheck(for key: String) {
        if checkedIngredientKeys.contains(key) {
            checkedIngredientKeys.remove(key)
        } else {
            checkedIngredientKeys.insert(key)
        }
    }
}

// 注文表の表示用内部構造体
struct ShoppingIngredientItem: Identifiable {
    let id: String
    let ingredientName: String
    let amount: String
    let menuName: String
    let mealType: MealType
    let isModifiedMeal: Bool
}

#Preview {
    NavigationStack {
        ShoppingListView()
    }
    .modelContainer(for: [KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self], inMemory: true)
}
