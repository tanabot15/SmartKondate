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
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Header
            HStack {
                Image(systemName: "fork.knife")
                    .font(.caption)
                    .foregroundStyle(.orange)
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

            // MARK: - Meal List
            VStack(alignment: .leading, spacing: 6) {
                mealRow(label: "B", icon: "sun.max.fill", color: .orange, menuName: entry.breakfast)
                mealRow(label: "L", icon: "sun.min.fill", color: .yellow, menuName: entry.lunch)
                mealRow(label: "D", icon: "moon.fill", color: .indigo, menuName: entry.dinner)
            }
            
            Spacer(minLength: 0)
        }
        .padding()
    }

    @ViewBuilder
    private func mealRow(label: String, icon: String, color: Color, menuName: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
                .frame(width: 14)
            
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text(menuName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
}

#Preview(as: .systemMedium) {
    SmartKondateWidget()
} timeline: {
    SimpleKondateEntry(
        date: Date(),
        patternName: "Weekly Rotation",
        dayText: "Day 3",
        breakfast: "Japanese Breakfast",
        lunch: "Chicken Nanban",
        dinner: "Grilled Pork"
    )
}
