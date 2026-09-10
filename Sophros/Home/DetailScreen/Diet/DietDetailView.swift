//
//  DietDetailView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData

struct DietDetailView: View {
    let card: DashboardCard
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \MealLog.occuredAt, ascending: true)
        ],
        animation: .default
    )
    
    private var mealLogs: FetchedResults<MealLog>

    @FetchRequest(sortDescriptors: [], animation: .default)
    private var nutritionGoals: FetchedResults<NutritionGoal>
    
    @State private var selectedDate = Date()
    @State private var showingAddMeal = false
    @State private var showingCalendar = false
    @State private var showingGoalOnboarding = false
    @State private var calorieInput = "2000"
    @State private var proteinInput = "120"
    @State private var fatInput = "70"
    @State private var carbsInput = "250"
    @State private var fiberInput = "30"
    @State private var sugarInput = "35"

    private var nutritionGoal: NutritionGoal? { nutritionGoals.first }
    private var calorieTarget: Double { nutritionGoal?.calorie ?? 2_000 }
    private var proteinTarget: Double { nutritionGoal?.protein ?? 120 }
    private var carbsTarget: Double { nutritionGoal?.carbs ?? 250 }
    private var fatTarget: Double { nutritionGoal?.fat ?? 70 }
    private var fiberTarget: Double { nutritionGoal?.fiber ?? 30 }
    private var sugarLimit: Double { nutritionGoal?.sugar ?? 35 }
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var todayLogs: [MealLog] {
        mealLogs
            .filter { meal in
                guard
                    meal.kindRaw == "log",
                    let occurredAt = meal.occuredAt
                else {
                    return false
                }

                return calendar.isDate(occurredAt, inSameDayAs: selectedDate)
            }
            .sorted {
                ($0.occuredAt ?? .distantPast) > ($1.occuredAt ?? .distantPast)
            }
    }
    
    private var allItems: [MealItem] {
        todayLogs.flatMap { meal in
            ((meal.items as? Set<MealItem>) ?? [])
        }
    }
    
    private var calories: Double {
        allItems.reduce(0) { $0 + $1.calories }
    }
    
    private var protein: Double {
        allItems.reduce(0) { $0 + $1.protein }
    }
    
    private var carbs: Double {
        allItems.reduce(0) { $0 + $1.carbs }
    }
    
    private var fat: Double {
        allItems.reduce(0) { $0 + $1.fat }
    }
    
    private var fiber: Double {
        allItems.reduce(0) { $0 + $1.fiber }
    }
    
    private var sugar: Double {
        allItems.reduce(0) { $0 + $1.sugar }
    }
    
    private var calorieProgress: Double {
        min(calories / calorieTarget, 1)
    }
    
    var body: some View {
        ZStack {
            Colormanager.baseBackground
                .ignoresSafeArea()
            
            List {
                datePicker
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                NutritionSummaryCard(
                    calories: calories,
                    calorieTarget: calorieTarget,
                    protein: protein,
                    proteinTarget: proteinTarget,
                    carbs: carbs,
                    carbsTarget: carbsTarget,
                    fat: fat,
                    fatTarget: fatTarget,
                    progress: calorieProgress,
                    fiber: fiber,
                    fiberTarget: fiberTarget,
                    sugar: sugar,
                    sugarLimit: sugarLimit
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if todayLogs.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    mealList
                    
                }

                Color.clear
                    .frame(height: 76)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Colormanager.baseBackground)
            
            VStack {
                Spacer()
                Button {
                    showingAddMeal = true
                } label: {
                    Label("Add Meal", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Colormanager.Accent.button)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 20,
                                style: .continuous
                            )
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            
            if showingCalendar {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingCalendar = false
                    }
                
                CalendarOverlay(
                    selectedWeek: $selectedDate,
                    isPresented: $showingCalendar,
                    calendar: calendar
                )
                .padding(20)
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 44)
            }

            if showingGoalOnboarding {
                FeatureOnboardingOverlay(
                    icon: "fork.knife",
                    tint: Colormanager.Diet.apricot,
                    title: "Set your nutrition targets",
                    message: "Set daily targets to make your meal summary useful from day one. You can edit them anytime.",
                    actionTitle: "Save targets",
                    actionEnabled: validNutritionInputs,
                    content: {
                        VStack(spacing: 8) {
                            OnboardingNumericField(title: "Calories", unit: "kcal", placeholder: "2000", value: $calorieInput)
                            HStack(spacing: 8) {
                                OnboardingNumericField(title: "Protein", unit: "g", placeholder: "120", value: $proteinInput)
                                OnboardingNumericField(title: "Carbs", unit: "g", placeholder: "250", value: $carbsInput)
                            }
                            HStack(spacing: 8) {
                                OnboardingNumericField(title: "Fat", unit: "g", placeholder: "70", value: $fatInput)
                                OnboardingNumericField(title: "Fiber", unit: "g", placeholder: "30", value: $fiberInput)
                            }
                            OnboardingNumericField(title: "Sugar limit", unit: "g", placeholder: "35", value: $sugarInput)
                        }
                    },
                    action: saveNutritionGoal
                )
            }
        }
        .navigationTitle("Diet")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: showingCalendar)
        .sheet(isPresented: $showingAddMeal) {
            AddMealView(mealDate: selectedDate)
        }
        .onAppear { showingGoalOnboarding = nutritionGoals.isEmpty }
    }

    private var validNutritionInputs: Bool {
        let values = [calorieInput, proteinInput, fatInput, carbsInput, fiberInput, sugarInput]
        return values.allSatisfy { (Double($0) ?? 0) > 0 }
    }

    private func saveNutritionGoal() {
        guard validNutritionInputs,
              let calorie = Double(calorieInput), let protein = Double(proteinInput),
              let fat = Double(fatInput), let carbs = Double(carbsInput),
              let fiber = Double(fiberInput), let sugar = Double(sugarInput) else { return }
        let goal = NutritionGoal(context: viewContext)
        goal.calorie = calorie
        goal.protein = protein
        goal.fat = fat
        goal.carbs = carbs
        goal.fiber = fiber
        goal.sugar = sugar
        try? viewContext.save()
        showingGoalOnboarding = false
    }
    
    private var datePicker: some View {
        HStack {
            Spacer()
            Button {
                showingCalendar = true
            } label: {
                HStack(spacing: 8) {
                    Text(selectedDate.relativeDisplayText)
                        .font(.headline)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(Colormanager.Typography.primaryText)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Colormanager.card)
                .clipShape(Capsule())
            }
            Spacer()
        }
    }
    
    private var mealList: some View {
        Section {
            ForEach(todayLogs, id: \.objectID) { meal in
                MealLogRow(meal: meal)
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: true
                    ) {
                        Button(role: .destructive) {
                            delete(meal)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowInsets(
                        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                    )
                    .listRowBackground(Colormanager.baseBackground)
            }
        }
        .listRowSeparatorTint(
            Colormanager.Typography.secondaryText.opacity(0.25)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.title2)
                .foregroundStyle(Colormanager.Diet.apricot)
            
            Text("No meals logged")
                .font(.headline)
                .foregroundStyle(Colormanager.Typography.primaryText)
            
            Text("Add your first meal for today.")
                .font(.subheadline)
                .foregroundStyle(Colormanager.Typography.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
    
    private func delete(_ meal: MealLog) {
        viewContext.delete(meal)

        do {
            try viewContext.save()
        } catch {
            // Show your existing error alert here if desired.
        }
    }
    
    private var addMealButton: some View {
        Button {
            showingAddMeal = true
        } label: {
            Label("Add Meal", systemImage: "plus")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Colormanager.Accent.button)
                .clipShape(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
        }
    }
}


private struct NutritionSummaryCard: View {
    let calories: Double
    let calorieTarget: Double
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbsTarget: Double
    let fat: Double
    let fatTarget: Double
    let progress: Double
    let fiber: Double
    let fiberTarget: Double
    let sugar: Double
    let sugarLimit: Double
    
    private var calorieProgress: Double {
        min(calories / max(calorieTarget, 1), 1)
    }
    
    private var caloriesLeft: Double {
        max(calorieTarget - calories, 0)
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 24) {
                CalorieRing(
                    calories: calories,
                    target: calorieTarget,
                    progress: calorieProgress
                )
                
                VStack(spacing: 18) {
                    MacroProgressBar(title: "Fat", value: fat, target: fatTarget)
                    
                    MacroProgressBar(
                        title: "Fiber",
                        value: fiber,
                        target: fiberTarget
                    )
                    
                    MacroProgressBar(
                        title: "Sugar",
                        value: sugar,
                        target: sugarLimit
                    )
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                MacroProgressBar(
                    title: "Protein",
                    value: protein,
                    target: proteinTarget,
                    emphasized: true
                )
                
                Divider()
                    .frame(height: 78)
                
                MacroProgressBar(
                    title: "Carbs",
                    value: carbs,
                    target: carbsTarget,
                    emphasized: true
                )
            }
            
        }
        .padding(20)
        .foregroundStyle(Colormanager.Typography.primaryText)
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
}

private struct CalorieRing: View {
    let calories: Double
    let target: Double
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Colormanager.Typography.secondaryText.opacity(0.16),
                    lineWidth: 13
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Colormanager.Accent.button,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 3) {
                Text(calories, format: .number.precision(.fractionLength(0)))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                
                Text("of \(target, format: .number.precision(.fractionLength(0))) kcal")
                    .font(.caption)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
            }
        }
        .frame(width: 155, height: 155)
    }
}

private struct MacroProgressBar: View {
    let title: String
    let value: Double
    let target: Double
    var emphasized = false
    
    private var progress: Double {
        min(value / max(target, 1), 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: emphasized ? 10 : 7) {
            HStack {
                Text(title)
                    .font(
                        emphasized
                        ? .subheadline.weight(.bold)
                        : .subheadline.weight(.semibold)
                    )
                
                Spacer()
                
                Text(
                    "\(value, format: .number.precision(.fractionLength(0))) / \(target, format: .number.precision(.fractionLength(0)))g"
                )
                .font(
                    emphasized
                    ? .subheadline.weight(.bold)
                    : .caption.weight(.medium)
                )
                .foregroundStyle(
                    emphasized
                    ? Colormanager.Typography.primaryText
                    : Colormanager.Typography.secondaryText
                )
            }
            
            ProgressView(value: progress)
                .tint(Colormanager.Accent.button)
                .scaleEffect(y: emphasized ? 1.7 : 1.25)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MacroProgress: View {
    let title: String
    let value: Double
    let target: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Colormanager.Typography.secondaryText)
            
            Text("\(value, format: .number.precision(.fractionLength(0)))g / \(target, format: .number.precision(.fractionLength(0)))g")
                .font(.subheadline.weight(.bold))
        }
    }
}

private struct MealLogRow: View {
    let meal: MealLog
    
    private var items: [MealItem] {
        ((meal.items as? Set<MealItem>) ?? [])
            .sorted {
                ($0.createdAt ?? .distantPast) <
                    ($1.createdAt ?? .distantPast)
            }
    }
    
    private var calories: Double {
        items.reduce(0) { $0 + $1.calories }
    }
    
    private var subtitle: String {
        items.map { $0.name ?? "Food item" }
            .joined(separator: ", ")
    }
    
    private var icon: String {
        switch meal.mealType {
        case .breakfast: "cup.and.saucer.fill"
        case .lunch: "fork.knife"
        case .dinner: "takeoutbag.and.cup.and.straw.fill"
        case .snack: "leaf.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(Colormanager.Diet.apricot)
                .frame(width: 38, height: 38)
                .background(Colormanager.Diet.softPeach)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.mealTypeRaw?.capitalized ?? "Meal")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Colormanager.Typography.primaryText)
                
                Text(meal.title ?? subtitle)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
            }
            
            Spacer()
            
            Text("\(calories, format: .number.precision(.fractionLength(0))) Cal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Colormanager.Typography.primaryText)
        }
        .padding()
    }
}


#Preview {
    DietDetailView(card: DashboardCard.cards[2])
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
