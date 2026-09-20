//
//  SettingsView.swift
//  Sophros
//

import SwiftUI
import CoreData


#Preview {
	SettingsView()
		.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


struct SettingsView: View {
	@Environment(\.managedObjectContext) private var context
	@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: true)],
		animation: .default
	)
	private var profiles: FetchedResults<UserProfile>
	
	@FetchRequest(sortDescriptors: [], animation: .default)
	private var nutritionGoals: FetchedResults<NutritionGoal>
	
	@State private var showingResetConfirmation = false
	@State private var deleteConfirmation = DeleteConfirmation()
	
	private var profile: UserProfile? { profiles.first }
	private var nutritionGoal: NutritionGoal? { nutritionGoals.first }
	
	var body: some View {
		NavigationStack {
			ZStack {
				Colormanager.baseBackground
					.ignoresSafeArea()
				
				List {
					Section {
						profileCard
					}
					
					Section {
						NavigationLink {
							if let nutritionGoal {
								NutritionSettings(nutritions: nutritionGoal)
							}
						} label: {
							nutritionCard
						}
					}
					
					Section {
						
						NavigationLink{
							ShareAppView()
						} label: {
							SettingsRow(
								icon: "ellipsis.bubble.fill",
								iconColor: Colormanager.Workout.terracotta,
								title: "Feedback",
								value: "We'd love to hear from you"
							)
						}
						
						NavigationLink {
							PrivacyView()
						} label: {
							SettingsRow(
								icon: "hand.raised.fill",
								iconColor: Colormanager.Accent.selected,
								title: "Privacy",
								value: "Your data stays on this device"
							)
						}
						
						NavigationLink {
							AboutAppView()
						} label: {
							SettingsRow(
								icon: "heart.fill",
								iconColor: Colormanager.MenstrualCycle.dustyRose,
								title: "Sophros",
								value: "Build healthy balance, one day at a time"
							)
						}
						
					}
					
					Section {
						
						
						SettingsRow(
							icon: "square.and.arrow.up",
							iconColor: Colormanager.Water.deepBlue,
							title: "Share App",
							value: "Share it with friends and family"
						)
					}
					
#if DEBUG
					Section {
						Button(role: .destructive) {
							Task {
								guard await deleteConfirmation.confirm(
									title: "Reset all app data?",
									message: "All health logs, reminders, goals, and app preferences will be permanently removed.",
									tint: Colormanager.Status.error
								) else { return }
								resetAppData()
							}
						} label: {
							HStack(spacing: 14) {
								Image(systemName: "trash.fill")
									.font(.headline)
									.foregroundStyle(Colormanager.Status.error)
									.frame(width: 34, height: 34)
									.background(Colormanager.Status.error.opacity(0.12))
									.clipShape(Circle())
								
								VStack(alignment: .leading, spacing: 3) {
									Text("Reset app data")
										.font(.body.weight(.semibold))
									Text("Clear Core Data and app preferences")
										.font(.caption)
								}
								.foregroundStyle(Colormanager.Status.error)
								
								Spacer(minLength: 0)
							}
							.padding(16)
							.contentShape(Rectangle())
						}
						.buttonStyle(.plain)
					}
#endif
					
				}
				.scrollContentBackground(.hidden)
				.listRowBackground(Color.clear)
			}
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.automatic)
			.onChange(of: nutritionGoal?.calorie) { oldValue, newValue in
				print("Calorie changed:", oldValue ?? 0, "→", newValue ?? 0)
			}
		}
		.deleteConfirmationOverlay(deleteConfirmation)
	}
	
	private var profileCard: some View {
		HStack(spacing: 16) {
			Text(profileInitials)
				.font(.title2.weight(.bold))
				.foregroundStyle(.white)
				.frame(width: 58, height: 58)
				.background(Colormanager.Accent.selected)
				.clipShape(Circle())
			
			VStack(alignment: .leading, spacing: 4) {
				Text(profileDisplayName)
					.font(.title3.weight(.bold))
					.foregroundStyle(Colormanager.Typography.primaryText)
				
				Text(profileDetails)
					.font(.subheadline)
					.foregroundStyle(Colormanager.Typography.secondaryText)
			}
			
			Spacer(minLength: 0)
		}
		.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
		.shadow(color: .black.opacity(0.04), radius: 10, y: 4)
	}
	
	private var profileInitials: String {
		let name = profile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		let initials = name.split(separator: " ").prefix(2).compactMap(\.first)
		return initials.isEmpty ? "S" : String(initials)
	}
	
	private var profileDisplayName: String {
		let name = profile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		return name.isEmpty ? "Your profile" : name
	}
	
	private var profileDetails: String {
		guard let profile else { return "Set up your health profile" }
		var details = [profile.gender.title]
		if profile.age > 0 { details.append("\(profile.age) years") }
		return details.joined(separator: " · ")
	}
	
	private var nutritionCard: some View {
		HStack(spacing: 14) {
			Image(systemName: "fork.knife")
				.font(.headline)
				.foregroundStyle(Colormanager.Diet.apricot)
				.frame(width: 34, height: 34)
				.background(Colormanager.Diet.apricot.opacity(0.12))
				.clipShape(Circle())
			
			VStack(alignment: .leading, spacing: 3) {
				Text("Daily targets")
					.font(.body.weight(.semibold))
					.foregroundStyle(Colormanager.Typography.primaryText)
				Text("\(Int(nutritionGoal?.calorie.rounded() ?? 0)) kcal per day")
					.font(.caption)
					.foregroundStyle(Colormanager.Typography.secondaryText)
					.lineLimit(1)
			}
			
			Spacer(minLength: 0)
		}
	}
	
	private var nutritionSummary: String {
		guard let nutritionGoal, nutritionGoal.calorie > 0 else {
			return "Not configured"
		}
		return "\(Int(nutritionGoal.calorie.rounded())) kcal per day"
	}
	
	private func resetAppData() {
		guard let entities = context.persistentStoreCoordinator?.managedObjectModel.entities else {
			return
		}
		
		do {
			for entity in entities {
				guard let entityName = entity.name else { continue }
				let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
				let objects = try context.fetch(request)
				objects.forEach(context.delete)
			}
			
			try context.save()
			
			if let bundleIdentifier = Bundle.main.bundleIdentifier {
				UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
			}
			hasCompletedOnboarding = false
		} catch {
			print("Failed to reset app data: \(error)")
		}
	}
}

private struct SettingsRow: View {
	let icon: String
	let iconColor: Color
	let title: String
	let value: String
	
	var body: some View {
		HStack(spacing: 14) {
			Image(systemName: icon)
				.font(.headline)
				.foregroundStyle(iconColor)
				.frame(width: 34, height: 34)
				.background(iconColor.opacity(0.12))
				.clipShape(Circle())
			
			VStack(alignment: .leading, spacing: 3) {
				Text(title)
					.font(.body.weight(.semibold))
					.foregroundStyle(Colormanager.Typography.primaryText)
				Text(value)
					.font(.caption)
					.foregroundStyle(Colormanager.Typography.secondaryText)
					.lineLimit(1)
			}
			
			Spacer(minLength: 0)
		}
	}
}
