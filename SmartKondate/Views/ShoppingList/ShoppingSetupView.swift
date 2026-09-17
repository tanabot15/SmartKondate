//
//  ShoppingSetupView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/09/17.
//

import SwiftUI
import SwiftData

struct ShoppingSetupView: View {
    @Query(sort: \KondatePattern.createdAt, order: .reverse) private var allPatterns: [KondatePattern]
    @Query(sort: \Menu.createdAt, order: .reverse) private var allMenus: [Menu]
    
    @State private var selectedPatternID: UUID?
    @State private var enabledDayIndices: Set<Int> = []
    @State private var extraSources: [ExtraSourceItem] = []
    @State private var showAddSourcePopover: Bool = false

    private var activePattern: KondatePattern? {
        allPatterns.first { $0.queueOrder == 0 } ?? allPatterns.first { $0.isActive }
    }

    private var selectedPattern: KondatePattern? {
        if let id = selectedPatternID {
            return allPatterns.first { $0.id == id }
        }
        return activePattern ?? allPatterns.first
    }

    private var currentConfig: ShoppingListConfig {
        ShoppingListConfig(
            selectedPattern: selectedPattern,
            selectedDayIndices: enabledDayIndices,
            extraSources: extraSources
        )
    }

    var body: some View {
        Form {
            // MARK: - 1. Base Pattern & Days Configuration
            Section {
                if allPatterns.isEmpty {
                    Text("No patterns available")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Base Pattern", selection: $selectedPatternID) {
                        ForEach(allPatterns) { pattern in
                            HStack {
                                Text(pattern.name)
                                if pattern.queueOrder == 0 {
                                    Text("(Active)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(Optional(pattern.id))
                        }
                    }
                    .onChange(of: selectedPatternID) { _, _ in
                        resetEnabledDays()
                    }

                    if let pattern = selectedPattern {
                        DisclosureGroup("Include Days (\(enabledDayIndices.count)/\(pattern.durationDays))") {
                            ForEach(0..<pattern.durationDays, id: \.self) { dayIdx in
                                Toggle(isOn: Binding(
                                    get: { enabledDayIndices.contains(dayIdx) },
                                    set: { isEnabled in
                                        if isEnabled {
                                            enabledDayIndices.insert(dayIdx)
                                        } else {
                                            enabledDayIndices.remove(dayIdx)
                                        }
                                    }
                                )) {
                                    Text("Day \(dayIdx + 1)")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Base Pattern Setup")
            }

            // MARK: - 2. Extra Additions
            Section {
                ForEach(extraSources) { source in
                    HStack {
                        Image(systemName: source.iconName)
                            .foregroundStyle(Color.accentColor)
                        Text(source.displayTitle)
                            .font(.subheadline)
                        Spacer()
                        Button {
                            extraSources.removeAll { $0.id == source.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    showAddSourcePopover = true
                } label: {
                    Label("Add Date, Pattern or Menu", systemImage: "plus.circle")
                        .font(.subheadline)
                }
                .popover(isPresented: $showAddSourcePopover) {
                    AddSourcePopoverView(
                        allPatterns: allPatterns,
                        allMenus: allMenus,
                        onAdd: { newSource in
                            if !extraSources.contains(where: { $0.id == newSource.id }) {
                                extraSources.append(newSource)
                            }
                            showAddSourcePopover = false
                        }
                    )
                    .presentationCompactAdaptation(.popover)
                }
            } header: {
                Text("Extra Additions")
            }
        }
        .navigationTitle("Shopping List Setup")
        .onAppear {
            if selectedPatternID == nil {
                selectedPatternID = activePattern?.id ?? allPatterns.first?.id
            }
            resetEnabledDays()
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                ShoppingListView(config: currentConfig)
            } label: {
                HStack {
                    Image(systemName: "cart.fill")
                    Text("Generate Shopping List")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(.thinMaterial)
        }
    }

    private func resetEnabledDays() {
        if let pattern = selectedPattern {
            enabledDayIndices = Set(0..<pattern.durationDays)
        } else {
            enabledDayIndices.removeAll()
        }
    }
}

// MARK: - Add Source Popover Component
private struct AddSourcePopoverView: View {
    let allPatterns: [KondatePattern]
    let allMenus: [Menu]
    let onAdd: (ExtraSourceItem) -> Void

    @State private var selectedTab: ExtraSourceType = .date
    @State private var selectedDate: Date = Date()
    @State private var selectedPattern: KondatePattern?
    @State private var selectedDayIndex: Int = 0
    @State private var selectedMenu: Menu?

    var body: some View {
        VStack(spacing: 16) {
            Picker("Source Type", selection: $selectedTab) {
                ForEach(ExtraSourceType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            switch selectedTab {
            case .date:
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)

                Button("Add Date Menu") {
                    onAdd(.date(selectedDate))
                }
                .fontWeight(.bold)
                .buttonStyle(.borderedProminent)

            case .pattern:
                if allPatterns.isEmpty {
                    Text("No patterns found").foregroundStyle(.secondary)
                } else {
                    Picker("Select Pattern", selection: $selectedPattern) {
                        Text("Select...").tag(Optional<KondatePattern>.none)
                        ForEach(allPatterns) { p in
                            Text(p.name).tag(Optional(p))
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Add Entire Pattern") {
                        if let p = selectedPattern {
                            onAdd(.pattern(p))
                        }
                    }
                    .disabled(selectedPattern == nil)
                    .fontWeight(.bold)
                    .buttonStyle(.borderedProminent)
                }

            case .patternDay:
                if allPatterns.isEmpty {
                    Text("No patterns found").foregroundStyle(.secondary)
                } else {
                    Picker("Select Pattern", selection: $selectedPattern) {
                        Text("Select...").tag(Optional<KondatePattern>.none)
                        ForEach(allPatterns) { p in
                            Text(p.name).tag(Optional(p))
                        }
                    }
                    .pickerStyle(.menu)

                    if let p = selectedPattern {
                        Picker("Select Day", selection: $selectedDayIndex) {
                            ForEach(0..<p.durationDays, id: \.self) { idx in
                                Text("Day \(idx + 1)").tag(idx)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)

                        Button("Add Day") {
                            if let day = p.days.first(where: { $0.dayIndex == selectedDayIndex }) {
                                onAdd(.patternDay(patternName: p.name, dayIndex: selectedDayIndex, day: day))
                            }
                        }
                        .fontWeight(.bold)
                        .buttonStyle(.borderedProminent)
                    }
                }

            case .menu:
                if allMenus.isEmpty {
                    Text("No menus found").foregroundStyle(.secondary)
                } else {
                    Picker("Select Menu", selection: $selectedMenu) {
                        Text("Select...").tag(Optional<Menu>.none)
                        ForEach(allMenus) { m in
                            Text(m.name).tag(Optional(m))
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Add Single Menu") {
                        if let m = selectedMenu {
                            onAdd(.menu(m))
                        }
                    }
                    .disabled(selectedMenu == nil)
                    .fontWeight(.bold)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self,
        configurations: config
    )
    let context = container.mainContext

    // 1. Create Patterns
    let pattern1 = KondatePattern(name: "Standard Weekly Plan", durationDays: 7, isActive: true, queueOrder: 0)
    let pattern2 = KondatePattern(name: "Low Carb Weekend", durationDays: 3, isActive: false, queueOrder: 1)
    context.insert(pattern1)
    context.insert(pattern2)

    // 2. Create Ingredients & Menus
    let ingPork = Ingredient(name: "Pork Belly", quantity: 250, unit: "g", category: .meatAndFish)
    let ingCabbage = Ingredient(name: "Cabbage", quantity: 0.5, unit: "head", category: .produce)
    let ingMiso = Ingredient(name: "Miso Paste", quantity: 2, unit: "tbsp", category: .pantryAndGrain)
    
    let menuStirFry = Menu(name: "Pork & Cabbage Stir-Fry", category: .main)
    menuStirFry.ingredients = [ingPork, ingCabbage, ingMiso]

    let ingSalmon = Ingredient(name: "Salmon Fillet", quantity: 2, unit: "pcs", category: .meatAndFish)
    let ingRice = Ingredient(name: "Rice", quantity: 2, unit: "cups", category: .pantryAndGrain)

    let menuSalmon = Menu(name: "Grilled Salmon Rice", category: .main)
    menuSalmon.ingredients = [ingSalmon, ingRice]

    [menuStirFry, menuSalmon].forEach { context.insert($0) }

    // 3. Create Pattern Days
    let day1 = PatternDay(dayIndex: 0, breakfastMenus: [], lunchMenus: [menuSalmon], dinnerMenus: [menuStirFry])
    day1.pattern = pattern1
    let day2 = PatternDay(dayIndex: 1, breakfastMenus: [], lunchMenus: [menuStirFry], dinnerMenus: [])
    day2.pattern = pattern1

    [day1, day2].forEach { context.insert($0) }

    return NavigationStack {
        ShoppingSetupView()
    }
    .modelContainer(container)
}
