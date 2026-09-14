//
//  WaterReminderNotificationService.swift
//  Sophros
//
//  Created by Sohan Maurya on 12/09/26.
//


import Foundation
import UserNotifications

/// Schedules hydration prompts separately from the user's general reminders.
enum WaterReminderNotificationService {
    private static let identifierPrefix = "water-reminder-"

    static func sync(intervalHours: Int, from startTime: Date, to endTime: Date) {
        Task {
            let center = UNUserNotificationCenter.current()
            await cancelPendingRequests(in: center)

            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined:
                guard (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) == true else {
                    return
                }
            case .authorized, .provisional, .ephemeral:
                break
            default:
                return
            }

            let calendar = Calendar.current
            let startMinutes = minutesSinceMidnight(for: startTime, calendar: calendar)
            let endMinutes = minutesSinceMidnight(for: endTime, calendar: calendar)
            guard intervalHours > 0, startMinutes < endMinutes else { return }

            let content = UNMutableNotificationContent()
            content.title = "Time to drink water 💧"
            content.body = "Take a moment to hydrate."
            content.sound = .default

            for minuteOfDay in stride(from: startMinutes, through: endMinutes, by: intervalHours * 60) {
                var components = DateComponents()
                components.hour = minuteOfDay / 60
                components.minute = minuteOfDay % 60

                let request = UNNotificationRequest(
                    identifier: identifier(for: minuteOfDay),
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                )

                do {
                    try await center.add(request)
                } catch {
                    print("Could not schedule water reminder: \(error.localizedDescription)")
                }
            }
        }
    }

    static func cancel() {
        Task {
            await cancelPendingRequests(in: UNUserNotificationCenter.current())
        }
    }

    private static func cancelPendingRequests(in center: UNUserNotificationCenter) async {
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func minutesSinceMidnight(for date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private static func identifier(for minuteOfDay: Int) -> String {
        identifierPrefix + String(minuteOfDay)
    }
}
