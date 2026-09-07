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
                        let mainText = result.effectiveMenus
                            .filter { $0.category == "Main" }
                            .map { $0.name }
                            .joined(separator: " / ")

                        let subText = result.effectiveMenus
                            .filter { $0.category != "Main" }
                            .map { $0.name }
                            .joined(separator: " / ")

                        VStack(alignment: .leading, spacing: 2) {
                            if !mainText.isEmpty {
                                Text("Main: \(mainText)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                            }
                            if !subText.isEmpty {
                                Text("Side: \(subText)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                                        Text(menu.category)
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
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Menu.self, Ingredient.self,
        configurations: config
    )
    let context = container.mainContext

    let main1 = Menu(name: "Hamburger Steak", category: "Main")
    let main2 = Menu(name: "Grilled Chicken", category: "Main")
    let side1 = Menu(name: "Caesar Salad", category: "Side")
    let soup1 = Menu(name: "Corn Soup", category: "Soup")

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
