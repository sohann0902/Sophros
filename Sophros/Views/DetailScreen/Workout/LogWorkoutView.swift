//
//  LogWorkoutView.swift
//  Sophros
//
//  Created by Sohan Maurya on 11/08/26.
//

import SwiftUI
import CoreData

struct LogWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \WorkoutTemplate.title,
                ascending: true
            )
        ],
        animation: .default
    )
    private var templates: FetchedResults<WorkoutTemplate>

    @State private var selectedTemplateID: NSManagedObjectID?
    @State private var startedAt = Date()
    @State private var completedAt = Date()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var workoutDate: Date
    
    
    init(workoutDate: Date) {
        _workoutDate = State(initialValue: workoutDate)
    }

    private var selectedTemplate: WorkoutTemplate? {
        templates.first { $0.objectID == selectedTemplateID }
    }

    private var templateEntries: [WorkoutTemplateEntry] {
        guard let selectedTemplate else { return [] }

        return ((selectedTemplate.entries as? Set<WorkoutTemplateEntry>) ?? [])
            .sorted {
                ($0.createdAt ?? .distantPast) <
                ($1.createdAt ?? .distantPast)
            }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if templates.isEmpty {
                        Text("Create a workout first.")
							.fontStyle(.body)
                    } else {
                        Picker("Workout", selection: $selectedTemplateID) {
                            Text("Choose a workout")
                                .tag(nil as NSManagedObjectID?)

                            ForEach(templates, id: \.objectID) { template in
                                Text(template.title ?? "Untitled Workout")
                                    .tag(template.objectID as NSManagedObjectID?)
                            }
                        }
						.fontStyle(.body)
						.onChange(of: selectedTemplate) { oldValue, newValue in
							HapticManager.success()
						}
                    }
                }
                .colorMultiply(Colormanager.Typography.primaryText)
                .listRowBackground(Colormanager.card)

                if !templateEntries.isEmpty {
                    Section {
                        ForEach(templateEntries, id: \.objectID) { entry in
                            HStack {
                                Text(entry.name ?? "Exercise")

                                Spacer()

                                Text(
                                    "\(entry.sets) × \(entry.reps) · \(entry.weight, specifier: "%g") kg"
                                )
                                .foregroundStyle(.secondary)
                            }
							.fontStyle(.body)
                        }
					} header: {
						Text("Exercises")
							.foregroundStyle(Colormanager.Typography.secondaryText)
							.fontStyle(.headline)
					}
                }

                Section {
                    DatePicker(
                        "Date",
                        selection: $workoutDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "Start time",
                        selection: $startedAt,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "End time",
                        selection: $completedAt,
                        displayedComponents: .hourAndMinute
                    )
                    
                }
				.fontStyle(.body)
                .colorMultiply(Colormanager.Typography.primaryText)
                .listRowBackground(Colormanager.card)
                
                Section {
                        
                        Button {
                            logWorkout()
                        } label: {
                            Text("Log")
								.foregroundStyle(.white)
                                .fontStyle(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Colormanager.Workout.terracotta)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 18,
                                        style: .continuous
                                    )
                                )
                        }
                   
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .foregroundStyle(Colormanager.Typography.primaryText)
            .scrollContentBackground(.hidden)
            .background(Colormanager.Workout.sand)
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12)
                    }
                }
            }
            .alert("Could not log workout", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
			.dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
    }

    private func logWorkout() {
        guard let template = selectedTemplate else {
            errorMessage = "Choose a workout first."
            showingError = true
            return
        }
        
        let actualStart = combining(date: workoutDate, time: startedAt)
        let actualEnd = combining(date: workoutDate, time: completedAt)

        guard actualEnd > actualStart else {
            errorMessage = "The end time must be after the start time."
            showingError = true
            return
        }

        startedAt = actualStart
        completedAt = actualEnd

        let session = WorkoutSession(context: viewContext)
        session.id = UUID()
        session.title = template.title
        session.note = template.note
        session.createdAt = .now
        session.startedAt = startedAt
        session.completedAt = completedAt
        session.template = template

        for (index, templateEntry) in templateEntries.enumerated() {
            let entry = WorkoutEntry(context: viewContext)
            entry.id = UUID()
            entry.createdAt = .now.addingTimeInterval(Double(index))
            entry.name = templateEntry.name
            entry.sets = templateEntry.sets
            entry.reps = templateEntry.reps
            entry.weight = templateEntry.weight
            entry.session = session
        }

        do {
            try viewContext.save()
			HapticManager.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func combining(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeParts = calendar.dateComponents([.hour, .minute], from: time)

        return calendar.date(
            bySettingHour: timeParts.hour ?? 0,
            minute: timeParts.minute ?? 0,
            second: 0,
            of: date
        ) ?? date
    }
}

#Preview {
    LogWorkoutView(workoutDate: Date())
        .environment(
            \.managedObjectContext,
            PersistenceController.preview.container.viewContext
        )
}
