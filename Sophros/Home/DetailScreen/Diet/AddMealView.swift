//
//  AddMealView.swift
//  Sophros
//
//  Created by Sohan Maurya on 19/08/26.
//


import SwiftUI
import CoreData

struct AddMealView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var foodFieldIsFocused: Bool
    
    @State private var description = ""
    @State private var title = ""
    @State private var mealType : MealType = .breakfast

    @State private var mealDate: Date
    @State private var mealTime = Date()

    @State private var items: [DraftMealItem] = [DraftMealItem(name: "oats", servingAmount: 10, servingUnit: "g", calories: 300, protein: 10, carbs: 250, fat: 5, fiber: 2, sugar: 5), DraftMealItem(name: "Lunch", servingAmount: 10, servingUnit: "g", calories: 300, protein: 10, carbs: 250, fat: 5, fiber: 2, sugar: 5)]
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
    
    @State var shouldScroll: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Colormanager.Workout.sand
                    .ignoresSafeArea()
                ScrollViewReader { proxy in
                    List {
                        Section {
                            descriptionCard
                            mealDetailsCard
                            
                            mealItemsList
                            nutritionSummary
                            savedMealsSection
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.horizontal, 0)
                        
                        Color.clear
                                .frame(height: 20) // space above the bottom action bar
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Colormanager.Workout.sand)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: shouldScroll) { _, val in
                        guard val else { return }
                        shouldScroll = false
                        withAnimation {
                            proxy.scrollTo("meal-items", anchor: .top)
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    actionButtons
                        .padding()
                        .padding(.bottom)
                        .background {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Colormanager.Workout.sand.opacity(1)
                                )
                        }
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(
                                Colormanager.Typography.primaryText
                            )
                    }
                }
            }
            .alert("Could Not Calculate Meal", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .toastHost()
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                        Label("Calculate Nutrition", systemImage: "sparkles")
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
        .padding(16)
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var mealDetailsCard: some View {
        VStack(spacing: 0) {
            TextField(
                "",
                text: $title,
                prompt: Text("Meal name (optional)")
                    .foregroundStyle(Colormanager.Typography.placeholder)
            )
            .foregroundStyle(Colormanager.Typography.primaryText)
            .tint(Colormanager.Accent.button)
            .padding()

            Picker("Meal type", selection: $mealType) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Text(type.title)
                        .tag(type)
                }
            }
            .colorMultiply(Colormanager.Accent.selected)
            .padding(.horizontal)
            .pickerStyle(.palette)

            HStack(alignment: .center) {
                DatePicker(
                    "Date and Time",
                    selection: $mealDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .colorMultiply(Colormanager.Accent.selected)
            }
            .padding()
        }
        .foregroundStyle(Colormanager.Typography.primaryText)
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var nutritionSummary: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Total")
                .font(.headline)
                .foregroundStyle(Colormanager.Typography.primaryText)
            
            Text("\(totalCalories, format: .number.precision(.fractionLength(0))) kcal")
                .font(.title.weight(.bold))
                .foregroundStyle(Colormanager.Typography.primaryText)
            
            HStack {
                MealMacro(value: totalProtein, title: "Protein")
                Spacer()
                MealMacro(value: totalCarbs, title: "Carbs")
                Spacer()
                MealMacro(value: totalFat, title: "Fat")
            }
        }
        .padding(16)
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        
    }

    private var mealItemsList: some View {
        Section {
            ForEach($items) { $item in
                MealItemEditorCard(item: $item)
                    .listRowInsets(
                        EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
                    )
                    .listRowBackground(Color.clear)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .onDelete { offsets in
                items.remove(atOffsets: offsets)
            }
        } header: {
            Text("Food Items")
                .font(.system(.headline))
                .foregroundStyle(Colormanager.Typography.primaryText)
        }
    }
    
    @ViewBuilder
    private var savedMealsSection: some View {
        if !savedMeals.isEmpty {
            Section {
                ForEach(savedMeals, id: \.objectID) { meal in
                    Button {
                        addSavedMeal(meal)
                    } label: {
                        SavedMealCard(meal: meal)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(
                        EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
                    )
                    .listRowBackground(Color.clear)
                }
            } header: {
                Text("Saved Meals")
                    .font(.system(.headline))
                    .foregroundStyle(Colormanager.Typography.primaryText)
            }
            .listRowSeparator(.hidden)
        } else {
            Section {
                Text("No saved meals yet")
                    .font(.subheadline)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Colormanager.card)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .listRowInsets(
                        EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
                    )
                    .listRowBackground(Color.clear)
            } header: {
                Text("Saved Meals")
                    .font(.system(.headline))
                    .foregroundStyle(Colormanager.Typography.primaryText)
            }
            .listRowSeparator(.hidden)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                saveMeal(kind: .template)
            } label: {
                Text("Save Meal")
                    .font(.headline)
                    .foregroundStyle(Colormanager.Typography.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Colormanager.card)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.borderless)

            Button {
                saveMeal(kind: .log)
            } label: {
                Text("Log Meal")
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
            meal.mealType = .breakfast

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

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items = drafts
        }
        
        shouldScroll = true
        ToastManager.shared.showToast("items added..", duration: 0.6)
    }
}

private struct MealMacro: View {
    let value: Double
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(value, format: .number.precision(.fractionLength(0)))g")
                .font(.headline.weight(.bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(Colormanager.Typography.secondaryText)
        }
        .foregroundStyle(Colormanager.Typography.primaryText)
    }
}

private struct MealItemEditorCard: View {
    @Binding var item: DraftMealItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Food name", text: $item.name)
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
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
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

            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(Colormanager.Accent.button)
        }
        .padding(16)
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}


#Preview {
    AddMealView(mealDate: Date())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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
