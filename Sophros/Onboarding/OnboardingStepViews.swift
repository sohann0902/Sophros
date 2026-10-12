//
//  OnboardingStepViews.swift
//  Sophros
//
//  Created by Sohan Maurya on 07/09/26.
//

import SwiftUI

// MARK: - Welcome

/// The intro screen shown before the info wizard begins.
struct WelcomeStepView: View {
	let shouldAnimateFlower: Bool
    let onStart: () -> Void

    var body: some View {
		ZStack(alignment: .center) {
			
			LinearGradient(colors: [
				.clear,
				Colormanager.Surfaces.border.opacity(0.3), Colormanager.Surfaces.border.opacity(0.5), Colormanager.Surfaces.border.opacity(0.7), Colormanager.Surfaces.border.opacity(0.1), .clear
			], startPoint: .top, endPoint: .bottom)
			.ignoresSafeArea()
			
			VStack(spacing: 8) {
				
				FlowerBloom(shouldBloom: shouldAnimateFlower)
				
				Text("Welcome to Sophros")
					.fontStyle(.largeTitle, size: 34)
					.multilineTextAlignment(.center)
				
				Text("Water, workouts, food, sleep, cycle, one place to keep track of it all.")
					.fontStyle(.body)
					.multilineTextAlignment(.center)
					.padding(.horizontal)
						.padding(.bottom)
				
				
				Button(action: onStart) {
					Text("Get Started")
						.foregroundStyle(.white)
						.fontStyle(.subheadline)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(
							RoundedRectangle(cornerRadius: 16)
								.fill(Colormanager.Accent.button)
						)
				}
				.padding(.bottom)
			}
			.padding()
		}
    }
}

// MARK: - Name

struct NameStepView: View {
    @Binding var name: String
    @FocusState private var focused: Bool

    var body: some View {
        TextField("Your name", text: $name)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
			.fontStyle(.title)
            .modifier(OnboardingFieldStyle())
            .focused($focused)
            .onAppear { focused = true }
    }
}

// MARK: - Gender

struct GenderStepView: View {
    @Binding var gender: Gender?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Gender.allCases) { option in
                let isSelected = gender == option
                Button {
                    gender = option
                } label: {
                    HStack {
                        Text(option.title)
                            
                        Spacer()
                    }
                    .foregroundStyle(isSelected ? .white : Colormanager.Typography.primaryText)
					.fontStyle(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? Colormanager.Accent.selected : Colormanager.secondaryBg)
                    )
                }
				.buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Age

struct AgeStepView: View {
    @Binding var age: Int?
    @FocusState private var focused: Bool

    private var text: Binding<String> {
        Binding(
            get: { age.map(String.init) ?? "" },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                age = digits.isEmpty ? nil : Int(digits)
            }
        )
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            TextField("25", text: text)
                .keyboardType(.numberPad)
                .fontStyle(.largeTitle, size: 40)
                
            Text("years")
				.foregroundStyle(Colormanager.Typography.secondaryText)
				.fontStyle(.headline)
               
        }
        .modifier(OnboardingFieldStyle())
        .focused($focused)
        .onAppear { focused = true }
    }
}

// MARK: - Measurement (height / weight)

struct MeasurementStepView: View {
    @Binding var value: Double?
    let unit: String
    let placeholder: String
    @FocusState private var focused: Bool

    private var text: Binding<String> {
        Binding(
            get: {
                guard let value else { return "" }
                // Show whole numbers without a trailing ".0".
                return value == value.rounded() ? String(Int(value)) : String(value)
            },
            set: { newValue in
                let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                value = cleaned.isEmpty ? nil : Double(cleaned)
            }
        )
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
				.fontStyle(.largeTitle, size: 40)

            Text(unit)
				.foregroundStyle(Colormanager.Typography.secondaryText)
                .fontStyle(.headline)
               
        }
        .modifier(OnboardingFieldStyle())
        .focused($focused)
        .onAppear { focused = true }
    }
}

// MARK: - Nutrition setup

struct ActivityLevelStepView: View {
    @Binding var activityLevel: ActivityLevel?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(ActivityLevel.allCases) { option in
                SelectionRow(
                    title: option.title,
                    isSelected: activityLevel == option
                ) {
                    activityLevel = option
                }
            }
        }
    }
}

struct NutritionGoalStepView: View {
    @Binding var goal: NutritionGoalType?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(NutritionGoalType.allCases) { option in
                SelectionRow(title: option.title, isSelected: goal == option) {
                    goal = option
                }
            }
        }
    }
}

private struct SelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
				
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                }
            }
            .foregroundStyle(isSelected ? .white : Colormanager.Typography.primaryText)
			.fontStyle(.subheadline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Colormanager.Accent.selected : Colormanager.secondaryBg)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared field styling

private struct OnboardingFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Colormanager.secondaryBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colormanager.border, lineWidth: 1)
            )
    }
}

#Preview {
	WelcomeStepView(shouldAnimateFlower: true) {
		
	}
}
