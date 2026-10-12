//
//  LogMealView.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI
import CoreData

struct LogMealView: View {
	
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.dismiss) private var dismiss
	@FocusState private var foodFieldIsFocused: Bool
	
	@State private var description = ""
	@State private var title = ""
	@State private var mealType : MealType = .breakfast

	@State private var mealDate: Date
	@State private var mealTime = Date()

	@State private var items: [DraftMealItem] = []
	
	@State private var isLoading = false
	@State private var errorMessage = ""
	@State private var showingError = false
	
	@State private var showSavedMeals = false
	@State private var deleteConfirmation = DeleteConfirmation()
	
	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(keyPath: \MealLog.createdAt, ascending: false)
		],
		predicate: NSPredicate(format: "kindRaw == %@", "template")
	)
	
	private var savedMeals: FetchedResults<MealLog>

	init(mealDate: Date) {
		_mealDate = State(initialValue: mealDate)
	}

	private var totalCalories: Double {
		items.reduce(0) { $0 + $1.calories }
	}

	private var totalProtein: Double {
		items.reduce(0) { $0 + $1.protein }
	}

	private var totalCarbs: Double {
		items.reduce(0) { $0 + $1.carbs }
	}

	private var totalFat: Double {
		items.reduce(0) { $0 + $1.fat }
	}

	var body: some View {
		
		NavigationStack {
			ZStack {
				Colormanager.Workout.sand
					.ignoresSafeArea()
					List {
							mealDetailsCard
							
							addFromSavedcard
							
							descriptionCard
							
							mealItemsList
							
							nutritionSummary
						
						Color.clear
								.frame(height: 20)
								.listRowBackground(Color.clear)
								.listRowSeparator(.hidden)
					}
					.listRowInsets(.horizontal, 0)
					.scrollContentBackground(.hidden)
					.scrollDismissesKeyboard(.interactively)
				
				VStack {
					Spacer()
					actionButtons
						.padding()
						.background {
							Rectangle()
								.fill(.ultraThinMaterial)
								.overlay(
									Colormanager.Workout.sand.opacity(1)
								)
						}
						.padding(.bottom, 12)
				}
				.ignoresSafeArea()
			}
			.navigationTitle("Log Meal")
			.navigationBarTitleDisplayMode(.inline)
			.alert("Could Not Calculate Meal", isPresented: $showingError) {
				Button("OK", role: .cancel) { }
			} message: {
				Text(errorMessage)
			}
			.sheet(isPresented: $showSavedMeals) {
				SavedMealsView { meal in
					addSavedMeal(meal)
				}
			}
		}
		.deleteConfirmationOverlay(deleteConfirmation)
	}
	
	private var addFromSavedcard: some View {
		Section {
			
			HStack {
				Image(systemName: "bookmark.circle")
					.font(.largeTitle)
					.foregroundStyle(Colormanager.Accent.selected)
					.padding(.trailing, 4)
					.frame(maxHeight: .infinity, alignment: .topLeading)
				
				VStack(alignment: .leading) {
					Text("Add from saved Meals")
						.fontStyle(.headline)
					
					Text("use your saved meals template to quickly add items to the meal")
						.fontStyle(.footer)
				}
				
				Image(systemName: "chevron.right")
					.padding(.horizontal)
			}
			.padding(.vertical)
			.frame(maxWidth: .infinity)
			.clipShape(
				RoundedRectangle(cornerRadius: 20, style: .continuous)
			)
			.onTapGesture {
				showSavedMeals = true
				HapticManager.selection()
			}
		}
		.padding(3)
		.listRowInsets(.all, 0)
		.background(Colormanager.card)
		.listRowSeparator(.hidden)
	}

	private var descriptionCard: some View {
		Section {
			VStack(alignment: .leading, spacing: 16) {
				Text("What did you eat?")
					.fontStyle(.headline)
				
				TextField(
					"",
					text: $description,
					prompt: Text(
						"Example: 1 banana, 1 scoop whey protein, 300 ml milk"
					),
					axis: .vertical
				)
				.lineLimit(3...6)
				.fontStyle(.body)
				.tint(Colormanager.Accent.button)
				.padding(14)
				.background(Colormanager.secondaryBg)
				.clipShape(
					RoundedRectangle(cornerRadius: 16, style: .continuous)
				)
				.overlay {
					RoundedRectangle(cornerRadius: 16, style: .continuous)
						.stroke(lineWidth: 0.2)
				}
				.focused($foodFieldIsFocused)
				
				Button {
					Task {
						foodFieldIsFocused = false
						if await calculateNutrition() {
							description = ""
						}
					}
				} label: {
					Group {
						if isLoading {
							ProgressView()
								.tint(.white)
						} else {
							Label("Add Item", systemImage: "sparkles")
						}
					}
					.foregroundStyle(.white)
					.fontStyle(.headline)
					.frame(maxWidth: .infinity)
					.frame(height: 50)
					.background(Colormanager.Accent.button)
					.clipShape(
						RoundedRectangle(cornerRadius: 18, style: .continuous)
					)
				}
				.disabled(
					description.trimmingCharacters(
						in: .whitespacesAndNewlines
					).isEmpty || isLoading
				)
				.opacity(
					description.trimmingCharacters(
						in: .whitespacesAndNewlines
					).isEmpty || isLoading ? 0.5 : 1
				)
			}
		}
		.padding(16)
		.background(Colormanager.card)
		.listRowSeparator(.hidden)
		.listRowInsets(.all, 0)
		.toolbar(.hidden, for: .tabBar)
	}

	private var mealDetailsCard: some View {
		Section {
			VStack(spacing: 16) {
				TextField(
					"",
					text: $title,
					prompt: Text("Meal name (optional)")
				)
				.fontStyle(.body)
				.tint(Colormanager.Accent.button)
				.padding()
				.overlay(content: {
					RoundedRectangle(cornerRadius: 16, style: .continuous)
						.stroke(lineWidth: 0.2)
				})
				
				
				Picker("Meal type", selection: $mealType) {
					ForEach(MealType.allCases, id: \.self) { type in
						Text(type.title)
							.tag(type)
					}
				}
				.colorMultiply(Colormanager.Accent.selected)
				.pickerStyle(.palette)
				.onChange(of: mealType) { _, _ in
					HapticManager.selection()
				}
				
				HStack(alignment: .center) {
					DatePicker(selection: $mealDate, displayedComponents: [.date, .hourAndMinute]) {
						
						Text("Time :")
							.fontStyle(.body)
					}
					.colorMultiply(Colormanager.Accent.selected)
					.tint(Colormanager.Accent.selected)
				}
			}
			.padding()
		}
		.listRowInsets(.all, 0)
		.foregroundStyle(Colormanager.Typography.primaryText)
		.background(Colormanager.card)
		.listRowSeparator(.hidden)
	}
	
	private var nutritionSummary: some View {
		Section {
			
			HStack {
				
				Image(mealType.image)
					.resizable()
					.scaledToFit()
					.frame(width: 48)
					.foregroundStyle(Colormanager.Accent.selected)
					.frame(maxHeight: .infinity, alignment: .topLeading)
					.padding(.trailing, 4)
				
				VStack(alignment: .leading) {
					
					Text("Meal Total")
						.fontStyle(.headline)
						.frame(maxHeight: .infinity)
					
					Text("\(totalCalories, format: .number.precision(.fractionLength(0))) kcal")
						.fontStyle(.headline)
						.frame(maxHeight: .infinity)
				}
				.padding(.trailing)
				
				Spacer()
				Spacer()
				
				VStack {
					Spacer()
					
					HStack {
						MealMacro(value: totalProtein, title: "P")
						Spacer()
						MealMacro(value: totalCarbs, title: "C")
						Spacer()
						MealMacro(value: totalFat, title: "F")
					}
				}
			}
			.padding()
		}
		.background(Colormanager.card)
		.listRowInsets(.all, 0)
		.listRowSeparator(.hidden)
		
	}

	private var mealItemsList: some View {
		Section {
			if items.isEmpty {
				
				ContentUnavailableView {
					Label {
						Text("No Items")
							.fontStyle(.headline)
					} icon: {
						Image(systemName: "tray")
							.font(.system(size: 32))
					}
				} description: {
					Text("Add item from above by entering a food item.")
						.fontStyle(.body)
				}
				
			} else {
				ForEach($items) { $item in
					MealItemEditorCard(item: $item)
						.listRowInsets(
							EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
						)
						.transition(.move(edge: .bottom).combined(with: .opacity))
						.swipeActions(edge: .trailing, allowsFullSwipe: false) {
							Button {
								Task {
									guard await deleteConfirmation.confirm(
										title: "Delete food item?",
										message: "This food item will be removed from this meal.",
										tint:  Colormanager.Accent.button
									) else { return }
									
									if let index = items.firstIndex(where: { $0.id == item.id }) {
										items.remove(at: index)
									}
								}
							} label: {
								Label("", systemImage: "trash")
							}
							.tint(Colormanager.Status.error)
						}
				}
			}

		} header: {
			Text("Food Items")
				.foregroundStyle(Colormanager.Typography.secondaryText)
				.fontStyle(.headline)
				
		}
	}
	
	private var actionButtons: some View {
		HStack(spacing: 12) {
			
			Button {
				saveMeal(kind: .log)
			} label: {
				Text("Log Meal")
					.foregroundStyle(.white)
					.fontStyle(.headline)
					.frame(maxWidth: .infinity)
					.frame(height: 50)
					.opacity(items.isEmpty ? 0.5 : 1)
					.background(Colormanager.Accent.button)
					.clipShape(
						RoundedRectangle(
							cornerRadius: 18,
							style: .continuous
						)
					)
			}
			.buttonStyle(.borderless)
			.disabled(items.isEmpty)
			.opacity(items.isEmpty ? 0.5 : 1)
		}
	}

	@MainActor
	private func calculateNutrition() async -> Bool {
		isLoading = true
		defer { isLoading = false }

		do {
			let response = try await NutritionAPIService.fetch(query: description)

			let newItems = response.items.map {
				DraftMealItem(
					name: $0.name,
					servingAmount: $0.servingSizeGrams,
					servingUnit: "g",
					calories: $0.calories,
					protein: $0.protein,
					carbs: $0.carbs,
					fat: $0.fat,
					fiber: $0.fiber,
					sugar: $0.sugar
				)
			}

			guard !newItems.isEmpty else {
				errorMessage = "No foods could be identified. Try describing the meal more clearly."
				showingError = true
				return false
			}

			withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
				items.insert(contentsOf: newItems, at: 0)
				HapticManager.success()
			}
			return true
		} catch {
			errorMessage = error.localizedDescription
			showingError = true
			return false
		}
	}

	private func saveMeal(kind: MealKind) {
		guard !items.isEmpty else { return }
		HapticManager.success()
		
		let title = title.isEmpty ? items.first?.name : title.trimmingCharacters(in: .whitespacesAndNewlines)
		
			let meal = MealLog(context: viewContext)
			meal.id = UUID()
			meal.createdAt = .now
			meal.kind = kind
			meal.title = title
			meal.originalDescription = description
			meal.mealType = mealType

		if kind == .log {
			meal.occuredAt = mealDate
		}

			for (index, draft) in items.enumerated() {
				let item = MealItem(context: viewContext)
				item.id = UUID()
				item.createdAt = .now.addingTimeInterval(Double(index))
				item.name = draft.name
				item.servingAmount = draft.servingAmount
				item.servingUnitRaw = draft.servingUnit
				item.calories = draft.calories
				item.protein = draft.protein
				item.carbs = draft.carbs
				item.fat = draft.fat
				item.fiber = draft.fiber
				item.sugar = draft.sugar
				item.meal = meal
			}

		do {
			try viewContext.save()
			if kind == .log {
				dismiss()
			}
		} catch {
			errorMessage = error.localizedDescription
			showingError = true
		}
	}
	
	private func addSavedMeal(_ meal: MealLog) {
		HapticManager.success()
		let drafts = meal.sortedItems.map { item in
			DraftMealItem(
				name: item.name ?? "Food item",
				servingAmount: item.servingAmount,
				servingUnit: item.servingUnitRaw ?? "g",
				calories: item.calories,
				protein: item.protein,
				carbs: item.carbs,
				fat: item.fat,
				fiber: item.fiber,
				sugar: item.sugar
			)
		}
		
		title = meal.title ?? ""
		mealType = meal.mealType

		withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
			items = drafts
		}
		
	}
}

#Preview {
	LogMealView(mealDate: .now)
}
