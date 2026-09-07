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
                    let baseStartDate = queuedPatterns.first?.startDate ?? Date()
                    var currentPatternStartDate = baseStartDate

                    ForEach(Array(queuedPatterns.enumerated()), id: \.element.id) { index, pattern in
                        let patternStartDate = currentPatternStartDate
                        
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

                        let _ = {
                            currentPatternStartDate = Calendar.current.date(byAdding: .day, value: pattern.durationDays, to: patternStartDate) ?? patternStartDate
                        }()
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self,
        configurations: config
    )

    let context = container.mainContext

    let ing1 = Ingredient(name: "Bread", amount: "2 slices")
    let ing2 = Ingredient(name: "Egg", amount: "2 pcs")
    let ing3 = Ingredient(name: "Chicken Thigh", amount: "150g")

    let menu1 = Menu(name: "Toast & Fried Eggs", category: "Main")
    menu1.ingredients = [ing1, ing2]

    let menu2 = Menu(name: "Chicken Teriyaki Bowl", category: "Main")
    menu2.ingredients = [ing3]

    [menu1, menu2].forEach { context.insert($0) }

    let pattern1 = KondatePattern(
        name: "Standard Weekly",
        durationDays: 3,
        isActive: true,
        queueOrder: 0,
        startDate: Date()
    )
    let pattern2 = KondatePattern(
        name: "Light Cycle",
        durationDays: 2,
        isActive: false,
        queueOrder: 1,
        startDate: nil
    )
    
    [pattern1, pattern2].forEach { context.insert($0) }

    let day1 = PatternDay(dayIndex: 0, breakfastMenus: [menu1], lunchMenus: [menu2], dinnerMenus: [])
    day1.pattern = pattern1
    context.insert(day1)

    return NavigationStack {
        DashboardView()
    }
    .modelContainer(container)
}
