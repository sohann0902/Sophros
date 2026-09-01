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
        sessions.filter { session in
            guard let startedAt = session.startedAt else { return false }
            return weekInterval.contains(startedAt)
        }
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
    
    private func debugGroupedSessions() {
        print("\n----- GROUPED SESSIONS -----")

        for group in groupedSessions {
            print("Day:", group.day.formatted(
                .dateTime.weekday(.wide).month(.abbreviated).day()
            ))

            for session in group.sessions {
                print(
                    "  •",
                    session.title ?? "Untitled",
                    "| started:",
                    session.startedAt?.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ) ?? "no date"
                )
            }
        }

        print("----------------------------\n")
    }
    
    @State private var showingCalendar = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    weekPicker
                    summaryCard

                    if weeklySessions.isEmpty {
                        emptyState
                    } else {
                        sessionList
                    }

                    actionButtons
                }
                .padding()
                .padding(.bottom, 24)
            }
            .background(Colormanager.baseBackground.ignoresSafeArea())

            if showingCalendar {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingCalendar = false
                    }

                CalendarOverlay(
                    selectedWeek: $selectedWeek,
                    isPresented: $showingCalendar,
                    calendar: calendar
                )
                .padding(20)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingCalendar)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreateWorkout) {
            CreateWorkoutView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingLogWorkout) {
            LogWorkoutView(workoutDate: selectedWeek)
                .interactiveDismissDisabled()
        }
    }

    private var weekPicker: some View {
        HStack(spacing: 16) {
            Spacer()
            Button {
                showingCalendar = true
            } label: {
                HStack {
                    Text(
                        "\(weekInterval.start.formatted(.dateTime.month(.abbreviated).day())) – \(weekInterval.end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day()))"
                    )
                    .font(.headline)
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
                icon: "figure.strengthtraining.traditional"
            )

            Divider()
                .frame(height: 48)

            WorkoutSummaryMetric(
                value: durationText,
                label: "Total time",
                icon: "clock"
            )

            Divider()
                .frame(height: 48)

            WorkoutSummaryMetric(
                value: "\(exerciseCount)",
                label: "Exercises",
                icon: "dumbbell"
            )
        }
        .padding(.vertical, 18)
        .background(Colormanager.Workout.sand.opacity(0.55))
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var sessionList: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(groupedSessions, id: \.day) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        group.day.formatted(
                            .dateTime.weekday(.wide).month(.abbreviated).day()
                        )
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Colormanager.Typography.secondaryText)

                    ForEach(group.sessions, id: \.objectID) { session in
                        WorkoutSessionCard(session: session)
                    }
                }
            }
        }
        .onAppear {
            debugGroupedSessions()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundStyle(Colormanager.Workout.terracotta)

            Text("No workouts this week")
                .font(.headline)
                .foregroundStyle(Colormanager.Typography.primaryText)

            Text("Create a workout, then log it when you are ready.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Colormanager.Typography.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingCreateWorkout = true
            } label: {
                Label("Create Workout", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(WorkoutActionButtonStyle(isPrimary: false))

            Button {
                showingLogWorkout = true
            } label: {
                Label("Log Workout", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(WorkoutActionButtonStyle(isPrimary: true))
        }
    }
}

#Preview {
    WorkoutDetailView(card: DashboardCard.cards[1])
        .environment(
            \.managedObjectContext,
            PersistenceController.preview.container.viewContext
        )
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
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title ?? "Workout")
                        .font(.headline)
                        .foregroundStyle(Colormanager.Typography.primaryText)

                    if let startedAt = session.startedAt {
                        Text(timeRange(startedAt: startedAt))
                            .font(.caption)
                            .foregroundStyle(
                                Colormanager.Typography.secondaryText
                            )
                    }
                }

                Spacer()

                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Colormanager.Workout.terracotta)
            }

            ForEach(entries, id: \.objectID) { entry in
                HStack {
                    Text(entry.name ?? "Exercise")
                        .foregroundStyle(Colormanager.Typography.primaryText)

                    Spacer()

                    Text(
                        "\(entry.sets) × \(entry.reps) sets, \(entry.weight, specifier: "%g") kg"
                    )
                    .foregroundStyle(Colormanager.Typography.secondaryText)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Colormanager.card)
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
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))

            Text(value)
                .font(.headline.weight(.bold))

            Text(label)
                .font(.caption2)
        }
        .foregroundStyle(Colormanager.Typography.primaryText)
        .frame(maxWidth: .infinity)
    }
}
