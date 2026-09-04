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
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    SmartKondateWidget()
} timeline: {
    SimpleKondateEntry(
        date: Date(),
        patternName: "Standard Rotation",
        dayText: "Day 1",
        breakfastMain: "Toast & Eggs",
        breakfastSub: "Coffee",
        lunchMain: "Curry Rice",
        lunchSub: "Side Salad",
        dinnerMain: "Steak",
        dinnerSub: "Miso Soup"
    )
}
