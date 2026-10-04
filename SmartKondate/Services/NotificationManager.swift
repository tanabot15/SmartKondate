//
//  NotificationManager.swift
//  SmartKondate
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    /// 通知権限を要求
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// 次回パターンの切り替え前に通知をスケジュール
    func scheduleNextPatternReminder(
        activePattern: KondatePattern?,
        daysBefore: Int,
        notificationHour: Int
    ) {
        cancelAllReminders()

        guard let pattern = activePattern, let startDate = pattern.startDate else { return }

        // 次回パターン開始日 = startDate + durationDays
        let calendar = Calendar.current
        guard let nextStartDate = calendar.date(byAdding: .day, value: pattern.durationDays, to: startDate) else { return }

        // リマインド日 = nextStartDate - daysBefore
        guard let targetDate = calendar.date(byAdding: .day, value: -daysBefore, to: nextStartDate) else { return }

        var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        components.hour = notificationHour
        components.minute = 0

        guard let scheduledDate = calendar.date(from: components), scheduledDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Meal Pattern"
        if daysBefore == 0 {
            content.body = "A new meal pattern '\(pattern.name)' starts today! Check your menus and grocery list."
        } else {
            content.body = "New pattern starts in \(daysBefore) day\(daysBefore > 1 ? "s" : ""). Get ready with your grocery list!"
        }
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "next_pattern_switch_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    /// 既存のリマインダーをクリア
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["next_pattern_switch_reminder"]
        )
    }
}
