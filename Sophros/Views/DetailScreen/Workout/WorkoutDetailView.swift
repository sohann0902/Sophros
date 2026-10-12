//
//  WorkoutDetailView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData

struct WorkoutDetailView: View {
	let card: DashboardCard
	
	@Environment(\.managedObjectContext) private var context
	
	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(
				keyPath: \WorkoutSession.startedAt,
				ascending: false
			)
		],
		animation: .default
	)
	
	private var sessions: FetchedResults<WorkoutSession>
	
	@FetchRequest(
		sortDescriptors: [
			NSSortDescriptor(
				keyPath: \WorkoutTemplate.createdAt,
				ascending: false
			)
		],
		animation: .default
	)
	
	private var templates: FetchedResults<WorkoutTemplate>
	
	@State private var selectedWeek = Date()
	@State private var showingCreateWorkout = false
	@State private var showingLogWorkout = false
	
	private var calendar: Calendar {
		var calendar = Calendar.current
		calendar.firstWeekday = 2 // Monday
		return calendar
	}
	
	private var weekInterval: DateInterval {
		calendar.dateInterval(of: .weekOfYear, for: selectedWeek)!
	}
	
	private var weeklySessions: [WorkoutSession] {
		let filtered = sessions.filter { session in
			guard let startedAt = session.startedAt else { return false }
			return weekInterval.contains(startedAt)
		}
		return filtered
	}
	
	private var totalDuration: TimeInterval {
		weeklySessions.reduce(0) { total, session in
			guard let startedAt = session.startedAt,
				  let completedAt = session.completedAt else {
				return total
			}
			
			return total + completedAt.timeIntervalSince(startedAt)
		}
	}
	
	private var durationText: String {
		let totalMinutes = Int(totalDuration / 60)
		let hours = totalMinutes / 60
		let minutes = totalMinutes % 60
		
		if hours > 0 {
			return "\(hours)h \(minutes)m"
		}
		
		return "\(minutes)m"
	}
	
	private var exerciseCount: Int {
		weeklySessions.reduce(0) { total, session in
			total + ((session.entries as? Set<WorkoutEntry>)?.count ?? 0)
		}
	}
	
	private var groupedSessions: [(day: Date, sessions: [WorkoutSession])] {
		let grouped = Dictionary(grouping: weeklySessions) { session in
			calendar.startOfDay(for: session.startedAt ?? .distantPast)
		}
		
		return grouped
			.map { day, sessions in
				(
					day: day,
					sessions: sessions.sorted {
						($0.startedAt ?? .distantPast) <
							($1.startedAt ?? .distantPast)
					}
				)
			}
			.sorted { $0.day < $1.day }
	}
	
	@State private var showingCalendar = false
	@AppStorage("WorkoutOnboard") private var showOnboarding = true
	
	@State private var deleteConfirmation = DeleteConfirmation()
	
	var body: some View {
		ZStack {
			Colormanager.baseBackground
				.ignoresSafeArea()
			
			VStack {
				weekPicker
				
				List {
					Section {
						
						summaryCard
					}
					.listRowSeparator(.hidden)
					.listRowBackground(Color.clear)
					.listRowInsets(.all, 0)
					
					
						
					if groupedSessions.isEmpty {
						Section {
							emptyState
								.listRowSeparator(.hidden)
								.listRowBackground(Color.clear)
								.listRowInsets(.all, 0)
						}
					} else {
						sessionList
					}
						
						Color.clear
							.frame(height: 76)
							.listRowSeparator(.hidden)
							.listRowBackground(Color.clear)
							.listRowInsets(.all, 0)
				}
				.scrollContentBackground(.hidden)
				
			}
			
			FadeOverlay(isPresented: $showingCalendar) {
				Color.black.opacity(0.25)
					.ignoresSafeArea()
					.onTapGesture {
						showingCalendar = false
					}
				
				CalendarOverlay(
					selectedWeek: $selectedWeek,
					isPresented: $showingCalendar,
					calendar: calendar,
					background: Colormanager.Workout.sand,
					tint: Colormanager.Workout.sand
				)
				.padding(20)
				.transition(.opacity)
			}
			
			VStack {
				Spacer()
				
				Button {
					showingLogWorkout = true
				} label: {
					Label("Log Workout", systemImage: "checkmark")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(WorkoutActionButtonStyle(isPrimary: true))
				.padding(.horizontal)
				.padding(.bottom, 12)
			}
			
			FadeOverlay(isPresented: $showOnboarding) {//
				FeatureOnboardingOverlay(
					tint: Colormanager.Workout.clay, background: Colormanager.Workout.terracotta,
					title: "Make workouts repeatable",
					message: "Create templates for the routines you love, then log them each day without rebuilding every exercise.",
					content: { EmptyView() }
				) {
					showOnboarding = false
				}
			}
			
		}
		.animation(.easeInOut(duration: 0.2), value: showingCalendar)
		.navigationTitle("Workout")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar(content: {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					showingCreateWorkout = true
				} label: {
					Image(systemName: "bookmark.fill")
				}
				.foregroundStyle(Colormanager.Workout.terracotta)
			}
		})
		.sheet(isPresented: $showingCreateWorkout) {
			CreateWorkoutView()
				.interactiveDismissDisabled()
		}
		.sheet(isPresented: $showingLogWorkout) {
			LogWorkoutView(workoutDate: selectedWeek)
				.interactiveDismissDisabled()
		}
		.deleteConfirmationOverlay(deleteConfirmation)
	}
	
	private var weekPicker: some View {
		HStack(spacing: 16) {
			Spacer()
			Button {
				showingCalendar = true
				HapticManager.selection()
			} label: {
				HStack {
					Text(
						"\(weekInterval.start.formatted(.dateTime.month(.abbreviated).day())) – \(weekInterval.end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day()))"
					)
					.fontStyle(.body)
					.foregroundStyle(Colormanager.Typography.primaryText)
					
					Image(systemName: "chevron.down")
						.font(.subheadline.weight(.bold))
						.tint(Colormanager.Accent.button)
				}
				.padding()
				.background(Colormanager.card)
				.clipShape(RoundedRectangle(cornerRadius: 30))
			}
			.glassEffect(.regular.interactive())
			
			Spacer()
		}
	}
	
	private var summaryCard: some View {
		HStack(spacing: 0) {
			WorkoutSummaryMetric(
				value: "\(weeklySessions.count)",
				label: "Workouts",
				icon: "workout-2"
			)
			
			Divider()
				.frame(height: 48)
			
			WorkoutSummaryMetric(
				value: durationText,
				label: "Total time",
				icon: "workout-3"
			)
			
			Divider()
				.frame(height: 48)
			
			WorkoutSummaryMetric(
				value: "\(exerciseCount)",
				label: "Exercises",
				icon: "workout-4"
			)
		}
		.padding(.vertical, 18)
		.background(Colormanager.Workout.sand.opacity(0.55))
		.clipShape(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
		)
	}
	
	private var sessionList: some View {
		ForEach(groupedSessions, id: \.day) { group in
			Section {
				ForEach(group.sessions, id: \.objectID) { session in
					VStack(alignment: .leading, spacing: 0) {
						WorkoutSessionCard(session: session)
					}
					.listRowBackground(Colormanager.card)
					.listRowInsets(.all, 0)
					.swipeActions(
						edge: .trailing,
						allowsFullSwipe: false
					) {
						Button {
							Task {
								guard await deleteConfirmation.confirm(
									title: "Delete workout session?",
									message: "This workout session will be permanently removed.",
									tint: Colormanager.Workout.terracotta
								) else {
									return
								}

								context.delete(session)
								do {
									try context.save()
								} catch {
									print("failed to delete session")
								}
								
							}
						} label: {
							Label("", systemImage: "trash")
								.tint(Colormanager.Status.error)
						}
					}
				}
			} header: {
				Text(
					group.day.formatted(
						.dateTime
							.weekday(.wide)
							.month(.abbreviated)
							.day()
					)
				)
				.foregroundStyle(
					Colormanager.Typography.secondaryText
				)
				.fontStyle(.headline)
				.textCase(nil)
				.frame(
					maxWidth: .infinity,
					alignment: .leading
				)
				.padding(.vertical, 6)
			}
		}
	}
	
	private var emptyState: some View {
		VStack(spacing: 10) {
			
			Text("No workouts this week")
				.fontStyle(.headline)
			
			Text("Create a workout, then log it when you are ready.")
				.foregroundStyle(Colormanager.Typography.secondaryText)
				.fontStyle(.subheadline)
				.multilineTextAlignment(.center)
				
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 28)
		.background(Colormanager.card)
		.clipShape(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
		)
	}
}

#Preview {
	NavigationStack {
		WorkoutDetailView(card: DashboardCard.cards[1])
			.environment(
				\.managedObjectContext,
				 PersistenceController.preview.container.viewContext
			)
	}
}

private struct WorkoutSessionCard: View {
	let session: WorkoutSession
	
	private var entries: [WorkoutEntry] {
		((session.entries as? Set<WorkoutEntry>) ?? [])
			.sorted {
				($0.createdAt ?? .distantPast) <
					($1.createdAt ?? .distantPast)
			}
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .top) {
					Text(session.title ?? "Workout")
						.fontStyle(.headline)
				Spacer()
				
				if let startedAt = session.startedAt {
					Text(timeRange(startedAt: startedAt))
						.fontStyle(.footer)
				}
			}
			
			ForEach(entries, id: \.objectID) { entry in
				HStack {
					Text(entry.name ?? "Exercise")
						.fontStyle(.body)
					
					Spacer()
					
					Text(
						"\(entry.sets) × \(entry.reps) sets, \(entry.weight, specifier: "%g") kg"
					)
					.foregroundStyle(Colormanager.Typography.secondaryText)
					.fontStyle(.body)
				}
				.font(.subheadline)
			}
		}
		.padding()
		.clipShape(
			RoundedRectangle(cornerRadius: 18, style: .continuous)
		)
	}
	
	private func timeRange(startedAt: Date) -> String {
		let start = startedAt.formatted(date: .omitted, time: .shortened)
		
		guard let completedAt = session.completedAt else {
			return "Started \(start)"
		}
		
		let end = completedAt.formatted(date: .omitted, time: .shortened)
		return "\(start) – \(end)"
	}
}

private struct WorkoutSummaryMetric: View {
	let value: String
	let label: String
	let icon: String
	
	var body: some View {
		VStack {
			Image(icon)
				.resizable()
				.scaledToFit()
				.frame(width: 44)
				.padding(.bottom)
			
			Text(label)
				.fontStyle(.footer)
			Text(value)
				.fontStyle(.body)
		}
		.foregroundStyle(Colormanager.Typography.primaryText)
		.frame(maxWidth: .infinity)
	}
}
