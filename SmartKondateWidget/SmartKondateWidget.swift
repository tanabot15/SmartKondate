//
//  SmartKondateWidget.swift
//  SmartKondateWidget
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import WidgetKit
import SwiftUI

struct SmartKondateWidget: Widget {
    let kind: String = "SmartKondateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KondateTimelineProvider()) { entry in
            TodayKondateWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Menu")
        .description("Displays breakfast, lunch, and dinner from your active meal pattern.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    SmartKondateWidget()
} timeline: {
    SimpleKondateEntry(
        date: Date(),
        patternName: "Standard Rotation",
        dayText: "Day 1",
        breakfast: "Toast & Eggs",
        lunch: "Curry Rice",
        dinner: "Steak & Salad"
    )
}
