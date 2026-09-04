//
//  PatternDetailView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct PatternDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var pattern: KondatePattern
    
    @Query(sort: \Menu.name) private var availableMenus: [Menu]
    @State private var isShowingEditPatternSheet = false

    var sortedDays: [PatternDay] {
        pattern.days.sorted { $0.dayIndex < $1.dayIndex }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(pattern.durationDays) Days")
                        .foregroundStyle(.secondary)
                }
                
                Toggle("Set as Active Pattern", isOn: Binding(
                    get: { pattern.isActive },
                    set: { newValue in
                        if newValue {
                            let fetchDescriptor = FetchDescriptor<KondatePattern>()
                            if let allPatterns = try? modelContext.fetch(fetchDescriptor) {
                                for p in allPatterns { p.isActive = false }
                            }
                        }
                        pattern.isActive = newValue
                    }
                ))
            } header: {
                Text("Pattern Info")
            }

            ForEach(sortedDays) { day in
                Section(header: Text("Day \(day.dayIndex + 1)")) {
                    MealSectionRows(
                        mealTitle: "Breakfast",
                        menus: Binding(
                            get: { day.breakfastMenus },
                            set: { day.breakfastMenus = $0 }
                        ),
                        availableMenus: availableMenus
                    )

                    MealSectionRows(
                        mealTitle: "Lunch",
                        menus: Binding(
                            get: { day.lunchMenus },
                            set: { day.lunchMenus = $0 }
                        ),
                        availableMenus: availableMenus
                    )

                    MealSectionRows(
                        mealTitle: "Dinner",
                        menus: Binding(
                            get: { day.dinnerMenus },
                            set: { day.dinnerMenus = $0 }
                        ),
                        availableMenus: availableMenus
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(pattern.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isShowingEditPatternSheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditPatternSheet) {
            NavigationStack {
                PatternEditorView(patternToEdit: pattern)
            }
        }
        .onAppear {
            ensurePatternDaysExist()
        }
    }

    private func ensurePatternDaysExist() {
        let existingIndices = Set(pattern.days.map { $0.dayIndex })
        for index in 0..<pattern.durationDays {
            if !existingIndices.contains(index) {
                let newDay = PatternDay(dayIndex: index)
                newDay.pattern = pattern
                modelContext.insert(newDay)
            }
        }
    }
}

// MARK: - MealSectionRows (1つの食事区分ごとの Main / Sub 行)
private struct MealSectionRows: View {
    let mealTitle: String
    @Binding var menus: [Menu]
    let availableMenus: [Menu]

    @State private var isShowingSubSheet = false

    // Mainカテゴリのメニュー（単一）
    private var mainSelection: Menu? {
        menus.first(where: { $0.category == "Main" })
    }

    // Main以外のサブカテゴリ（Side, Soup等）のメニュー（複数）
    private var selectedSubMenus: [Menu] {
        menus.filter { $0.category != "Main" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mealTitle)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            // Main
            HStack {
                Text("Main")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Picker("Main", selection: Binding(
                    get: { mainSelection },
                    set: { newMain in
                        var updated = menus.filter { $0.category != "Main" }
                        if let newMain = newMain {
                            updated.append(newMain)
                        }
                        menus = updated
                    }
                )) {
                    Text("None").tag(Menu?.none)
                    Divider()
                    ForEach(availableMenus.filter { $0.category == "Main" }) { menu in
                        Text(menu.name).tag(Menu?.some(menu))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Divider()

            // Subs
            HStack {
                Text("Side / Soup")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    isShowingSubSheet = true
                } label: {
                    if selectedSubMenus.isEmpty {
                        Text("None")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(selectedSubMenus.map { $0.name }.joined(separator: " / "))
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isShowingSubSheet) {
            SubMenuPickerSheet(
                mealTitle: mealTitle,
                allSubMenus: availableMenus.filter { $0.category != "Main" },
                selectedSubMenus: selectedSubMenus,
                onSave: { updatedSubs in
                    // Main は残したまま、Subメニュー群を差し替える
                    let currentMain = menus.filter { $0.category == "Main" }
                    menus = currentMain + updatedSubs
                }
            )
        }
    }
}

// MARK: - SubMenuPickerSheet
private struct SubMenuPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let mealTitle: String
    let allSubMenus: [Menu]
    @State var selectedSubMenus: [Menu]
    let onSave: ([Menu]) -> Void

    init(mealTitle: String, allSubMenus: [Menu], selectedSubMenus: [Menu], onSave: @escaping ([Menu]) -> Void) {
        self.mealTitle = mealTitle
        self.allSubMenus = allSubMenus
        self._selectedSubMenus = State(initialValue: selectedSubMenus)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                if allSubMenus.isEmpty {
                    ContentUnavailableView(
                        "No Side or Soup Available",
                        systemImage: "fork.knife",
                        description: Text("Register Side/Soup items in Menus first.")
                    )
                } else {
                    ForEach(allSubMenus) { menu in
                        Button {
                            toggleSelection(menu)
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
                                if selectedSubMenus.contains(where: { $0.id == menu.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("\(mealTitle) - Side & Soup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedSubMenus)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggleSelection(_ menu: Menu) {
        if let index = selectedSubMenus.firstIndex(where: { $0.id == menu.id }) {
            selectedSubMenus.remove(at: index)
        } else {
            selectedSubMenus.append(menu)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self,
        configurations: config
    )
    let context = container.mainContext

    let main1 = Menu(name: "Toast & Fried Eggs", category: "Main")
    let main2 = Menu(name: "Chicken Teriyaki Bowl", category: "Main")
    let side1 = Menu(name: "Green Salad", category: "Side")
    let soup1 = Menu(name: "Miso Soup", category: "Soup")
    [main1, main2, side1, soup1].forEach { context.insert($0) }

    let pattern = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
    context.insert(pattern)

    let day1 = PatternDay(dayIndex: 0, breakfastMenus: [main1, side1], lunchMenus: [main2], dinnerMenus: [main2, side1, soup1])
    day1.pattern = pattern
    context.insert(day1)

    return NavigationStack {
        PatternDetailView(pattern: pattern)
    }
    .modelContainer(container)
}
