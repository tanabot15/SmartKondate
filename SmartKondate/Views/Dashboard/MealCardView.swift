//
//  MealCardView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct MealCardView: View {
    let dayIndex: Int
    let date: Date
    let diffResults: [MealDiffResult]
    let availableMenus: [Menu]
    let onSelectMenus: (MealType, [Menu]?) -> Void

    @State private var editingMealType: MealType?
    @State private var selectedMenuForEdit: Menu?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (EEE)"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Day & Date
            HStack {
                Text("Day \(dayIndex + 1)")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Divider()

            ForEach(diffResults, id: \.mealType) { result in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(result.mealType.rawValue)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)

                        if result.isModified {
                            Text("Modified")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Button("Change") {
                            editingMealType = result.mealType
                        }
                        .font(.caption)
                    }

                    if result.effectiveMenus.isEmpty {
                        Text("No menu assigned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        let mains = result.effectiveMenus.filter { $0.category == .main }
                        let sides = result.effectiveMenus.filter { $0.category != .main }

                        VStack(alignment: .leading, spacing: 4) {
                            if !mains.isEmpty {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("Main:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    FlowMenuView(menus: mains) { menu in
                                        selectedMenuForEdit = menu
                                    }
                                }
                            }
                            if !sides.isEmpty {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("Side:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    FlowMenuView(menus: sides) { menu in
                                        selectedMenuForEdit = menu
                                    }
                                }
                            }
                        }
                    }
                }
                
                if result.mealType != .dinner {
                    Divider()
                        .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(item: $editingMealType) { mealType in
            let currentResult = diffResults.first { $0.mealType == mealType }
            NavigationStack {
                List {
                    Section {
                        Button("Clear All") {
                            onSelectMenus(mealType, nil)
                            editingMealType = nil
                        }
                        .foregroundStyle(.red)
                    }

                    Section(header: Text("Available Menus")) {
                        ForEach(availableMenus) { menu in
                            Button {
                                let current = currentResult?.effectiveMenus ?? []
                                var updated = current
                                if let idx = updated.firstIndex(where: { $0.id == menu.id }) {
                                    updated.remove(at: idx)
                                } else {
                                    updated.append(menu)
                                }
                                onSelectMenus(mealType, updated)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(menu.name)
                                            .foregroundStyle(.primary)
                                        Text(menu.category.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if currentResult?.effectiveMenus.contains(where: { $0.id == menu.id }) == true {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("\(mealType.rawValue) Menu")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            editingMealType = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedMenuForEdit) { menu in
            NavigationStack {
                MenuDetailEditorView(menuToEdit: menu)
            }
        }
    }
}

// MARK: - Helper View for Clickable Menus
private struct FlowMenuView: View {
    let menus: [Menu]
    let onTap: (Menu) -> Void

    var body: some View {
        ForEach(Array(menus.enumerated()), id: \.element.id) { index, menu in
            Button {
                onTap(menu)
            } label: {
                Text(menu.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                    .underline(true, color: Color.primary.opacity(0.3))
            }
            .buttonStyle(.plain)

            if index < menus.count - 1 {
                Text("/")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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

    let main1 = Menu(name: "Hamburger Steak", category: .main)
    let main2 = Menu(name: "Grilled Chicken", category: .main)
    let side1 = Menu(name: "Caesar Salad", category: .side)
    let soup1 = Menu(name: "Corn Soup", category: .soup)

    let menus = [main1, main2, side1, soup1]
    menus.forEach { context.insert($0) }

    let breakfastResult = MealDiffResult(
        mealType: .breakfast,
        defaultMenus: [],
        customMenus: nil
    )

    let lunchResult = MealDiffResult(
        mealType: .lunch,
        defaultMenus: [],
        customMenus: [main1, main2, side1]
    )

    let dinnerResult = MealDiffResult(
        mealType: .dinner,
        defaultMenus: [main1, side1, soup1],
        customMenus: nil
    )

    let diffResults = [breakfastResult, lunchResult, dinnerResult]

    return ScrollView {
        VStack(spacing: 16) {
            MealCardView(
                dayIndex: 0,
                date: Date(),
                diffResults: diffResults,
                availableMenus: menus,
                onSelectMenus: { mealType, newMenus in }
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(container)
}
