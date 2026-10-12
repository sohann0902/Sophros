//
//  WeightDetailView.swift
//  Sophros
//
//  Created by Sohan Maurya on 01/09/26.
//

import SwiftUI
import CoreData

struct WeightDetailView: View {
    let card: DashboardCard
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRange: WeightRange = .month
    @State private var showingLogWeight = false
    @State private var showingGoalEditor = false
    @State private var weightText = ""
    @State private var goalText = ""
    @State private var showingGoalOnboarding = false
    @State private var onboardingGoalText = ""
	
	@FocusState var focused

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeightEntry.createdAt, ascending: false)],
        animation: .easeInOut
    )
    
    private var entries: FetchedResults<WeightEntry>
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \WeightGoal.createdAt,
                ascending: false
            )
        ],
        animation: .default
    )
    
    private var weightGoals: FetchedResults<WeightGoal>

    private var currentWeight: Double? { entries.first?.weight }
    private var startingWeight: Double? { entries.last?.weight }
    private var goalWeight: Double? { weightGoals.first?.weight }
    private var remainingWeight: Double? {
        guard let currentWeight, let goalWeight else { return nil }
        return abs(goalWeight - currentWeight)
    }

    var body: some View {
        ZStack {
            Colormanager.baseBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    currentWeightHero
                    trendCard
                    
                Picker("Range", selection: $selectedRange) {
                    ForEach(WeightRange.allCases) { range in
                        Text(range.rawValue).tag(range)
							.fontStyle(.body)
                    }
                }
                .pickerStyle(.segmented)
                .symbolColorRenderingMode(.flat)
                .tint(.white)
				.colorMultiply(Colormanager.Calendar.green)
                .padding(.horizontal, 24)
				.onChange(of: selectedRange) {
					HapticManager.selection()
				}
					
					Button {
						showingLogWeight = true
					} label: {
						Text("Log weight")
							.foregroundStyle(.white)
							.fontStyle(.headline)
							.padding()
							.frame(maxWidth: .infinity)
							.background(Colormanager.Calendar.green)
							.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
					}
					.buttonStyle(PressableButtonStyle())
					.padding(.horizontal, 24)

                    goalCard
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
			
			FadeOverlay(isPresented: $showingGoalOnboarding) {
				FeatureOnboardingOverlay(
					tint: Colormanager.Calendar.green, background: Colormanager.Calendar.green,
					title: "Set your target weight",
					message: "Choose a weight you want to work toward. You can update this at any time.",
					actionTitle: "Save target",
					actionEnabled: validOnboardingGoal,
					content: {
						OnboardingNumericField(title: "Target weight", unit: "kg", placeholder: "65", value: $onboardingGoalText)
							.focused($focused)
					},
					action: saveOnboardingGoal
				)
			}
			
			FadeOverlay(isPresented: $showingLogWeight) {
				TextFieldOverlay(
					tint: Colormanager.Calendar.green, background: Colormanager.Calendar.green,
					title: "",
					message: "",
					actionTitle: "Log Weight",
					actionEnabled: !weightText.isEmpty && (Double(weightText) ?? 0) > 0,
					content: {
						OnboardingNumericField(title: "Weight", unit: "kg", placeholder: "50", value: $weightText)
							.focused($focused)
					},
					action: saveWeight, showing: $showingLogWeight
				)
			}
			
			FadeOverlay(isPresented: $showingGoalEditor) {
				TextFieldOverlay(
					tint: Colormanager.Calendar.green, background: Colormanager.Calendar.green,
					title: "Set goal",
					message: "Choose the weight you want to work toward.",
					actionTitle: "Save target",
					actionEnabled: !goalText.isEmpty && (Double(goalText) ?? 0) > 0,
					content: {
						OnboardingNumericField(title: "Weight in kg", unit: "kg", placeholder: "50", value: $goalText)
							.focused($focused)
						
					},
					action: setGoal, showing: $showingGoalEditor
				)
			}
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { showingGoalOnboarding = weightGoals.isEmpty }
    }

    private var currentWeightHero: some View {
        
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(currentWeight ?? 0, format: .number.precision(.fractionLength(1)))
						.fontStyle(.largeTitle, size: 52)
                    Text("kg")
						.fontStyle(.body)
                }
                
                
                Text("Current weight")
					.fontStyle(.footer)
            }
            .foregroundStyle(Colormanager.Calendar.green)

            Spacer()
            
        }
        .padding(.horizontal, 32)
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your journey")
				.fontStyle(.title)
            WeightTrendSection(range: selectedRange)
                .id(selectedRange)
                .frame(height: 230)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Colormanager.Calendar.green.opacity(0.22), Colormanager.Calendar.green.opacity(0.18), Colormanager.Calendar.green.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 24)
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your goal")
					.fontStyle(.headline)
				
                Spacer()
				
                Button {
                    goalText = String(format: "%.1f", goalWeight ?? 0)
                    showingGoalEditor = true
                } label: {
                    Image(systemName: "square.and.pencil.circle.fill")
						.foregroundStyle(Colormanager.Calendar.green)
						.fontStyle(.largeTitle)
                }
            }
            
            Spacer()
            
            HStack(alignment: .center) {
                VStack {
                    Text(goalWeight ?? 0, format: .number.precision(.fractionLength(1)))
						.fontStyle(.largeTitle, size: 42)
                    Text("kg")
						.fontStyle(.headline)
                }
                
                Spacer()
                
                if let startingWeight, let currentWeight, let goalWeight {
                    GoalJourney(
                        startingWeight: startingWeight,
                        currentWeight: currentWeight,
                        goalWeight: goalWeight
                    )
                    .frame(height: 100)
                }
                
            }

           
        }
        .foregroundStyle(Colormanager.Calendar.green)
        .padding(24)
        .background(
            LinearGradient(
                colors: [Colormanager.Calendar.green.opacity(0.22), Colormanager.Calendar.green.opacity(0.18), Colormanager.Calendar.green.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 24)
    }

    private func saveWeight() {
        guard let value = Double(weightText), value > 0 else { return }
        let entry = WeightEntry(context: context)
        entry.id = UUID()
        entry.weight = value
        entry.createdAt = .now
        entry.updatedAt = .now
        try? context.save()
        weightText = ""
		
		HapticManager.selection()
		showingLogWeight = false
		focused = false
    }

    private func setGoal() {
        guard let value = Double(goalText), value > 0 else { return }
        let goal = weightGoals.first ?? WeightGoal(context: context)
        if goal.id == nil {
            goal.id = UUID()
            goal.createdAt = .now
        }
        goal.weight = value
        goal.updatedAt = .now
        try? context.save()
        goalText = ""
		
		HapticManager.selection()
		showingGoalEditor = false
		focused = false
    }

    private var validOnboardingGoal: Bool {
        guard let value = Double(onboardingGoalText) else { return false }
        return value > 0
    }

    private func saveOnboardingGoal() {
        guard validOnboardingGoal else { return }
        goalText = onboardingGoalText
        setGoal()
        onboardingGoalText = ""
        showingGoalOnboarding = false
		focused = false
    }
}

#Preview {
    WeightDetailView(card: DashboardCard.cards.last!)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}





