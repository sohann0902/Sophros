//
//  OnboardingModels.swift
//  Sophros
//
//  Created by Sohan Maurya on 07/09/26.
//

import Foundation

/// The ordered steps of the onboarding flow. `welcome` is the intro screen;
/// the remaining cases each collect one piece of profile information.
enum OnboardingStep: Int, CaseIterable {
    case welcome
    case name
    case gender
    case age
    case height
    case weight
    case activity
    case nutritionGoal

    /// Steps that make up the collect-info wizard (everything after the welcome screen).
    static var inputSteps: [OnboardingStep] {
        allCases.filter { $0 != .welcome }
    }

    var isLast: Bool {
        self == OnboardingStep.allCases.last
    }

    /// Fraction (0...1) used to drive the progress bar. `welcome` has no progress.
    var progress: Double {
        guard let index = OnboardingStep.inputSteps.firstIndex(of: self) else { return 0 }
        return Double(index + 1) / Double(OnboardingStep.inputSteps.count)
    }

    var title: String {
        switch self {
        case .welcome: return ""
        case .name: return "What should we call you?"
        case .gender: return "How do you identify?"
        case .age: return "How old are you?"
        case .height: return "How tall are you?"
        case .weight: return "What's your weight?"
        case .activity: return "How active are you?"
        case .nutritionGoal: return "What's your nutrition goal?"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return ""
        case .name: return "We'll use this to personalize your experience."
        case .gender: return "This helps tailor your health insights."
        case .age: return "Your age helps us set healthy targets."
        case .height: return "Measured in centimeters."
        case .weight: return "Measured in kilograms."
        case .activity: return "This helps us estimate your daily energy needs."
        case .nutritionGoal: return "We'll use this to personalize your nutrition targets."
        }
    }

    func next() -> OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    func previous() -> OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }
}

/// In-memory scratchpad for the values the user enters while onboarding.
/// Nothing is persisted until the flow finishes and a `UserProfile` is created.
struct OnboardingDraft {
    var name: String = ""
    var gender: Gender? = nil
    var age: Int? = nil
    var heightCm: Double? = nil
    var weightKg: Double? = nil
    var activityLevel: ActivityLevel? = nil
    var nutritionGoal: NutritionGoalType? = nil

    /// Whether the current step has a valid value, used to gate the Continue button.
    func isValid(for step: OnboardingStep) -> Bool {
        switch step {
        case .welcome:
            return true
        case .name:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .gender:
            return gender != nil
        case .age:
            guard let age else { return false }
            return (1...200).contains(age)
        case .height:
            return true
        case .weight:
            guard let _ = weightKg else { return false }
            return true
        case .activity:
            return activityLevel != nil
        case .nutritionGoal:
            return nutritionGoal != nil
        }
    }
}
