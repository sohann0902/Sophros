//
//  AddMealView.swift
//  Sophros
//
//  Created by Sohan Maurya on 19/08/26.
//

import SwiftUI
import CoreData

struct MealMacro: View {
	let value: Double
	let title: String

	var body: some View {
		HStack(alignment: .firstTextBaseline, spacing: 8) {
			
			Text(title)
				
			Text("\(value, format: .number.precision(.fractionLength(0)))g")
		}
		.foregroundStyle(Colormanager.Typography.primaryText)
		.fontStyle(.footer)
	}
}

struct MealItemEditorCard: View {
	@Binding var item: DraftMealItem

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(item.name)
				.fontStyle(.subheadline)
				.tint(Colormanager.Accent.button)

			HStack {
				Text(
					"\(item.calories, format: .number.precision(.fractionLength(0))) kcal"
				)
				.fontStyle(.subheadline)

				Spacer()

				Text(
					"P \(item.protein, format: .number.precision(.fractionLength(0)))g · C \(item.carbs, format: .number.precision(.fractionLength(0)))g · F \(item.fat, format: .number.precision(.fractionLength(0)))g"
				)
				.foregroundStyle(Colormanager.Typography.primaryText)
				.fontStyle(.footer)
				
			}
			
		}
		.padding(16)
	}
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
