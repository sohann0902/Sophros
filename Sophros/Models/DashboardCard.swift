//
//  DashboardCard.swift
//  Sophros
//
//  Created by Sohan Maurya on 06/08/26.
//


import SwiftUI

enum DashboardCardType {
    case water, workout, diet, sleep, cycle, reminders
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
        .init(type: .water, icon: "drop.fill", iconColor: .blue,
              title: "Water", value: "1.8 / 2.5 L",
              subtitle: "72%", progress: 0.72),
        
            .init(type: .workout, icon: "figure.run", iconColor: .green,
                  title: "Workout", value: "Push Day",
                  subtitle: "5 Exercises"),
        
            .init(type: .diet, icon: "sun.max.fill", iconColor: .orange,
                  title: "Diet", value: "1,720 / 2,000",
                  subtitle: "Calories"),
        
            .init(type: .sleep, icon: "moon.fill", iconColor: .purple,
                  title: "Sleep", value: "7h 15m",
                  subtitle: "Last Night"),
        
            .init(type: .cycle, icon: "flame.fill", iconColor: .red,
                  title: "Cycle", value: "Day 5",
                  subtitle: "Follicular Phase"),
        
            .init(type: .reminders, icon: "calendar", iconColor: .orange,
                  title: "Reminders", value: "3",
                  subtitle: "Upcoming")
    ]
}

