//
//  SavedMealsView.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI
import CoreData

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
	@State private var deleteConfirmation = DeleteConfirmation()
	
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
							
							ContentUnavailableView {
								Label {
									Text(searchText.isEmpty ? "No Saved Meals" : "No Results")
										.fontStyle(.headline)
								} icon: {
									Image(systemName: searchText.isEmpty ? "fork.knife" : "magnifyingglass")
										.font(.system(size: 32))
								}
							} description: {
								Text(searchText.isEmpty
									 ? "Create a meal to save it here."
									 : "No saved meals match your search.")
									.fontStyle(.body)
							}
							
						} else {
							ForEach(filteredMeals, id: \.objectID) { meal in
								
								Button {
									selectedMeal(meal)
									dismiss()
								} label: {
									SavedMealCard(meal: meal)
										
								}
								.buttonStyle(SelectableListCell())
								.swipeActions(edge: .trailing, allowsFullSwipe: false) {
									Button {
										Task {
											guard await deleteConfirmation.confirm(
												title: "Delete saved meal?",
												message: "This saved meal and its food items will be permanently removed.",
												tint: Colormanager.Diet.apricot
											) else { return }
											delete(meal)
										}
									} label: {
										Label("", systemImage: "trash")
									}
									.tint(Colormanager.Status.error)
								}
							}
						}
					} footer: {
						Text("Items from selected meal will get added")
							.fontStyle(.footer)
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
							.foregroundStyle(.white)
							.fontStyle(.headline)
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
		.deleteConfirmationOverlay(deleteConfirmation)
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

#Preview {
	SavedMealsView{ _ in
		
	}
	.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

struct SavedMealCard: View {
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
			
			Image(meal.mealType.image)
				.resizable()
				.scaledToFit()
				.frame(width: 48)
				.foregroundStyle(Colormanager.Accent.selected)
				.frame(maxHeight: .infinity, alignment: .topLeading)
				.padding(.trailing, 4)
			
			VStack(alignment: .leading, spacing: 7) {
				Text(meal.title ?? "Untitled meal")
					.fontStyle(.headline)
				
				Text(
					"\(totalCalories, format: .number.precision(.fractionLength(0))) kcal · \(meal.sortedItems.count) items"
				)
				.fontStyle(.subheadline)
				
				Text(
					"P \(totalProtein, format: .number.precision(.fractionLength(0)))g · C \(totalCarbs, format: .number.precision(.fractionLength(0)))g · F \(totalFat, format: .number.precision(.fractionLength(0)))g"
				)
				.fontStyle(.footer)
			}
			
			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		.padding()
	}
}
