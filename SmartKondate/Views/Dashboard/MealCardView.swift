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
    var isToday: Bool = false

    @State private var editingMealType: MealType?
    @State private var selectedMenuForEdit: Menu?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (EEE)"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Day & Date & Today Badge
            HStack(spacing: 8) {
                Text("Day \(dayIndex + 1)")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(dateString)
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? Color.accentColor : .secondary)

                if isToday {
                    Text("TODAY")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }

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
        .background(isToday ? Color.accentColor.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .sheet(item: $editingMealType) { mealType in
            MealEditorSheet(
                mealType: mealType,
                diffResult: diffResults.first { $0.mealType == mealType },
                availableMenus: availableMenus,
                onSelectMenus: onSelectMenus,
                onDismiss: { editingMealType = nil }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedMenuForEdit) { menu in
            NavigationStack {
                MenuDetailEditorView(menuToEdit: menu)
            }
        }
    }
}

// MARK: - Meal Editor Sheet Component
private struct MealEditorSheet: View {
    let mealType: MealType
    let diffResult: MealDiffResult?
    let availableMenus: [Menu]
    let onSelectMenus: (MealType, [Menu]?) -> Void
    let onDismiss: () -> Void

    private var currentMenus: [Menu] {
        diffResult?.effectiveMenus ?? []
    }

    private func isSelected(_ menu: Menu) -> Bool {
        currentMenus.contains(where: { $0.id == menu.id })
    }

    private func toggleMenu(_ menu: Menu) {
        var updated = currentMenus
        if let index = updated.firstIndex(where: { $0.id == menu.id }) {
            updated.remove(at: index)
        } else {
            updated.append(menu)
        }
        onSelectMenus(mealType, updated)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Clear All") {
                        onSelectMenus(mealType, nil)
                        onDismiss()
                    }
                    .foregroundStyle(.red)
                }

                Section(header: Text("Available Menus")) {
                    ForEach(availableMenus) { menu in
                        Button {
                            toggleMenu(menu)
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

                                if isSelected(menu) {
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
                        onDismiss()
                    }
                }
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
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Card Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MealCardView(
                    dayIndex: 0,
                    date: Date(),
                    diffResults: diffResults,
                    availableMenus: menus,
                    onSelectMenus: { _, _ in },
                    isToday: true
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Standard Day Card Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MealCardView(
                    dayIndex: 1,
                    date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                    diffResults: diffResults,
                    availableMenus: menus,
                    onSelectMenus: { _, _ in },
                    isToday: false
                )
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(container)
}
