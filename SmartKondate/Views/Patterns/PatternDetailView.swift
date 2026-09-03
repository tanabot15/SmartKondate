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
                    MealMenuPickerRow(mealTitle: "Breakfast", icon: "sun.max.fill", iconColor: .orange, selectedMenu: Binding(
                        get: { day.breakfastMenu },
                        set: { day.breakfastMenu = $0 }
                    ), availableMenus: availableMenus)

                    MealMenuPickerRow(mealTitle: "Lunch", icon: "sun.headline.fill", iconColor: .yellow, selectedMenu: Binding(
                        get: { day.lunchMenu },
                        set: { day.lunchMenu = $0 }
                    ), availableMenus: availableMenus)

                    MealMenuPickerRow(mealTitle: "Dinner", icon: "moon.stars.fill", iconColor: .indigo, selectedMenu: Binding(
                        get: { day.dinnerMenu },
                        set: { day.dinnerMenu = $0 }
                    ), availableMenus: availableMenus)
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

private struct MealMenuPickerRow: View {
    let mealTitle: String
    let icon: String
    let iconColor: Color
    @Binding var selectedMenu: Menu?
    let availableMenus: [Menu]

    var body: some View {
        HStack {
            Label {
                Text(mealTitle)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            
            Spacer()

            Picker(mealTitle, selection: $selectedMenu) {
                Text("None").tag(Menu?.none)
                Divider()
                ForEach(availableMenus) { menu in
                    Text(menu.name).tag(Menu?.some(menu))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
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

    let menu1 = Menu(name: "Toast & Fried Eggs", category: "Breakfast")
    let menu2 = Menu(name: "Chicken Teriyaki Bowl", category: "Lunch")
    let menu3 = Menu(name: "Grilled Salmon & Veggies", category: "Dinner")
    [menu1, menu2, menu3].forEach { context.insert($0) }

    let pattern = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
    context.insert(pattern)

    let day1 = PatternDay(dayIndex: 0, breakfastMenu: menu1, lunchMenu: menu2, dinnerMenu: menu3)
    day1.pattern = pattern
    context.insert(day1)

    let day2 = PatternDay(dayIndex: 1, breakfastMenu: menu1, lunchMenu: menu2, dinnerMenu: nil)
    day2.pattern = pattern
    context.insert(day2)

    return NavigationStack {
        PatternDetailView(pattern: pattern)
    }
    .modelContainer(container)
}
