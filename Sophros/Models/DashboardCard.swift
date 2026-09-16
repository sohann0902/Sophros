//
//  DashboardCard.swift
//  Sophros
//
//  Created by Sohan Maurya on 06/08/26.
//


import SwiftUI

enum DashboardCardType {
    case water, diet, workout, reminders, cycle, weight
}

struct DashboardCard: Identifiable {
    let id = UUID()
    let type: DashboardCardType
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    var progress: Double? = nil
    
    static let cards : [DashboardCard] = [
        .init(type: .water, icon: "waterbottle.fill", iconColor: .blue,
              title: "Water", value: "1.8 / 2.5 L",
              subtitle: "72%", progress: 0.72),
        
            .init(type: .workout, icon: "figure.strengthtraining.traditional", iconColor: Colormanager.Workout.terracotta,
                  title: "Workout", value: "Push Day",
                  subtitle: "5 Exercises"),
        
            .init(type: .diet, icon: "fork.knife", iconColor: .orange,
                  title: "Diet", value: "1,720 / 2,000",
                  subtitle: "Calories"),
        
            .init(type: .reminders, icon: "calendar", iconColor: Colormanager.Reminder.periwinkle,
                  title: "Reminders", value: "3",
                  subtitle: "Upcoming")
    ]
    
    static let otherCards : [DashboardCard] = [
        .init(type: .weight, icon: "scalemass.fill", iconColor: Colormanager.Calendar.green,
              title: "Weight", value: "58kg",
              subtitle: ""),
        
            .init(type: .cycle, icon: "drop.fill", iconColor: .red,
                  title: "Cycle", value: "Day 5",
                  subtitle: "Follicular Phase"),
        
    ]
}

