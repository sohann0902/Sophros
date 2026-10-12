//
//  NutritionSettings.swift
//  Sophros
//
//  Created by Sohan Maurya on 17/09/26.
//

import SwiftUI
import CoreData

struct NutritionSettings: View {
	@Environment(\.managedObjectContext) private var context
	@ObservedObject var nutritions: NutritionGoal
	@State private var isediting = false
	
	@FetchRequest(sortDescriptors: [], animation: .default)
	private var nutritionGoals: FetchedResults<NutritionGoal>
	@State private var nutritionGoalHeader : NutritionGoalHeader = .calorie
	@State private var value : String = ""
	
	internal enum NutritionGoalHeader {
		case calorie
		case protein
		case carbs
		case fat
		case sugar
		case fiber
		
		func getTitle() -> String {
			switch self {
			case .calorie:
				return "Calorie Goal"
			case .protein:
				return "Protein Goal"
			case .carbs:
				return "Carbs Goal"
			case .fat:
				return "Fat Limit"
			case .sugar:
				return "Sugar Limit"
			case .fiber:
				return "Fiber Goal"
			}
		}
	}
	
	var body: some View {
		
		ZStack {
			Colormanager.baseBackground.ignoresSafeArea()
			List {
				HStack {
					Text("Calories")
					Spacer()
					Group {
						Text("\(Int(nutritions.calorie.rounded())) kcal")
						Image(systemName: "pencil")
					} .onTapGesture {
						value = String(Int(nutritions.calorie.rounded()))
						nutritionGoalHeader = .calorie
						isediting = true
						
					}
				}
				
				HStack {
					Text("Protein")
					Spacer()
					Group {
						Text("\(Int(nutritions.protein)) g")
						Image(systemName: "pencil")
					}
					.onTapGesture {
						value = String(Int(nutritions.protein.rounded()))
						nutritionGoalHeader = .protein
						isediting = true
						
					}
				}
				
				HStack {
					Text("Carbs")
					Spacer()
					Group {
						Text("\(Int(nutritions.carbs)) g")
						Image(systemName: "pencil")
					}
					.onTapGesture {
						value = String(Int(nutritions.carbs.rounded()))
						nutritionGoalHeader = .carbs
						isediting = true
						
					}
				}
				
				HStack {
					Text("Fat")
					Spacer()
					Group {
						Text("\(Int(nutritions.fat)) g")
						Image(systemName: "pencil")
					}
					.onTapGesture {
						value = String(Int(nutritions.fat.rounded()))
						nutritionGoalHeader = .fat
						isediting = true
						
					}

				}
				
				HStack {
					Text("Sugar Limit")
					Spacer()
					Group {
						Text("\(Int(nutritions.sugar)) g")
						Image(systemName: "pencil")
					}
					.onTapGesture {
						value = String(Int(nutritions.sugar.rounded()))
						nutritionGoalHeader = .sugar
						isediting = true
						
					}
				}
				
				HStack {
					Text("Fiber")
					Spacer()
					Group {
						Text("\(Int(nutritions.fiber)) g")
						Image(systemName: "pencil")
					}
					.onTapGesture {
						value = String(Int(nutritions.fiber.rounded()))
						nutritionGoalHeader = .fiber
						isediting = true
						
					}
				}
			}
			.fontStyle(.body)
			.scrollContentBackground(.hidden)
			.sheet(isPresented: $isediting) {
				NumericGoalSheet(title: nutritionGoalHeader.getTitle(), value: $value) { newValue in
					
					updateNutritionGoal(nutrition: nutritionGoalHeader, value: Double(newValue) ?? 0)
					// persist newValue here
				}
				.presentationDragIndicator(.hidden)
				.presentationBackground(.clear)
			}
		}
		.ignoresSafeArea(.keyboard)
	}
	
	private func updateNutritionGoal(nutrition: NutritionGoalHeader, value : Double) {
		switch nutrition {
		case .calorie:
			nutritions.calorie = value
		case .protein:
			nutritions.protein = value
		case .carbs:
			nutritions.carbs = value
		case .fat:
			nutritions.fat = value
		case .sugar:
			nutritions.sugar = value
		case .fiber:
			nutritions.fiber = value
		}
		
		do {
			try self.context.save()
		} catch {
			print("failed to update nutrition goal")
		}
	}
}
