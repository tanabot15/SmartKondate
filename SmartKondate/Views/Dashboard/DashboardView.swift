//
//  DashboardView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<KondatePattern> { $0.isActive }) private var activePatterns: [KondatePattern]
    @Query(sort: \Menu.name) private var availableMenus: [Menu]

    @State private var selectedDate: Date = Date()

    @State private var customBreakfast: [Menu]?
    @State private var customLunch: [Menu]?
    @State private var customDinner: [Menu]?

    private var activePattern: KondatePattern? {
        activePatterns.first
    }

    private var diffResults: [MealDiffResult] {
        DiffCalculator.calculateDiff(
            for: selectedDate,
            pattern: activePattern,
            startDate: activePattern?.createdAt ?? Date(),
            customBreakfast: customBreakfast,
            customLunch: customLunch,
            customDinner: customDinner
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    DatePicker(
                        "Target Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()

                    if let pattern = activePattern {
                        let dayIndex = DiffCalculator.calculateDayIndex(
                            for: selectedDate,
                            startDate: pattern.createdAt,
                            durationDays: pattern.durationDays
                        )
                        Text("Active Pattern: \(pattern.name) (Day \(dayIndex + 1)/\(pattern.durationDays))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No active pattern selected")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Meal Card
                ForEach(diffResults, id: \.mealType) { result in
                    MealCardView(
                        diffResult: result,
                        availableMenus: availableMenus,
                        onSelectMenus: { newMenus in
                            updateCustomMenus(for: result.mealType, with: newMenus)
                        }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Today's Menu")
    }

    private func updateCustomMenus(for mealType: MealType, with menus: [Menu]?) {
        switch mealType {
        case .breakfast:
            customBreakfast = menus
        case .lunch:
            customLunch = menus
        case .dinner:
            customDinner = menus
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self,
        configurations: config
    )

    let context = container.mainContext

    let ing1 = Ingredient(name: "Bread", amount: "2 slices")
    let ing2 = Ingredient(name: "Egg", amount: "2 pcs")
    let ing3 = Ingredient(name: "Chicken Thigh", amount: "150g")
    let ing4 = Ingredient(name: "Rice", amount: "1 bowl")
    let ing5 = Ingredient(name: "Salmon Fillet", amount: "2 pcs")

    let menu1 = Menu(name: "Toast & Fried Eggs", category: "Main")
    menu1.ingredients = [ing1, ing2]

    let menu2 = Menu(name: "Chicken Teriyaki Bowl", category: "Main")
    menu2.ingredients = [ing3, ing4]

    let menu3 = Menu(name: "Grilled Salmon & Veggies", category: "Main")
    menu3.ingredients = [ing5]

    let menu4 = Menu(name: "Japanese Curry Rice", category: "Main")

    [menu1, menu2, menu3, menu4].forEach { context.insert($0) }

    let pattern = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
    context.insert(pattern)

    // 複数メニュー配列（[Menu]）渡しの初期化子に修正
    let day1 = PatternDay(dayIndex: 0, breakfastMenus: [menu1], lunchMenus: [menu2], dinnerMenus: [menu3])
    day1.pattern = pattern
    context.insert(day1)

    let stock1 = StockItem(name: "Soy Sauce", category: "Seasoning")
    let stock2 = StockItem(name: "Rice", category: "Pantry")
    [stock1, stock2].forEach { context.insert($0) }

    return NavigationStack {
        DashboardView()
    }
    .modelContainer(container)
}
