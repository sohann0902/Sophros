//
//  NutritionCalculator.swift
//  Sophros
//
//  Created by Sohan Maurya on 12/09/26.
//

import SwiftUI
import CoreData


// MARK: - Nutrition Calculator

struct NutritionCalculator {

	static func createGoal(
		profile: NutritionProfile,
		context: NSManagedObjectContext
	) -> NutritionGoal {

		// 1. Calculate BMR
		let bmr = calculateBMR(
			gender: profile.gender,
			age: profile.age,
			heightCM: profile.heightCM,
			weightKG: profile.weightKG
		)

		// 2. Calculate maintenance calories
		let maintenanceCalories =
			bmr * profile.activityLevel.multiplier

		// 3. Adjust calories according to goal
		let calories =
			calculateCalories(
				maintenanceCalories: maintenanceCalories,
				goal: profile.goal
			)

		// 4. Protein
		let proteinPerKG: Double

		switch profile.goal {

		case .lose:
			proteinPerKG = 2.0

		case .maintain:
			proteinPerKG = 1.7

		case .gain:
			proteinPerKG = 1.8
		}

		let protein =
			profile.weightKG * proteinPerKG

		// 5. Fat
		let fat =
			profile.weightKG * 0.8

		// 6. Carbohydrates
		let proteinCalories =
			protein * 4

		let fatCalories =
			fat * 9

		let remainingCalories =
			max(
				0,
				calories -
				proteinCalories -
				fatCalories
			)

		let carbs =
			remainingCalories / 4

		// 7. Fiber
		let fiber =
			(calories / 1000) * 14

		// 8. Sugar limit
		//
		// This is a limit, not a target.
		// ~10% of calories from sugar.
		let sugarLimit =
			(calories * 0.10) / 4


		// MARK: - Create Core Data Object

		let nutritionGoal =
			NutritionGoal(context: context)

		nutritionGoal.calorie =
			calories.rounded()

		nutritionGoal.protein =
			protein.rounded()

		nutritionGoal.carbs =
			carbs.rounded()

		nutritionGoal.fat =
			fat.rounded()

		nutritionGoal.fiber =
			fiber.rounded()

		nutritionGoal.sugar =
			sugarLimit.rounded()

		return nutritionGoal
	}


	// MARK: - BMR

	private static func calculateBMR(
		gender: Gender,
		age: Int,
		heightCM: Double,
		weightKG: Double
	) -> Double {

		let base =
			(10 * weightKG) +
			(6.25 * heightCM) -
			(5 * Double(age))

		switch gender {

		case .male:
			return base + 5

		case .female:
			return base - 161

		case .other,
			 .preferNotToSay:

			// Neutral estimate.
			return base - 78
		}
	}


	// MARK: - Calories

	private static func calculateCalories(
		maintenanceCalories: Double,
		goal: NutritionGoalType
	) -> Double {

		switch goal {

		case .maintain:
			return maintenanceCalories

		case .lose:
			return maintenanceCalories - 400

		case .gain:
			return maintenanceCalories + 300
		}
	}
}

struct NutritionProfile {

	let gender: Gender
	let age: Int
	let heightCM: Double
	let weightKG: Double
	let activityLevel: ActivityLevel
	let goal: NutritionGoalType
}


// MARK: - Nutrition Goal Type

enum NutritionGoalType: String, CaseIterable, Identifiable {

	case maintain
	case lose
	case gain

	var id: String { rawValue }

	var title: String {
		switch self {
		case .maintain:
			return "Maintain"
		case .lose:
			return "Cut"
		case .gain:
			return "Gain"
		}
	}
}


// MARK: - Activity Level

enum ActivityLevel: String, CaseIterable, Identifiable {

	case sedentary
	case lightlyActive
	case moderatelyActive
	case veryActive
	case extremelyActive

	var id: String { rawValue }

	var title: String {
		switch self {
		case .sedentary:
			return "Sedentary"

		case .lightlyActive:
			return "Lightly Active"

		case .moderatelyActive:
			return "Moderately Active"

		case .veryActive:
			return "Very Active"

		case .extremelyActive:
			return "Extremely Active"
		}
	}

	var multiplier: Double {
		switch self {
		case .sedentary:
			return 1.20

		case .lightlyActive:
			return 1.375

		case .moderatelyActive:
			return 1.55

		case .veryActive:
			return 1.725

		case .extremelyActive:
			return 1.90
		}
	}
}

