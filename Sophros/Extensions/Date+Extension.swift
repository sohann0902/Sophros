//
//  Date+Extension.swift
//  Sophros
//
//  Created by Sohan Maurya on 19/08/26.
//


import Foundation

extension Date {
    var relativeDisplayText: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "Today"
        }

        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }

        let day = calendar.component(.day, from: self)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"

        return "\(day)\(day.ordinalSuffix) \(formatter.string(from: self))"
    }
}


