//
//  TodayKondateWidgetView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import WidgetKit

struct TodayKondateWidgetView: View {
    var entry: SimpleKondateEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // MARK: - Header
            HStack {
                Text(entry.patternName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Spacer()
                Text(entry.dayText)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }

            Divider()

            // MARK: - Meal List (各食事1行)
            VStack(alignment: .leading, spacing: 6) {
                mealCompactRow(label: "B", main: entry.breakfastMain, sub: entry.breakfastSub)
                mealCompactRow(label: "L", main: entry.lunchMain, sub: entry.lunchSub)
                mealCompactRow(label: "D", main: entry.dinnerMain, sub: entry.dinnerSub)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    @ViewBuilder
    private func mealCompactRow(label: String, main: String, sub: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 12, alignment: .leading)
            
            Text(main.isEmpty ? "No menu" : main)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            if !sub.isEmpty {
                Text("(\(sub))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview("Small", as: .systemSmall) {
    SmartKondateWidget()
} timeline: {
    SimpleKondateEntry(
        date: Date(),
        patternName: "Weekly Rotation",
        dayText: "Day 3",
        breakfastMain: "Toast & Eggs",
        breakfastSub: "Coffee",
        lunchMain: "Chicken Nanban",
        lunchSub: "Rice / Soup",
        dinnerMain: "Grilled Pork",
        dinnerSub: "Salad / Miso Soup"
    )
}

#Preview("Medium", as: .systemMedium) {
    SmartKondateWidget()
} timeline: {
    SimpleKondateEntry(
        date: Date(),
        patternName: "Weekly Rotation",
        dayText: "Day 3",
        breakfastMain: "Toast & Eggs",
        breakfastSub: "Coffee",
        lunchMain: "Chicken Nanban",
        lunchSub: "Rice / Soup",
        dinnerMain: "Grilled Pork",
        dinnerSub: "Salad / Miso Soup"
    )
}
