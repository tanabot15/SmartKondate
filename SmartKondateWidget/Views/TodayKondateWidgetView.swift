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

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(EEE)"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // MARK: - Header
            HStack(alignment: .firstTextBaseline) {
                Text(formattedDate)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(" - ")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.patternName)
                    .font(.caption)
                    .fontWeight(.bold)

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

            // MARK: - Table Header (列見出し)
            HStack(spacing: 8) {
                Text("")
                    .frame(width: 14) // 食事区分 (B, L, D) 用の幅
                
                Text("Main")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Side / Soup / Others")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // MARK: - Table Content (各食事の行)
            VStack(spacing: 4) {
                mealTableRow(label: "B", main: entry.breakfastMain, sub: entry.breakfastSub)
                mealTableRow(label: "L", main: entry.lunchMain, sub: entry.lunchSub)
                mealTableRow(label: "D", main: entry.dinnerMain, sub: entry.dinnerSub)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    @ViewBuilder
    private func mealTableRow(label: String, main: String, sub: String) -> some View {
        HStack(spacing: 8) {
            // header
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 14, alignment: .leading)

            // main
            Text(main.isEmpty ? "-" : main)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // subs
            Text(sub.isEmpty ? "-" : sub)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
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
