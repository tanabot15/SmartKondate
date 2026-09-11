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
    
    @Query(sort: \KondatePattern.queueOrder) private var allPatterns: [KondatePattern]
    @Query(sort: \Menu.name) private var availableMenus: [Menu]

    @AppStorage("isQueueLoopEnabled") private var isQueueLoopEnabled: Bool = false

    @State private var customMenuDict: [String: [Menu]] = [:]

    private var queuedPatterns: [KondatePattern] {
        allPatterns
            .filter { $0.queueOrder != nil }
            .sorted { ($0.queueOrder ?? 0) < ($1.queueOrder ?? 0) }
    }

    // パターンの累計日数から開始日を安全に計算するヘルパー
    private func startDate(for patternIndex: Int) -> Date {
        let baseStartDate = queuedPatterns.first?.startDate ?? Date()
        let offsetDays = queuedPatterns.prefix(patternIndex).reduce(0) { $0 + $1.durationDays }
        return Calendar.current.date(byAdding: .day, value: offsetDays, to: baseStartDate) ?? baseStartDate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if queuedPatterns.isEmpty {
                    ContentUnavailableView {
                        Label("No Scheduled Patterns", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("Please add patterns to the Queue in the Patterns tab.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(Array(queuedPatterns.enumerated()), id: \.element.id) { index, pattern in
                        let patternStartDate = startDate(for: index)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // MARK: - Pattern Section Header
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(pattern.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)

                                    if index == 0 {
                                        Text("Now Active")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.accentColor)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                    } else {
                                        Text("Queue #\(index)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.secondary.opacity(0.2))
                                            .foregroundStyle(.secondary)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text("\(pattern.durationDays) Days Cycle")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // MARK: - Days List in Pattern
                            ForEach(0..<pattern.durationDays, id: \.self) { dayIndex in
                                let date = Calendar.current.date(byAdding: .day, value: dayIndex, to: patternStartDate) ?? patternStartDate
                                let diffResults = getDiffResults(for: date, dayIndex: dayIndex, pattern: pattern)

                                MealCardView(
                                    dayIndex: dayIndex,
                                    date: date,
                                    diffResults: diffResults,
                                    availableMenus: availableMenus,
                                    onSelectMenus: { mealType, newMenus in
                                        updateCustomMenus(patternID: pattern.id, dayIndex: dayIndex, mealType: mealType, with: newMenus)
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pattern Dashboard")
        .onAppear {
            checkAndAdvanceQueue()
        }
    }

    private func getDiffResults(for date: Date, dayIndex: Int, pattern: KondatePattern) -> [MealDiffResult] {
        let breakfast = customMenuDict["\(pattern.id)_\(dayIndex)_\(MealType.breakfast.rawValue)"]
        let lunch = customMenuDict["\(pattern.id)_\(dayIndex)_\(MealType.lunch.rawValue)"]
        let dinner = customMenuDict["\(pattern.id)_\(dayIndex)_\(MealType.dinner.rawValue)"]

        return DiffCalculator.calculateDiff(
            for: date,
            pattern: pattern,
            startDate: pattern.startDate ?? pattern.createdAt,
            customBreakfast: breakfast,
            customLunch: lunch,
            customDinner: dinner
        )
    }

    private func updateCustomMenus(patternID: UUID, dayIndex: Int, mealType: MealType, with menus: [Menu]?) {
        let key = "\(patternID)_\(dayIndex)_\(mealType.rawValue)"
        if let menus = menus {
            customMenuDict[key] = menus
        } else {
            customMenuDict.removeValue(forKey: key)
        }
    }

    private func checkAndAdvanceQueue() {
        var queued = queuedPatterns
        guard let current = queued.first, let startDate = current.startDate else { return }

        let calendar = Calendar.current
        let daysPassed = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: Date())).day ?? 0

        if daysPassed >= current.durationDays {
            let finishedPattern = queued.removeFirst()

            if isQueueLoopEnabled {
                queued.append(finishedPattern)
            } else {
                finishedPattern.queueOrder = nil
                finishedPattern.isActive = false
                finishedPattern.startDate = nil
            }

            let nextStartDate = calendar.date(byAdding: .day, value: current.durationDays, to: startDate) ?? Date()

            for (index, p) in queued.enumerated() {
                p.queueOrder = index
                p.isActive = (index == 0)
                if index == 0 {
                    p.startDate = nextStartDate
                }
            }
        }
    }
}

#Preview {
    @MainActor
    func createPreviewContainer() -> ModelContainer {
        let schema = Schema([
            KondatePattern.self,
            PatternDay.self,
            Menu.self,
            Ingredient.self,
            StockItem.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let ingBread = Ingredient(name: "Bread", quantity: 2, unit: "slices")
        let ingEgg = Ingredient(name: "Egg", quantity: 2, unit: "pcs")
        let ingChicken = Ingredient(name: "Chicken Thigh", quantity: 300, unit: "g")
        let ingRice = Ingredient(name: "Rice", quantity: 1, unit: "bowl")
        let ingOnion = Ingredient(name: "Onion", quantity: 1, unit: "pc")

        let stockBread = StockItem(name: "Bread", category: "Pantry")
        let stockEgg = StockItem(name: "Egg", category: "Fridge")

        context.insert(stockBread)
        context.insert(stockEgg)

        let menuToast = Menu(name: "Toast & Fried Eggs", category: "Breakfast", source: "Cookbook p.12")
        menuToast.ingredients = [ingBread, ingEgg]

        let menuTeriyaki = Menu(name: "Chicken Teriyaki Bowl", category: "Main", source: "https://example.com/teriyaki")
        menuTeriyaki.ingredients = [ingChicken, ingRice]

        let menuCurry = Menu(name: "Japanese Curry", category: "Main", source: "Family Recipe")
        menuCurry.ingredients = [ingChicken, ingOnion]

        context.insert(menuToast)
        context.insert(menuTeriyaki)
        context.insert(menuCurry)

        let pattern1 = KondatePattern(
            name: "Standard Weekly",
            durationDays: 3,
            isActive: true,
            queueOrder: 0,
            startDate: Date()
        )
        
        let pattern2 = KondatePattern(
            name: "Healthy Weekend",
            durationDays: 2,
            isActive: false,
            queueOrder: 1,
            startDate: nil
        )

        context.insert(pattern1)
        context.insert(pattern2)

        let day1 = PatternDay(dayIndex: 0, breakfastMenus: [menuToast], lunchMenus: [menuTeriyaki], dinnerMenus: [menuCurry])
        day1.pattern = pattern1

        let day2 = PatternDay(dayIndex: 1, breakfastMenus: [menuToast], lunchMenus: [], dinnerMenus: [menuTeriyaki])
        day2.pattern = pattern1

        let day3 = PatternDay(dayIndex: 2, breakfastMenus: [], lunchMenus: [menuCurry], dinnerMenus: [])
        day3.pattern = pattern1

        let p2Day1 = PatternDay(dayIndex: 0, breakfastMenus: [menuToast], lunchMenus: [menuCurry], dinnerMenus: [])
        p2Day1.pattern = pattern2

        return container
    }

    return NavigationStack {
        DashboardView()
    }
    .modelContainer(createPreviewContainer())
}
