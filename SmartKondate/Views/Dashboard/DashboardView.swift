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
    
    @Query(filter: #Predicate<KondatePattern> { $0.isActive }) private var activePatterns: [KondatePattern]
    @Query(sort: \Menu.name) private var availableMenus: [Menu]

    @State private var selectedDate: Date = Date()

    // ユーザーによる本日の単体差し替え用一時ステート
    @State private var customBreakfast: Menu?
    @State private var customLunch: Menu?
    @State private var customDinner: Menu?

    private var activePattern: KondatePattern? {
        activePatterns.first
    }

    private var diffResults: [MealDiffResult] {
        DiffCalculator.calculateDiff(
            for: selectedDate,
            pattern: activePattern,
            startDate: activePattern?.createdAt ?? Date(),
            customBreakfast: customBreakfast,
            customLunch: customLunch,
            customDinner: customDinner
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 日付選択 & パターン情報ヘッダー
                VStack(spacing: 8) {
                    DatePicker(
                        "Target Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()

                    if let pattern = activePattern {
                        let dayIndex = DiffCalculator.calculateDayIndex(
                            for: selectedDate,
                            startDate: pattern.createdAt,
                            durationDays: pattern.durationDays
                        )
                        Text("Active Pattern: \(pattern.name) (Day \(dayIndex + 1)/\(pattern.durationDays))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No active pattern selected")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 各食のカード
                ForEach(diffResults, id: \.mealType) { result in
                    MealCardView(
                        diffResult: result,
                        availableMenus: availableMenus,
                        onSelectMenu: { newMenu in
                            updateCustomMenu(for: result.mealType, with: newMenu)
                        }
                    )
                }

                // 買い物リストへのナビゲーションボタン
                NavigationLink(destination: StockCheckListView()) {
                    HStack {
                        Image(systemName: "cart.fill")
                            .font(.title3)
                        Text("Go to Stock Checklist")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Today's Menu")
    }

    private func updateCustomMenu(for mealType: MealType, with menu: Menu?) {
        switch mealType {
        case .breakfast:
            customBreakfast = menu
        case .lunch:
            customLunch = menu
        case .dinner:
            customDinner = menu
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self], inMemory: true)
}
