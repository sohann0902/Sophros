//
//  Navigator.swift
//  Sophros
//
//  Created by Sohan Maurya on 06/08/26.
//

import SwiftUI

struct Navigator {
    
    @ViewBuilder
    static func openCardView(for card: DashboardCard) -> some View {
        switch card.type {
        case .water:
            WaterDetailView(card: card)
        case .workout:
            WorkoutDetailView(card: card)
        case .diet:
            DietDetailView(card: card)
        case .sleep:
            SleepDetailView(card: card)
        case .cycle:
            CycleDetailView(card: card)
        case .reminders:
            RemindersDetailView(card: card)
        }
    }
}
