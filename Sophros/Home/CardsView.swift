//
//  CardsView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData
import Foundation

struct CardsView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @FetchRequest(sortDescriptors: [], animation: .default)
    private var waterGoals: FetchedResults<WaterGoal>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WaterEntry.createdAt, ascending: false)],
        animation: .default
    )
    private var waterEntries: FetchedResults<WaterEntry>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutSession.completedAt, ascending: false)],
        animation: .default
    )
    private var workoutSessions: FetchedResults<WorkoutSession>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MealLog.occuredAt, ascending: false)],
        animation: .default
    )
    private var mealLogs: FetchedResults<MealLog>

    @FetchRequest(sortDescriptors: [], animation: .default)
    private var nutritionGoals: FetchedResults<NutritionGoal>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Reminder.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Reminder.createdAt, ascending: true)
        ],
        predicate: NSPredicate(format: "completedAt == nil"),
        animation: .default
    )
    private var upcomingReminders: FetchedResults<Reminder>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeightEntry.createdAt, ascending: false)],
        animation: .default
    )
    private var weightEntries: FetchedResults<WeightEntry>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CycleSettings.createdAt, ascending: true)],
        animation: .default
    )
    private var cycleSettings: FetchedResults<CycleSettings>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CycleLog.date, ascending: true)],
        animation: .default
    )
    private var cycleLogs: FetchedResults<CycleLog>

    private var calendar: Calendar { .current }

    private var primaryCards: [DashboardCard] {
        [waterCard, workoutCard, weightCard, remindersCard]
    }

    private var secondaryCards: [DashboardCard] {
        [dietCard, cycleCard]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 2 x 3
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(primaryCards) { card in
                            NavigationLink {
                                Navigator.openCardView(for: card)
                            } label: {
                                DashboardCardView(card: card, height: geometry.size.height / 4)
                            }
                            
                        }
                    }
                    
                    // 1 x 2
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(secondaryCards) { card in
                            NavigationLink {
                                Navigator.openCardView(for: card)
                            } label: {
                                DashboardCardView(card: card, height: geometry.size.height / 4)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var waterCard: DashboardCard {
        guard let goal = waterGoals.first, goal.amountML > 0 else {
            return card(
                .water,
                value: "Goal not configured",
                subtitle: "Set your daily goal"
            )
        }

        let consumed = waterEntries
            .filter { entry in
                guard let createdAt = entry.createdAt else { return false }
                return calendar.isDateInToday(createdAt)
            }
            .reduce(Int64(0)) { $0 + $1.amountML }
        let progress = min(Double(consumed) / Double(goal.amountML), 1)

        return card(
            .water,
            value: "\(waterAmount(consumed)) / \(waterAmount(goal.amountML))",
            subtitle: "\(Int((Double(consumed) / Double(goal.amountML)) * 100))%",
            progress: progress
        )
    }

    private var workoutCard: DashboardCard {
        guard let workout = workoutSessions.first(where: { $0.completedAt != nil }) else {
            return card(.workout, value: "No workout today", subtitle: "Plan workout")
        }

        let exercises = ((workout.entries as? Set<WorkoutEntry>) ?? [])
            .compactMap(\.name)
            .sorted()
		let exerciseStr = exercises.count > 1 ? "Exercises" : "Exercise"
        let exerciseSummary = exercises.isEmpty
            ? "No exercises logged"
            : "\(exercises.count) \(exerciseStr)"

        return card(
            .workout,
            value: workout.title ?? "Workout",
            subtitle: exerciseSummary
        )
    }

    private var dietCard: DashboardCard {
        let mealsToday = mealLogs.filter { meal in
            guard meal.kind == .log, let occurredAt = meal.occuredAt else { return false }
            return calendar.isDateInToday(occurredAt)
        }
        let calories = mealsToday
            .flatMap { ($0.items as? Set<MealItem>) ?? [] }
            .reduce(0.0) { $0 + $1.calories }

        guard !mealsToday.isEmpty else {
            return card(.diet, value: "Nothing logged", subtitle: "Log your first meal")
        }

        if let goal = nutritionGoals.first, goal.calorie > 0 {
            return card(
                .diet,
                value: "\(wholeNumber(calories)) / \(wholeNumber(goal.calorie)) kcal",
                subtitle: "Calories",
                progress: min(calories / goal.calorie, 1)
            )
        }

        return card(
            .diet,
            value: "\(wholeNumber(calories)) kcal",
            subtitle: "Calories"
        )
    }

    private var remindersCard: DashboardCard {
        guard !upcomingReminders.isEmpty else {
            return card(.reminders, value: "No reminders yet", subtitle: "Add reminder")
        }

        return card(
            .reminders,
            value: "\(upcomingReminders.count)",
            subtitle: "upcoimng"
        )
    }

    private var weightCard: DashboardCard {
        guard let entry = weightEntries.first else {
            return card(.weight, value: "No weight recorded", subtitle: "Add weight")
        }

        return card(
            .weight,
            value: "\(oneDecimalNumber(entry.weight)) kg",
            subtitle: ""
        )
    }

    private var cycleCard: DashboardCard {
        let settings = cycleSettings.first
        guard settings != nil || !cycleLogs.isEmpty else {
            return card(.cycle, value: "Cycle not configured", subtitle: "Get started")
        }

        let logs = cycleLogs.compactMap { log -> CycleLogSnapshot? in
            guard let date = log.date else { return nil }
            let symptoms = (log.symptoms as? Set<CycleSymptom>)?
                .compactMap(\.symptomKey)
                .sorted() ?? []
            return CycleLogSnapshot(date: date, isPeriodDay: log.isPeriodDay, symptomKeys: symptoms)
        }
        let engine = CycleEngine(
            logs: logs,
            settings: CycleSettingsSnapshot(
                cycleLength: Int(settings?.cycleLength ?? 28),
                periodLength: Int(settings?.periodLength ?? 5)
            )
        )
        let status = engine.status(for: .now)

        guard let cycleDay = status.cycleDay, let phase = status.phase else {
            return card(.cycle, value: "Cycle not configured", subtitle: "Start tracking")
        }

        return card(.cycle, value: "Day \(cycleDay)", subtitle: phase.title)
    }

    private func card(
        _ type: DashboardCardType,
        value: String,
        subtitle: String,
        progress: Double? = nil
    ) -> DashboardCard {
        switch type {
        case .water:
            DashboardCard(type: type, icon: "waterbottle.fill", iconColor: .blue, title: "Water", value: value, subtitle: subtitle, progress: progress)
        case .workout:
            DashboardCard(type: type, icon: "figure.strengthtraining.traditional", iconColor: Colormanager.Workout.terracotta, title: "Workout", value: value, subtitle: subtitle, progress: progress)
        case .diet:
            DashboardCard(type: type, icon: "fork.knife", iconColor: .orange, title: "Diet", value: value, subtitle: subtitle, progress: progress)
        case .reminders:
            DashboardCard(type: type, icon: "calendar", iconColor: Colormanager.Reminder.periwinkle, title: "Reminders", value: value, subtitle: subtitle, progress: progress)
        case .weight:
            DashboardCard(type: type, icon: "scalemass.fill", iconColor: Colormanager.Calendar.green, title: "Weight", value: value, subtitle: subtitle, progress: progress)
        case .cycle:
            DashboardCard(type: type, icon: "drop.fill", iconColor: .red, title: "Cycle", value: value, subtitle: subtitle, progress: progress)
        }
    }

    private func waterAmount(_ milliliters: Int64) -> String {
        String(format: "%.1f L", Double(milliliters) / 1_000)
    }

    private func wholeNumber(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    private func oneDecimalNumber(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}


struct DashboardCardView: View {
    let card: DashboardCard
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: card.icon)
                .font(.headline)
                .foregroundStyle(card.iconColor)
                .frame(width: 34, height: 34)
                .background(card.iconColor.opacity(0.12))
                .clipShape(Circle())
            
            Spacer(minLength: 0)
            
            Text(card.title)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Colormanager.Typography.primaryText)
            
            Text(card.value)
                .font(.headline)
                .foregroundStyle(Colormanager.Typography.primaryText)
            
            if let progress = card.progress {
                ProgressView(value: progress)
                    .tint(card.iconColor)
                
                Text(card.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(card.iconColor)
            } else {
                Text(card.subtitle)
                    .font(.caption)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .padding(14)
        .background(Colormanager.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}
