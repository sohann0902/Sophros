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

    @State private var step: OnboardingStep = .welcome
    @State private var draft = OnboardingDraft()

    var body: some View {
        ZStack {
            Colormanager.baseBackground
                .ignoresSafeArea()

            if step == .welcome {
                WelcomeStepView(onStart: advance)
                    .transition(.opacity)
            } else {
                wizard
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Wizard scaffold

    private var wizard: some View {
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

            continueButton
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Colormanager.Typography.primaryText)
                }
                .glassEffect()

                Spacer()
            }

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
            finish()
        } else if let next = step.next() {
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
            hasCompletedOnboarding = true
        } catch {
            // Leave the flag unset so onboarding is retried on next launch.
            print("Failed to save UserProfile during onboarding: \(error)")
        }
    }
}

#Preview {
    OnboardingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
