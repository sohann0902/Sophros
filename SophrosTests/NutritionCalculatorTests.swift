//
//  NutritionCalculatorTests.swift
//  SophrosTests
//
//  Created by Sohan Maurya on 12/09/26.
//

import XCTest
import CoreData
@testable import Sophros

final class NutritionCalculatorTests: XCTestCase {
	
	
	@MainActor func test_NutritioncalculatorForMale() {
		
		let profile = NutritionProfile(gender: .male, age: 24, heightCM: 169, weightKG: 55, activityLevel: .veryActive, goal: .gain)
		let context = PersistenceController.preview.container.viewContext
		let goal = NutritionCalculator.createGoal(profile: profile, context: context)
		
		XCTAssertNotNil(goal)
	}
}
