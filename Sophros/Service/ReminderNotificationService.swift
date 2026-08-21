//
//  ReminderNotificationService.swift
//  Sophros
//

import Foundation
import UserNotifications

final class ReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge, .list]
    }
    
}

enum ReminderNotificationService {
    private static let identifierPrefix = "reminder-"

    static func cancelNotification(for id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: notificationIdentifiers(for: id)
        )
    }

    static func syncNotification(
        id: UUID,
        title: String,
        dueAt: Date?,
        repeatRule: ReminderRepeatRule,
        isCompleted: Bool
    ) {
        cancelNotification(for: id)

        guard
            let dueAt,
            !isCompleted,
            repeatRule != .never || dueAt > .now
        else {
            return
        }

        Task {
            let center = UNUserNotificationCenter.current()
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

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = ""
            content.sound = .default

            do {
                for request in notificationRequests(
                    id: id,
                    content: content,
                    dueAt: dueAt,
                    repeatRule: repeatRule
                ) {
                    try await center.add(request)
                }
            } catch {
                print("Could not schedule reminder notification: \(error.localizedDescription)")
            }
        }
    }

    private static func notificationRequests(
        id: UUID,
        content: UNMutableNotificationContent,
        dueAt: Date,
        repeatRule: ReminderRepeatRule
    ) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: dueAt)

        func request(
            identifier: String,
            components: DateComponents,
            repeats: Bool
        ) -> UNNotificationRequest {
            UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: repeats
                )
            )
        }

        switch repeatRule {
        case .never:
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueAt
            )
            return [request(
                identifier: notificationIdentifier(for: id),
                components: components,
                repeats: false
            )]

        case .hourly:
            return [request(
                identifier: notificationIdentifier(for: id),
                components: calendar.dateComponents([.minute], from: dueAt),
                repeats: true
            )]

        case .daily:
            return [request(
                identifier: notificationIdentifier(for: id),
                components: time,
                repeats: true
            )]

        case .weekdays:
            return (2...6).map { weekday in
                var components = time
                components.weekday = weekday
                return request(
                    identifier: weekdayNotificationIdentifier(for: id, weekday: weekday),
                    components: components,
                    repeats: true
                )
            }

        case .weekly:
            var components = time
            components.weekday = calendar.component(.weekday, from: dueAt)
            return [request(
                identifier: notificationIdentifier(for: id),
                components: components,
                repeats: true
            )]

        case .monthly:
            var components = time
            components.day = calendar.component(.day, from: dueAt)
            return [request(
                identifier: notificationIdentifier(for: id),
                components: components,
                repeats: true
            )]

        case .yearly:
            var components = time
            components.month = calendar.component(.month, from: dueAt)
            components.day = calendar.component(.day, from: dueAt)
            return [request(
                identifier: notificationIdentifier(for: id),
                components: components,
                repeats: true
            )]
        }
    }

    private static func notificationIdentifiers(for id: UUID) -> [String] {
        [notificationIdentifier(for: id)] + (2...6).map {
            weekdayNotificationIdentifier(for: id, weekday: $0)
        }
    }

    private static func notificationIdentifier(for id: UUID) -> String {
        identifierPrefix + id.uuidString
    }

    private static func weekdayNotificationIdentifier(for id: UUID, weekday: Int) -> String {
        notificationIdentifier(for: id) + "-weekday-\(weekday)"
    }
}
