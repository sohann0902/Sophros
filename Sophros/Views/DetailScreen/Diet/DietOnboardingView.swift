//
//  DietOnboardingView.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI

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
					.fontStyle(.subheadline)

				Spacer()
				Spacer()

				HStack {
					Text("\(targets.calories, format: .number.precision(.fractionLength(0))) kcal")
						.foregroundStyle(Colormanager.Accent.button)
						.fontStyle(.largeTitle, size: 30)
				}

				Text("Calories")
					.fontStyle(.body)

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
						.foregroundStyle(.white)
						.fontStyle(.headline)
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

#Preview {
	DietOnboardingView(targets: .init(calories: 20, protein: 20, carbs: 20, fat: 20, fiber: 20, sugarLimit: 20)) {
		
	}
}
