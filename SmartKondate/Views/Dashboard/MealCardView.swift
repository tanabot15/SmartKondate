//
//  MealCardView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct MealCardView: View {
    let diffResult: MealDiffResult
    let availableMenus: [Menu]
    let onSelectMenus: ([Menu]?) -> Void

    @State private var isShowingPickerSheet = false

    // Main Category
    private var mainMenusText: String {
        let mains = diffResult.effectiveMenus.filter { $0.category == "Main" }
        return mains.map { $0.name }.joined(separator: " / ")
    }

    // Side / Soup / Other Category
    private var subMenusText: String {
        let subs = diffResult.effectiveMenus.filter { $0.category != "Main" }
        return subs.map { $0.name }.joined(separator: " / ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(diffResult.mealType.rawValue)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if diffResult.isModified {
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
                    isShowingPickerSheet = true
                }
                .font(.subheadline)
            }

            Divider()

            if diffResult.effectiveMenus.isEmpty {
                Text("No menu assigned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    // Main
                    if !mainMenusText.isEmpty {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("Main:")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            Text(mainMenusText)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    }

                    // Sub
                    if !subMenusText.isEmpty {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("Side/Soup:")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            Text(subMenusText)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $isShowingPickerSheet) {
            NavigationStack {
                List {
                    Section {
                        Button("Clear All") {
                            onSelectMenus(nil)
                            isShowingPickerSheet = false
                        }
                        .foregroundStyle(.red)
                    }

                    Section(header: Text("Available Menus")) {
                        ForEach(availableMenus) { menu in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(menu.name)
                                        .foregroundStyle(.primary)
                                    Text(menu.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("\(diffResult.mealType.rawValue) Menu")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingPickerSheet = false
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

    let dinnerResult = MealDiffResult(
        mealType: .dinner,
        defaultMenus: [main1, side1, soup1],
        customMenus: nil
    )

    let lunchResult = MealDiffResult(
        mealType: .lunch,
        defaultMenus: [],
        customMenus: [main1, main2, side1]
    )

    return ScrollView {
        VStack(spacing: 16) {
            MealCardView(diffResult: dinnerResult, availableMenus: menus, onSelectMenus: { _ in })
            MealCardView(diffResult: lunchResult, availableMenus: menus, onSelectMenus: { _ in })
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(container)
}
