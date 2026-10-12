//
//  WaterDetailView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData

struct WaterDetailView: View {
    let card : DashboardCard
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \WaterEntry.createdAt, ascending: false)
        ],
        animation: .default
    )
    private var entries: FetchedResults<WaterEntry>
    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    )
    private var goal: FetchedResults<WaterGoal>
    
    init(card: DashboardCard) {
        self.card = card
    }

    @State private var selectedDate = Date()
    @State private var showingCalendar = false
    @State private var showingGoalOnboarding = false
    @State private var goalInput = "2500"

    private var calendar: Calendar {
        Calendar.current
    }

    private var selectedDateEntries: [WaterEntry] {
        entries.filter { entry in
            guard let createdAt = entry.createdAt else { return false }
            return calendar.isDate(createdAt, inSameDayAs: selectedDate)
        }
    }
    
    private var dailyGoalML: Int {
        Int(goal.first?.amountML ?? 2500)
    }
    
    private var totalML: Int {
        Int(selectedDateEntries.reduce(0) { $0 + $1.amountML })
    }
    
    private var progress: Double {
        guard dailyGoalML > 0 else { return 0 }
        
        return (Double(totalML) / Double(dailyGoalML))
    }
    
    private var lastDrinkML: Int {
        Int(selectedDateEntries.first?.amountML ?? 0)
    }
    
    @State private var entryBeingEdited: WaterEntry?
    @State private var updateWaterEntry = false
    
    @State private var presentCustomEntryForm = false
    @State private var customWaterEntry : String = "250"

    @State private var deleteConfirmation = DeleteConfirmation()

	@State private var reminderSheet: Bool = false
    @State private var reminderSheetDetent: PresentationDetent = .fraction(0.28)
    
    private let waterAmounts = Array(stride(from: 0, through: 1000, by: 50))
    
    var body: some View {
            ZStack {
                Colormanager.baseBackground
                    .ignoresSafeArea()
                
                List {
                    datePicker
                    
                    Section {
                        VStack(spacing: 28) {
                            waterProgress
								.onTapGesture {
									showingGoalOnboarding = true
									HapticManager.medium()
								}
                            
                            HStack(spacing: 0) {
                                statistic(value: "\(lastDrinkML) ml", title: "Last Drink")
                                
                                Divider().frame(height: 80)
                                
                                statistic(value: "\(totalML / 250)", title: "Cups")
                                
                                Divider().frame(height: 80)
                                
                                statistic(
                                    value: "\(Int(progress * 100))%",
                                    title: "Goal"
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Quick Add")
									.fontStyle(.headline)
                                
                                    HStack(spacing: 12) {
                                        quickAddButton("250 ml", amount: 250)
                                        quickAddButton("500 ml", amount: 500)
                                        quickAddButton("1 L", amount: 1000)
                                        customAddButton()
                                    }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    Section {
						if selectedDateEntries.isEmpty {
							Text("No entries")
								.fontStyle(.body)
								.listRowBackground(Color.clear)
								.listRowSeparator(.hidden)
						}
						
                        ForEach(selectedDateEntries) { entry in
                            waterLogRow(entry)
                                .listRowInsets(
                                    EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16)
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        Task {
                                            guard await deleteConfirmation.confirm(
                                                title: "Delete water entry?",
                                                message: "This water entry will be removed.",
                                                tint: Colormanager.Water.deepBlue
                                            ) else { return }
                                            delete(entry)
                                        }
                                    } label: {
                                        Label("", systemImage: "trash")
                                    }
									.tint(Colormanager.Status.error)
                                }
                                .swipeActions(edge: .leading) {
                                                                    Button(role: .confirm) {
                                                                        update(entry)
                                                                    } label: {
                                                                        Label("", systemImage: "square.and.pencil")
                                                                    }
																	.tint(Colormanager.Water.deepBlue)
                                }
                        }
                    } header: {
                        Text("\(selectedDate.relativeDisplayText)'s Log")
							.fontStyle(.headline)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
				.safeAreaPadding(.bottom, 24)
				
				FadeOverlay(isPresented: $updateWaterEntry) {
					TextFieldOverlay(
						tint: Colormanager.Water.deepBlue, background: Colormanager.Water.lightBlue,
						title: "Update Quantity",
						message: "Enter the amount of water in ml",
						actionTitle: "Save",
						actionEnabled: !customWaterEntry.isEmpty && (Double(customWaterEntry) ?? 0) > 0,
						content: {
							OnboardingNumericField(title: "Amount", unit: "ml", placeholder: customWaterEntry, value: $customWaterEntry)
						},
						action: {
							update()
						}, showing: $updateWaterEntry
					)
				}
				
				FadeOverlay(isPresented: $presentCustomEntryForm) {
					TextFieldOverlay(
						tint: Colormanager.Water.deepBlue, background: Colormanager.Water.lightBlue,
						title: "Add Water",
						message: "Enter the amount of water in ml",
						actionTitle: "Save",
						actionEnabled: !customWaterEntry.isEmpty && (Double(customWaterEntry) ?? 0) > 0,
						content: {
							OnboardingNumericField(title: "Amount", unit: "ml", placeholder: customWaterEntry, value: $customWaterEntry)
						},
						action: {
							guard let customWaterEntry = Int(customWaterEntry), customWaterEntry > 0 else {
								return
							}
							
							addWater(customWaterEntry)
							
						}, showing: $presentCustomEntryForm
					)
				}

                FadeOverlay(isPresented: $showingCalendar) {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingCalendar = false
                            }

                        CalendarOverlay(
                            selectedWeek: $selectedDate,
                            isPresented: $showingCalendar,
                            calendar: calendar,
							background: Colormanager.Water.lightBlue,
							tint: Colormanager.Water.deepBlue
                        )
                        .padding(20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 44)
                    }
                }

                FadeOverlay(isPresented: $showingGoalOnboarding) {
                    FeatureOnboardingOverlay(
						tint: Colormanager.Water.skyBlue, background: Colormanager.Water.deepBlue,
                        title: "Set your water goal",
                        message: "Choose how much water you want to drink each day. You can change this anytime.",
                        actionTitle: "Save goal",
                        actionEnabled: validGoalInput,
                        content: {
                            OnboardingNumericField(title: "Daily intake", unit: "ml", placeholder: "2500", value: $goalInput)
                        },
                        action: saveGoal
                    )
                }
            }
            .navigationTitle("Water")
            .navigationBarTitleDisplayMode(.inline)
			.deleteConfirmationOverlay(deleteConfirmation)
			.toolbar(content: {
				ToolbarItem(placement: .topBarTrailing) {

					Button {
						reminderSheet = true
					} label: {
						Image(systemName: "bell")
							.resizable()
							.scaledToFit()
							.foregroundStyle(.white)
					}
					.buttonStyle(.glassProminent)
					.tint(Colormanager.Water.skyBlue.opacity(0.7))
					.disabled(isAlertPresenting)
				}
			})

			.sheet(isPresented: $reminderSheet, content: {
				WaterReminderSheet(detent: $reminderSheetDetent)
				.presentationDetents(
					[.fraction(0.28), .fraction(0.5)],
					selection: $reminderSheetDetent
				)
				.presentationDragIndicator(.hidden)
				.presentationCornerRadius(20)
				.presentationBackground(Colormanager.Water.skyBlue.opacity(0.2))
			})
            .onAppear { showingGoalOnboarding = goal.isEmpty }
    }
	
	private var isAlertPresenting : Bool {
		return showingCalendar || updateWaterEntry || presentCustomEntryForm || showingGoalOnboarding
	}
    private var validGoalInput: Bool {
        guard let amount = Int(goalInput) else { return false }
        return (250...10_000).contains(amount)
    }

    private func saveGoal() {
        guard let amount = Int(goalInput), (250...10_000).contains(amount) else { return }
		
		HapticManager.selection()
		
        let waterGoal = WaterGoal(context: context)
        waterGoal.id = UUID()
        waterGoal.amountML = Int64(amount)
        waterGoal.createdAt = .now
        waterGoal.updatedAt = .now
        try? context.save()
        showingGoalOnboarding = false
    }

    private var datePicker: some View {
        HStack {
            Spacer()
            Button {
                showingCalendar = true
            } label: {
                HStack(spacing: 8) {
                    Text(selectedDate.relativeDisplayText)
						.fontStyle(.body)

                    Image(systemName: "chevron.down")
						.fontStyle(.body)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Colormanager.card)
                .clipShape(Capsule())
            }
            Spacer()
        }
		.listRowBackground(Color.clear)
		.listRowSeparator(.hidden)
    }
    
    private var waterProgress: some View {
        ZStack {
            ActivityRingView(progress: progress)
            VStack(spacing: 8) {
                
                Text(litersText(totalML))
					.fontStyle(.largeTitle, size: 42)
					
                
                Text("of \(litersText(dailyGoalML))")
					.fontStyle(.lightBody)
            }
        }
        .padding()
    }
    
    private func statistic(value: String, title: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
				.fontStyle(.headline)
            
            Text(title)
				.fontStyle(.body)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func quickAddButton(_ title: String, amount: Int) -> some View {
        Button {
            addWater(amount)
			HapticManager.medium()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
				.fontStyle(.lightBody)
                .padding(.vertical, 18)
                .background(Colormanager.baseBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    private func customAddButton() -> some View {
        Button {
            addCustomWater()
        } label:  {
            Text("Custom")
                .frame(maxWidth: .infinity)
				.fontStyle(.lightBody)
                .padding(.vertical, 18)
                .background(Colormanager.baseBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    private func waterLogRow(_ entry: WaterEntry) -> some View {
        HStack(spacing: 14) {
            Image("droplet-icon")
				.resizable()
				.scaledToFit()
				.frame(height: 28)
            
            Text("\(Int(entry.amountML)) ml")
				.fontStyle(.body)
            
            Spacer()
            
            Text(entry.createdAt ?? .now, format: .dateTime.hour().minute())
				.fontStyle(.footer)
        }
        .padding()
        .background(Colormanager.baseBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.16), radius: 6, y: 2)
    }
    
    private func addWater(_ amount: Int) {
		HapticManager.medium()
		
        let entryDate: Date
        if calendar.isDateInToday(selectedDate) {
            entryDate = .now
        } else {
            let time = calendar.dateComponents([.hour, .minute, .second], from: .now)
            entryDate = calendar.date(
                bySettingHour: time.hour ?? 0,
                minute: time.minute ?? 0,
                second: time.second ?? 0,
                of: selectedDate
            ) ?? selectedDate
        }

        let entry = WaterEntry(context: context)
        entry.id = UUID()
        entry.note = "q"
        entry.source = .preset
        entry.amountML = Int64(amount)
        entry.createdAt = entryDate
        entry.updatedAt = .now
        
        do {
            try context.save()
			presentCustomEntryForm = false
			self.customWaterEntry = "250"
        } catch {
            print("Could not save water entry: \(error.localizedDescription)")
        }
    }
    
    private func addCustomWater() {
        presentCustomEntryForm = true
    }
    
    private func delete(_ entry: WaterEntry) {
        context.delete(entry)
        
        do {
            try context.save()
        } catch {
            print("Could not delete water entry: \(error.localizedDescription)")
        }
    }
    
    private func update() {
        guard let entry = entryBeingEdited else { return }
		HapticManager.medium()
        entry.amountML = Int64(customWaterEntry) ?? entry.amountML
        entry.updatedAt = .now
        
        do {
            try context.save()
			self.customWaterEntry = "250"
			updateWaterEntry = false
        } catch {
            print("Could not update water entry: \(error.localizedDescription)")
        }
    }
    
    private func update(_ entry: WaterEntry) {
        entryBeingEdited = entry
        customWaterEntry = String(entry.amountML)
        updateWaterEntry = true
    }
    
    private func litersText(_ milliliters: Int) -> String {
        String(format: "%.1f L", Double(milliliters) / 1000)
    }
}



#Preview {
	NavigationStack{
		WaterDetailView(card: DashboardCard.cards[0])
			.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	}
}
