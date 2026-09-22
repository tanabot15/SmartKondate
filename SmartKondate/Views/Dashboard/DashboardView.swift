//
//  DashboardView.swift
//  SmartKondate
//

import SwiftUI
import SwiftData
import WidgetKit

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

    private func startDate(for patternIndex: Int) -> Date {
        let baseStartDate = queuedPatterns.first?.startDate ?? Date()
        let offsetDays = queuedPatterns.prefix(patternIndex).reduce(0) { $0 + $1.durationDays }
        return Calendar.current.date(byAdding: .day, value: offsetDays, to: baseStartDate) ?? baseStartDate
    }

    var body: some View {
        Group {
            if queuedPatterns.isEmpty {
                ContentUnavailableView {
                    Label("No Scheduled Patterns", systemImage: "arrow.triangle.2.circlepath")
                } description: {
                    Text("Add patterns to the queue in the Patterns tab.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
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
                                        let diffResults = getDiffResults(for: date, dayIndex: dayIndex, pattern: pattern, patternStartDate: patternStartDate)
                                        let isToday = Calendar.current.isDateInToday(date)

                                        MealCardView(
                                            dayIndex: dayIndex,
                                            date: date,
                                            diffResults: diffResults,
                                            availableMenus: availableMenus,
                                            onSelectMenus: { mealType, newMenus in
                                                updateCustomMenus(patternID: pattern.id, dayIndex: dayIndex, mealType: mealType, with: newMenus)
                                            },
                                            isToday: isToday
                                        )
                                        .id("card_\(pattern.id)_\(dayIndex)")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollToToday(proxy: proxy)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .onAppear {
            checkAndAdvanceQueue()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func scrollToToday(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        for index in 0..<queuedPatterns.count {
            let pattern = queuedPatterns[index]
            let pStartDate = startDate(for: index)
            
            for dayIndex in 0..<pattern.durationDays {
                if let date = calendar.date(byAdding: .day, value: dayIndex, to: pStartDate),
                   calendar.isDateInToday(date) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("card_\(pattern.id)_\(dayIndex)", anchor: .top)
                        }
                    }
                    return
                }
            }
        }
    }

    private func getDiffResults(for date: Date, dayIndex: Int, pattern: KondatePattern, patternStartDate: Date) -> [MealDiffResult] {
        let breakfast = customMenuDict["\(pattern.id)_\(dayIndex)_\(MealType.breakfast.rawValue)"]
        let lunch = customMenuDict["\(pattern.id)_\(dayIndex)_\(MealType.lunch.rawValue)"]
        let dinner = customMenuDict["\(pattern.id)_\(dayIndex)_\(MealType.dinner.rawValue)"]

        return DiffCalculator.calculateDiff(
            for: date,
            pattern: pattern,
            startDate: patternStartDate,
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
        
        if let pattern = queuedPatterns.first(where: { $0.id == patternID }),
           let targetDay = pattern.days.first(where: { $0.dayIndex == dayIndex }) {
            
            let updatedMenus = menus ?? []
            switch mealType {
            case .breakfast:
                targetDay.breakfastMenus = updatedMenus
            case .lunch:
                targetDay.lunchMenus = updatedMenus
            case .dinner:
                targetDay.dinnerMenus = updatedMenus
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to save menu update: \(error)")
            }
        }

        WidgetCenter.shared.reloadAllTimelines()
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
            
            WidgetCenter.shared.reloadAllTimelines()
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

        let menuToast = Menu(name: "Toast & Fried Eggs", category: .main, source: "Cookbook p.12")
        menuToast.ingredients = [ingBread, ingEgg]

        let menuTeriyaki = Menu(name: "Chicken Teriyaki Bowl", category: .main, source: "https://example.com/teriyaki")
        menuTeriyaki.ingredients = [ingChicken]

        context.insert(menuToast)
        context.insert(menuTeriyaki)

        // 今日の日付を起点（Day 2を今日に設定して動作確認可能）
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let pattern1 = KondatePattern(
            name: "Standard Weekly",
            durationDays: 3,
            isActive: true,
            queueOrder: 0,
            startDate: yesterday
        )

        context.insert(pattern1)

        let day1 = PatternDay(dayIndex: 0, breakfastMenus: [menuToast], lunchMenus: [], dinnerMenus: [menuTeriyaki])
        day1.pattern = pattern1

        let day2 = PatternDay(dayIndex: 1, breakfastMenus: [menuToast], lunchMenus: [menuTeriyaki], dinnerMenus: [])
        day2.pattern = pattern1

        let day3 = PatternDay(dayIndex: 2, breakfastMenus: [], lunchMenus: [], dinnerMenus: [menuTeriyaki])
        day3.pattern = pattern1

        return container
    }

    return NavigationStack {
        DashboardView()
    }
    .modelContainer(createPreviewContainer())
}
