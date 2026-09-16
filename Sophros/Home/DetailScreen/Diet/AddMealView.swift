//
//  AddMealView.swift
//  Sophros
//
//  Created by Sohan Maurya on 19/08/26.
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
						.font(.headline)
					
					Text("use your saved meals template to quickly add items to the meal")
						.font(.footnote)
				}
				
				Image(systemName: "chevron.right")
					.padding(.leading)
			}
			.padding(.vertical)
			.frame(maxWidth: .infinity)
			.background(Colormanager.Accent.button.opacity(0.4))
			.clipShape(
				RoundedRectangle(cornerRadius: 20, style: .continuous)
			)
			.onTapGesture {
				showSavedMeals = true
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
					.font(.headline)
					.foregroundStyle(Colormanager.Typography.primaryText)
				
				
				TextField(
					"",
					text: $description,
					prompt: Text(
						"Example: 1 banana, 1 scoop whey protein, 300 ml milk"
					)
					.foregroundStyle(Colormanager.Typography.placeholder),
					axis: .vertical
				)
				.lineLimit(3...6)
				.foregroundStyle(Colormanager.Typography.primaryText)
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
					.font(.headline)
					.foregroundStyle(.white)
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
						.foregroundStyle(Colormanager.Typography.placeholder)
				)
				.foregroundStyle(Colormanager.Typography.primaryText)
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
				
				HStack(alignment: .center) {
					DatePicker(
						"Time :",
						selection: $mealDate,
						displayedComponents: [.date, .hourAndMinute]
					)
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
				
				Image(systemName: "fork.knife.circle.fill")
					.font(.system(size: 48))
					.foregroundStyle(Colormanager.Accent.selected)
					.frame(maxHeight: .infinity, alignment: .topLeading)
					.padding(.trailing, 4)
				
				VStack(alignment: .leading) {
					
					Text("Meal Total")
						.font(.headline)
						.foregroundStyle(Colormanager.Typography.primaryText)
						.frame(maxHeight: .infinity)
					
					Text("\(totalCalories, format: .number.precision(.fractionLength(0))) kcal")
						.font(.headline.weight(.bold))
						.foregroundStyle(Colormanager.Typography.primaryText)
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
				ContentUnavailableView("No items",
					systemImage: "tray",
					description: Text(
						"Add item from above by entering a food item"
					)
				)
			} else {
				ForEach($items) { $item in
					MealItemEditorCard(item: $item)
						.listRowInsets(
							EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
						)
						.transition(.move(edge: .bottom).combined(with: .opacity))
				}
				.onDelete { offsets in
					withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
						items.remove(atOffsets: offsets)
					}
				}
			}

		} header: {
			Text("Food Items")
				
		}
	}
	
	private var actionButtons: some View {
		HStack(spacing: 12) {
			
			Button {
				saveMeal(kind: .log)
			} label: {
				Text("Log Meal")
					.font(.headline)
					.foregroundStyle(.white)
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

struct SavedMealsView: View {

	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.dismiss) private var dismiss

	@State private var searchText = ""
	
	var selectedMeal: ((MealLog) -> Void)

	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(keyPath: \MealLog.createdAt, ascending: false)
		],
		predicate: NSPredicate(format: "kindRaw == %@", "template")
	)
	private var savedMeals: FetchedResults<MealLog>
	
	@State private var showCreateMeal = false
	
	var filteredMeals : [MealLog] {
		return savedMeals.filter { meal in
			searchText.isEmpty ||
			(meal.title ?? "").localizedCaseInsensitiveContains(searchText)
		}
	}

	var body: some View {
		
		NavigationStack {
			ZStack {
				List {
					Section {
						if filteredMeals.isEmpty {
							ContentUnavailableView(
								searchText.isEmpty ? "No Saved Meals" : "No Results",
								systemImage: searchText.isEmpty ? "fork.knife" : "magnifyingglass",
								description: Text(
									searchText.isEmpty
									? "Create a meal to save it here."
									: "No saved meals match your search."
								)
							)
						} else {
							ForEach(filteredMeals, id: \.objectID) { meal in
								
								Button {
									selectedMeal(meal)
									dismiss()
								} label: {
									SavedMealCard(meal: meal)
										
								}
								.buttonStyle(SelectableListCell())
								.swipeActions(edge: .trailing) {
									Button(role: .destructive) {
										delete(meal)
									} label: {
										Label("Delete", systemImage: "trash")
									}
								}
							}
						}
					} footer: {
						Text("items from selected meal will get added.")
					}
					.listRowInsets(.all, 0)
				}
				.scrollContentBackground(.hidden)
				.background(Colormanager.Diet.cream)
				.searchable(
					text: $searchText,
					placement: .navigationBarDrawer(displayMode: .automatic),
					prompt: "Search saved meals"
				)

				
				VStack {
					Spacer()
					
					Button {
						showCreateMeal = true
					} label: {
						Text("Create Meal")
							.font(.headline)
							.foregroundStyle(.white)
							.padding()
							.background(Colormanager.Diet.apricot)
							.clipShape(RoundedRectangle(cornerRadius: 16))
							.padding()
					}
				}
			}
			.navigationTitle("Saved Meals")
			.navigationBarTitleDisplayMode(.inline)
			.ignoresSafeArea(.keyboard)
			.navigationDestination(isPresented: $showCreateMeal) {
				CreateMealView(mealDate: Date())
			}
		}
	}

	private func updateSearchPredicate(_ searchText: String) {

		let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

		if trimmedSearch.isEmpty {
			savedMeals.nsPredicate = NSPredicate(
				format: "kindRaw == %@",
				"template"
			)
		} else {
			savedMeals.nsPredicate = NSPredicate(
				format: "kindRaw == %@ AND name CONTAINS[cd] %@",
				"template",
				trimmedSearch
			)
		}
	}

	private func delete(_ meal: MealLog) {
		viewContext.delete(meal)

		do {
			try viewContext.save()
		} catch {
			// Show your existing error alert here if desired.
		}
	}
}

struct CreateMealView : View {
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
			.navigationTitle("Create Meal")
			.navigationBarTitleDisplayMode(.inline)
			.alert("Could Not Calculate Meal", isPresented: $showingError) {
				Button("OK", role: .cancel) { }
			} message: {
				Text(errorMessage)
			}
		}
	}

	private var descriptionCard: some View {
		Section {
			VStack(alignment: .leading, spacing: 16) {
				Text("What did you eat?")
					.font(.headline)
					.foregroundStyle(Colormanager.Typography.primaryText)
				
				
				TextField(
					"",
					text: $description,
					prompt: Text(
						"Example: 1 banana, 1 scoop whey protein, 300 ml milk"
					)
					.foregroundStyle(Colormanager.Typography.placeholder),
					axis: .vertical
				)
				.lineLimit(3...6)
				.foregroundStyle(Colormanager.Typography.primaryText)
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
					.font(.headline)
					.foregroundStyle(.white)
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
						.foregroundStyle(Colormanager.Typography.placeholder)
				)
				.foregroundStyle(Colormanager.Typography.primaryText)
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
				
				Image(systemName: "fork.knife.circle.fill")
					.font(.system(size: 48))
					.foregroundStyle(Colormanager.Accent.selected)
					.frame(maxHeight: .infinity, alignment: .topLeading)
					.padding(.trailing, 4)
				
				VStack(alignment: .leading) {
					
					Text("Meal Total")
						.font(.headline)
						.foregroundStyle(Colormanager.Typography.primaryText)
						.frame(maxHeight: .infinity)
					
					Text("\(totalCalories, format: .number.precision(.fractionLength(0))) kcal")
						.font(.headline.weight(.bold))
						.foregroundStyle(Colormanager.Typography.primaryText)
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
				ContentUnavailableView("No items",
					systemImage: "tray",
					description: Text(
						"Add item from above by entering a food item"
					)
				)
			} else {
				
				ForEach($items) { $item in
					MealItemEditorCard(item: $item)
						.listRowInsets(
							EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
						)
						.transition(.move(edge: .bottom).combined(with: .opacity))
				}
				.onDelete { offsets in
					withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
						items.remove(atOffsets: offsets)
					}
				}
			}

		} header: {
			Text("Food Items")
				
		}
	}
	
	private var actionButtons: some View {
		HStack(spacing: 12) {
			
			Button {
				saveMeal(kind: .template)
			} label: {
				Text("Create Meal")
					.font(.headline)
					.foregroundStyle(.white)
					.frame(maxWidth: .infinity)
					.frame(height: 50)
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
		let title = title.isEmpty ? items.first?.name : title.trimmingCharacters(in: .whitespacesAndNewlines)
		
			let meal = MealLog(context: viewContext)
			meal.id = UUID()
			meal.createdAt = .now
			meal.kind = kind
			meal.title = title
			meal.originalDescription = description
			meal.mealType = mealType

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
			dismiss()
		} catch {
			errorMessage = error.localizedDescription
			showingError = true
		}
	}
}



#Preview {
//	CreateMealView(mealDate: Date())
//		.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	
}

private struct MealMacro: View {
	let value: Double
	let title: String

	var body: some View {
		HStack(alignment: .firstTextBaseline, spacing: 8) {
			
			Text(title)
				.font(.footnote)
				.foregroundStyle(Colormanager.Typography.secondaryText)
			
			Text("\(value, format: .number.precision(.fractionLength(0)))g")
				.font(.footnote.weight(.bold))
		}
		.foregroundStyle(Colormanager.Typography.primaryText)
	}
}

private struct MealItemEditorCard: View {
	@Binding var item: DraftMealItem

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(item.name)
				.font(.headline)
				.foregroundStyle(Colormanager.Typography.primaryText)
				.tint(Colormanager.Accent.button)

			HStack {
				Text(
					"\(item.calories, format: .number.precision(.fractionLength(0))) kcal"
				)
				.font(.subheadline.weight(.semibold))

				Spacer()

				Text(
					"P \(item.protein, format: .number.precision(.fractionLength(0)))g · C \(item.carbs, format: .number.precision(.fractionLength(0)))g · F \(item.fat, format: .number.precision(.fractionLength(0)))g"
				)
				.font(.caption)
				.foregroundStyle(Colormanager.Typography.secondaryText)
			}
			.foregroundStyle(Colormanager.Typography.primaryText)
		}
		.padding(16)
//        .background(Colormanager.card)
//        .clipShape(
//            RoundedRectangle(cornerRadius: 18, style: .continuous)
//        )
	}
}

private struct SavedMealCard: View {
	let meal: MealLog

	private var totalCalories: Double {
		meal.sortedItems.reduce(0) { $0 + $1.calories }
	}

	private var totalProtein: Double {
		meal.sortedItems.reduce(0) { $0 + $1.protein }
	}

	private var totalCarbs: Double {
		meal.sortedItems.reduce(0) { $0 + $1.carbs }
	}

	private var totalFat: Double {
		meal.sortedItems.reduce(0) { $0 + $1.fat }
	}

	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: "fork.knife")
				.font(.title3)
				.foregroundStyle(Colormanager.Accent.button)
				.frame(width: 42, height: 42)
				.background(Colormanager.secondaryBg)
				.clipShape(Circle())
			
			VStack(alignment: .leading, spacing: 7) {
				Text(meal.title ?? "Untitled meal")
					.font(.headline)
					.foregroundStyle(Colormanager.Typography.primaryText)
				
				Text(
					"\(totalCalories, format: .number.precision(.fractionLength(0))) kcal · \(meal.sortedItems.count) items"
				)
				.font(.subheadline.weight(.semibold))
				.foregroundStyle(Colormanager.Typography.primaryText)
				
				Text(
					"P \(totalProtein, format: .number.precision(.fractionLength(0)))g · C \(totalCarbs, format: .number.precision(.fractionLength(0)))g · F \(totalFat, format: .number.precision(.fractionLength(0)))g"
				)
				.font(.caption)
				.foregroundStyle(Colormanager.Typography.secondaryText)
			}
			
			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		.padding()
	}
}

private struct SavedMealCard2: View {

	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: "fork.knife")
				.font(.title3)
				.foregroundStyle(Colormanager.Accent.button)
				.frame(width: 42, height: 42)
				.background(Colormanager.secondaryBg)
				.clipShape(Circle())

			VStack(alignment: .leading, spacing: 7) {
				Text("breakfast")
					.font(.headline)
					.foregroundStyle(Colormanager.Typography.primaryText)

				Text(
					"\(2897, format: .number.precision(.fractionLength(0))) kcal · \(3) items"
				)
				.font(.subheadline.weight(.semibold))
				.foregroundStyle(Colormanager.Typography.primaryText)

				Text(
					"P \(20, format: .number.precision(.fractionLength(0)))g · C \(250, format: .number.precision(.fractionLength(0)))g · F \(40, format: .number.precision(.fractionLength(0)))g"
				)
				.font(.caption)
				.foregroundStyle(Colormanager.Typography.secondaryText)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		.background(.green.opacity(0.4))
	}
}

#Preview {
	SavedMealsView { meal in
		
	}
	.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//	SavedMealCard2()
}

struct DraftMealItem: Identifiable {
	let id = UUID()

	var name: String
	var servingAmount: Double
	var servingUnit: String
	var calories: Double
	var protein: Double
	var carbs: Double
	var fat: Double
	var fiber: Double
	var sugar: Double
}
