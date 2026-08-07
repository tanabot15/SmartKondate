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
                            // 他のパターンのアクティブ状態を解除
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

    // 指定した durationDays 分の PatternDay オブジェクトが存在することを確認・生成
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

// サブ View: 食事タイプ別のメニュー選択 Picker 行
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
    let pattern = KondatePattern(name: "Standard Weekly", durationDays: 7, isActive: true)
    return NavigationStack {
        PatternDetailView(pattern: pattern)
    }
    .modelContainer(for: [KondatePattern.self, PatternDay.self, Menu.self], inMemory: true)
}
