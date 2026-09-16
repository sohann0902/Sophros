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

	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: true)],
		animation: .default
	)
	private var userProfiles: FetchedResults<UserProfile>
	
	@State private var selectedDate = Date()
	@State private var showingAddMeal = false
	@State private var showingSaveMeal = false
	@State private var showingCalendar = false
	@State private var showingGoalOnboarding = false
	
	private var nutritionGoal: NutritionGoal? { nutritionGoals.first }
	private var userProfile: UserProfile? { userProfiles.first }

	private var calculatedNutritionProfile: NutritionProfile? {
		guard let userProfile, userProfile.age > 0, userProfile.height > 0, userProfile.weight > 0 else {
			return nil
		}

		return NutritionProfile(
			gender: userProfile.gender,
			age: Int(userProfile.age),
			heightCM: userProfile.height,
			weightKG: userProfile.weight,
			activityLevel: userProfile.activityLevel,
			goal: userProfile.nutritionGoal
		)
	}

	private var calculatedTargets: NutritionTargets? {
		guard let calculatedNutritionProfile else { return nil }
		return NutritionCalculator.calculateTargets(profile: calculatedNutritionProfile)
	}
	
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
	
	var body: some View {
		ZStack {
			Colormanager.baseBackground
				.ignoresSafeArea()

			List {
				datePicker
					.listRowBackground(Color.clear)
					.listRowSeparator(.hidden)
				
				if let nutritionGoal {
					NutritionSummaryCard(
						calories: calories,
						calorieTarget: nutritionGoal.calorie,
						protein: protein,
						proteinTarget: nutritionGoal.protein,
						carbs: carbs,
						carbsTarget: nutritionGoal.carbs,
						fat: fat,
						fatTarget: nutritionGoal.fat,
						progress: min(calories / max(nutritionGoal.calorie, 1), 1),
						fiber: fiber,
						fiberTarget: nutritionGoal.fiber,
						sugar: sugar,
						sugarLimit: nutritionGoal.sugar
					)
					.listRowBackground(Color.clear)
					.listRowSeparator(.hidden)
				} else {
					nutritionTargetUnavailable
						.listRowBackground(Color.clear)
						.listRowSeparator(.hidden)
				}
				
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
			
			
			FadeOverlay(isPresented: $showingCalendar) {
				Color.black.opacity(0.25)
					.ignoresSafeArea()
					.onTapGesture {
						showingCalendar = false
					}
				
				CalendarOverlay(
					selectedWeek: .constant(.now),
					isPresented: .constant(true),
					calendar: Calendar.current,
					background: Colormanager.Accent.button,
					tint: Color.black
				)
				.padding(20)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
				.padding(.top, 44)
			}

			FadeOverlay(isPresented: $showingGoalOnboarding) {
				if let calculatedTargets {
					DietOnboardingView(targets: calculatedTargets, action: saveNutritionGoal)
				}
			}

		}
		.navigationTitle("Diet")
		.navigationBarTitleDisplayMode(.inline)
		.animation(.easeInOut(duration: 0.2), value: showingCalendar)
		.animation(.easeInOut(duration: 0.4), value: showingGoalOnboarding)
		.navigationDestination(isPresented: $showingAddMeal) {
			LogMealView(mealDate: selectedDate)
		}
		.sheet(isPresented: $showingSaveMeal) {
			SavedMealsView { _ in
				
			}
		}
		.onAppear {
			showingGoalOnboarding = nutritionGoals.isEmpty && calculatedNutritionProfile != nil
		}
		.toolbar(content: {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					showingSaveMeal = true
				} label: {
					Image(systemName: "bookmark.fill")
				}
				.foregroundStyle(Colormanager.Accent.button)
			}
		})
	}

	private func saveNutritionGoal() {
		guard let calculatedNutritionProfile else { return }

		let _ = NutritionCalculator.createGoal(profile: calculatedNutritionProfile, context: viewContext)

		do {
			try viewContext.save()
			showingGoalOnboarding = false
		} catch {
			print("Failed to save nutrition target: \(error)")
		}
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

	private var nutritionTargetUnavailable: some View {
		VStack(spacing: 10) {
			Image(systemName: "chart.bar.doc.horizontal")
				.font(.title2)
				.foregroundStyle(Colormanager.Diet.apricot)

			Text("Nutrition targets unavailable")
				.font(.headline)
				.foregroundStyle(Colormanager.Typography.primaryText)

			Text("Complete onboarding to calculate your personalized daily targets.")
				.font(.subheadline)
				.multilineTextAlignment(.center)
				.foregroundStyle(Colormanager.Typography.secondaryText)
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 32)
		.padding(.horizontal)
		.background(Colormanager.card)
		.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
//	DietDetailView(card: DashboardCard.cards[2])
//		.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	
	CalendarOverlay(
		selectedWeek: .constant(.now),
		isPresented: .constant(true),
		calendar: Calendar.current,
		background: Colormanager.Accent.button.opacity(0.5),
		tint: Color.black
	)
	.padding(20)
	.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
	.padding(.top, 44)
}

struct DietOnboardingView: View {
	let targets: NutritionTargets
	var action: () -> Void

	var body: some View {
		ZStack {
			Colormanager.Diet.cream.ignoresSafeArea()

			VStack {
				Text("")

				Text("We have estimated target nutrients for you to make your meal summary useful from day one. You can edit them anytime in settings.")
					.multilineTextAlignment(.center)
					.font(.system(.headline))

				Spacer()
				Spacer()

				HStack {
					Text("\(targets.calories, format: .number.precision(.fractionLength(0))) kcal")
						.font(.largeTitle)
						.fontWeight(.heavy)
						.foregroundStyle(Colormanager.Accent.button)
				}

				Text("Calories")

				Spacer()
				Spacer()

				HStack(spacing: 50) {
					MacroRingView(title: "Protein", value: targets.protein)
					MacroRingView(title: "Carbs", value: targets.carbs)
					MacroRingView(title: "Fat", value: targets.fat)
				}
				.padding(.horizontal, 24)

				Spacer()
				Spacer()

				ZStack {
					Circle()
						.fill(Colormanager.Diet.softPeach.opacity(0.6))
						.blur(radius: 50)
						.ignoresSafeArea()

					Image("Diet-onboard")
						.resizable()
						.scaledToFit()
				}

				Button(action: action) {
					Text("Save")
						.font(.system(size: 17, weight: .bold))
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 15)
						.background(Colormanager.Accent.button, in: RoundedRectangle(cornerRadius: 15))
				}
			}
			.padding()
		}
		.ignoresSafeArea(.keyboard)
	}
}

struct MacroRingView: View {
	let title: String
	let value: Double

	var body: some View {
		VStack {
			ZStack {
				Circle().stroke(Colormanager.Accent.button, lineWidth: 2)
				Text("\(value, format: .number.precision(.fractionLength(0))) g")
			}
			Text(title)
		}
	}
}

struct ListSample: View {
	
	var string = ["abc","efg", "hij", "klm"]
	
	var body: some View {
		List {
			Section {
				ForEach(string, id: \.self) { str in
					VStack {
						Image(systemName: "checkmark")
						
						Text(str)
					}
				}
				.listRowSeparator(.hidden)
				.listRowBackground(Color.clear)
			} header: {
				Text("okay")
			}
			
			Section {
				ForEach(string, id: \.self) { str in
					VStack {
						Image(systemName: "checkmark")
						
						Text(str)
					}
				}
			} header: {
				Text("okay 2")
			}
			
		}
	}
}
//
#Preview {
	NavigationStack {
		ZStack {
			ListSample()
		}
		.navigationTitle("abc")
		.navigationBarTitleDisplayMode(.inline)
	}
}
