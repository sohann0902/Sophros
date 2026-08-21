//
//  ReminderRepeatRule.swift
//  Sophros
//
//  Created by Sohan Maurya on 21/08/26.
//

import Foundation

enum ReminderRepeatRule: String, CaseIterable, Identifiable {
    case never
    case hourly
    case daily
    case weekdays
    case weekly
    case monthly
    case yearly

    var id: Self { self }

    var title: String {
        switch self {
        case .never:
            "Never"
        case .hourly:
            "Hourly"
        case .daily:
            "Daily"
        case .weekdays:
            "Weekdays"
        case .weekly:
            "Weekly"
        case .monthly:
            "Monthly"
        case .yearly:
            "Yearly"
        }
    }
}

extension Reminder {
    var repeatRule: ReminderRepeatRule {
        get {
            ReminderRepeatRule(rawValue: repeatRuleRaw ?? "") ?? .never
        }
        set {
            repeatRuleRaw = newValue.rawValue
        }
    }
}
