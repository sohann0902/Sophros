//
//  OnboardingView.swift
//  Sophros
//
//  Created by Sohan Maurya on 07/09/26.
//

import SwiftUI
import CoreData

/// Root of the first-launch onboarding flow. Owns step navigation and the draft,
/// and persists a `UserProfile` once the user finishes.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.managedObjectContext) private var context
    let shouldAnimateWelcome: Bool

	@State private var step: OnboardingStep = .welcome
    @State private var draft = OnboardingDraft()
    @State private var showAllSet = false

    var body: some View {
        ZStack {
			Color.white
                .ignoresSafeArea()

            if showAllSet {
                allSetView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if step == .welcome {
                WelcomeStepView(
                    shouldAnimateFlower: shouldAnimateWelcome,
                    onStart: advance
                )
                    .transition(.opacity)
            } else {
                wizard
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
    }

	var allSetView: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("You're all set!")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(Colormanager.Typography.primaryText)

            Text("Let's keep everything in balance, starting today.")
                .font(.system(size: 17, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Colormanager.Typography.secondaryText)
                .padding(.horizontal, 32)
			
			
			Button {
				begin()
			} label: {
				ZStack {
					Circle()
						.fill(.selected)
						.frame(width: 80)
					
					Image(systemName: "arrow.right")
						.resizable()
						.scaledToFit()
						.frame(width: 40)
						.foregroundStyle(.white)
				}
			}
			.buttonStyle(PressableButtonStyle())

            Spacer()

        }
        .padding()
    }
    
    // MARK: - Wizard scaffold

    private var wizard: some View {
		NavigationStack {
			VStack(alignment: .leading, spacing: 0) {
				header
				
				ScrollView {
					VStack(alignment: .leading, spacing: 24) {
						VStack(alignment: .leading, spacing: 8) {
							Text(step.title)
								.font(.system(size: 28, weight: .heavy))
								.foregroundStyle(Colormanager.Typography.primaryText)
							
							Text(step.subtitle)
								.font(.system(size: 16, weight: .medium))
								.foregroundStyle(Colormanager.Typography.secondaryText)
						}
						
						stepContent
					}
					.padding(.horizontal)
					.padding(.top, 24)
				}
				
			}
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button(action: goBack) {
						Image(systemName: "chevron.left")
							.font(.system(size: 18, weight: .bold))
							.foregroundStyle(Colormanager.Typography.primaryText)
					}
				}
				
				ToolbarItem(placement: .topBarTrailing) {
					Button(action: advance) {
						Image(systemName: "checkmark")
							.resizable()
							.renderingMode(.template)
							.scaledToFit()
							.foregroundStyle(.white)
							.opacity(draft.isValid(for: step) ? 1 : 0.4)
					}
					.disabled(!draft.isValid(for: step))
					.buttonStyle(.glassProminent)
					.tint(.selected)
				}
			}
		}
    }

    private var header: some View {
        VStack(spacing: 16) {
			
			ProgressView(value: step.progress)
				.tint(Colormanager.Accent.selected)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            EmptyView()
        case .name:
            NameStepView(name: $draft.name)
        case .gender:
            GenderStepView(gender: $draft.gender)
        case .age:
            AgeStepView(age: $draft.age)
        case .height:
            MeasurementStepView(value: $draft.heightCm, unit: "cm", placeholder: "170")
        case .weight:
            MeasurementStepView(value: $draft.weightKg, unit: "kg", placeholder: "65")
        case .activity:
            ActivityLevelStepView(activityLevel: $draft.activityLevel)
        case .nutritionGoal:
            NutritionGoalStepView(goal: $draft.nutritionGoal)
        }
    }

    private var continueButton: some View {
        Button(action: advance) {
            Text(step.isLast ? "Finish" : "Continue")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Colormanager.Accent.button)
                )
                .opacity(draft.isValid(for: step) ? 1 : 0.4)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!draft.isValid(for: step))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Navigation

    private func advance() {
        if step.isLast {
			dismissKeyboard()
            finish()
        } else if let next = step.next() {
			if next == .gender { dismissKeyboard() }
            withAnimation(.easeInOut) { step = next }
        }
    }

    private func goBack() {
        if let previous = step.previous() {
            withAnimation(.easeInOut) { step = previous }
        }
    }

    // MARK: - Persistence

    private func finish() {
        let profile = UserProfile(context: context)
        profile.id = UUID()
        profile.createdAt = .now
        profile.displayName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.gender = draft.gender ?? .preferNotToSay
        profile.age = Int16(draft.age ?? 0)
        profile.height = draft.heightCm ?? 0
        profile.weight = draft.weightKg ?? 0
        profile.activityLevel = draft.activityLevel ?? .sedentary
        profile.nutritionGoal = draft.nutritionGoal ?? .maintain
        profile.userType = "free"

        // The profile records the initial answer, while WeightEntry gives the
        // Weight screen a current value and the first point in its trend.
        if let initialWeight = draft.weightKg {
            let entry = WeightEntry(context: context)
            entry.id = UUID()
            entry.weight = initialWeight
            entry.createdAt = .now
            entry.updatedAt = .now
        }

        do {
            try context.save()

            withAnimation(.easeInOut(duration: 0.35)) {
                showAllSet = true
            }
        } catch {
            // Leave the flag unset so onboarding is retried on next launch.
            print("Failed to save UserProfile during onboarding: \(error)")
        }
    }

    private func begin() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView(shouldAnimateWelcome: true)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	//
}
