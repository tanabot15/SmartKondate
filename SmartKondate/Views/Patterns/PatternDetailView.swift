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

    @State private var isShowingMainSheet = false
    @State private var isShowingSubSheet = false

    // Mainカテゴリのメニュー（単一）
    private var mainSelection: Menu? {
        menus.first(where: { $0.category == .main })
    }

    // Main以外のサブカテゴリ（Side, Soup等）のメニュー（複数）
    private var selectedSubMenus: [Menu] {
        menus.filter { $0.category != .main }
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

                Button {
                    isShowingMainSheet = true
                } label: {
                    if let mainSelection {
                        Text(mainSelection.name)
                            .foregroundStyle(.primary)
                    } else {
                        Text("None")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
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
        .sheet(isPresented: $isShowingMainSheet) {
            MenuPickerSheet(
                title: "\(mealTitle) - Main",
                candidateMenus: availableMenus.filter { $0.category == .main },
                selectedMenus: mainSelection.map { [$0] } ?? [],
                isSingleSelection: true,
                onSave: { updatedMains in
                    let currentSubs = menus.filter { $0.category != .main }
                    menus = updatedMains + currentSubs
                }
            )
        }
        .sheet(isPresented: $isShowingSubSheet) {
            MenuPickerSheet(
                title: "\(mealTitle) - Side & Soup",
                candidateMenus: availableMenus.filter { $0.category != .main },
                selectedMenus: selectedSubMenus,
                isSingleSelection: false,
                onSave: { updatedSubs in
                    let currentMain = menus.filter { $0.category == .main }
                    menus = currentMain + updatedSubs
                }
            )
        }
    }
}

// MARK: - MenuPickerSheet (Main / Sub 共通メニュー選択シート)
private struct MenuPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let candidateMenus: [Menu]
    @State private var selectedMenus: [Menu]
    let isSingleSelection: Bool
    let onSave: ([Menu]) -> Void

    @State private var searchText = ""

    init(
        title: String,
        candidateMenus: [Menu],
        selectedMenus: [Menu],
        isSingleSelection: Bool,
        onSave: @escaping ([Menu]) -> Void
    ) {
        self.title = title
        self.candidateMenus = candidateMenus
        self._selectedMenus = State(initialValue: selectedMenus)
        self.isSingleSelection = isSingleSelection
        self.onSave = onSave
    }

    private var filteredMenus: [Menu] {
        if searchText.isEmpty {
            return candidateMenus
        } else {
            return candidateMenus.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if candidateMenus.isEmpty {
                    ContentUnavailableView(
                        "No Menus Available",
                        systemImage: "fork.knife",
                        description: Text("Register items in Menus first.")
                    )
                } else if filteredMenus.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(filteredMenus) { menu in
                        Button {
                            toggleSelection(menu)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(menu.name)
                                        .foregroundStyle(.primary)
                                    Text(menu.category.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedMenus.contains(where: { $0.id == menu.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search menus")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedMenus)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggleSelection(_ menu: Menu) {
        if isSingleSelection {
            if selectedMenus.contains(where: { $0.id == menu.id }) {
                selectedMenus.removeAll()
            } else {
                selectedMenus = [menu]
            }
        } else {
            if let index = selectedMenus.firstIndex(where: { $0.id == menu.id }) {
                selectedMenus.remove(at: index)
            } else {
                selectedMenus.append(menu)
            }
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

    let main1 = Menu(name: "Toast & Fried Eggs", category: .main)
    let main2 = Menu(name: "Chicken Teriyaki Bowl", category: .main)
    let side1 = Menu(name: "Green Salad", category: .side)
    let soup1 = Menu(name: "Miso Soup", category: .soup)
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
