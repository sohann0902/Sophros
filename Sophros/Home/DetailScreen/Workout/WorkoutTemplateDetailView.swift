//
//  WorkoutTemplateDetailView.swift
//  Sophros
//
//  Created by Sohan Maurya on 12/08/26.
//

import SwiftUI
import CoreData

struct WorkoutTemplateDetailView: View {
    @ObservedObject var template: WorkoutTemplate

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var newExercises: [DraftWorkoutExercise] = []
    
    private var allowAddExercise : Bool {
        guard !newExercises.isEmpty else { return true }
        return newExercises.last?.name != ""
    }

    private var entries: [WorkoutTemplateEntry] {
        ((template.entries as? Set<WorkoutTemplateEntry>) ?? [])
            .sorted {
                ($0.createdAt ?? .distantPast) <
                ($1.createdAt ?? .distantPast)
            }
    }

    var body: some View {
        Form {
            Section {
                TextField(
                    "",
                    text: Binding(
                        get: { template.title ?? "" },
                        set: { template.title = $0 }
                    ),
                    prompt: Text("Workout name eg. Push day")
                        .foregroundStyle(
                            Colormanager.Typography.placeholder
                        )
                )
                .foregroundStyle(Colormanager.Typography.primaryText)
                .tint(Colormanager.Accent.button)

                TextField(
                    "",
                    text: Binding(
                        get: { template.note ?? "" },
                        set: { template.note = $0 }
                    ),
                    prompt: Text("Note (optional)")
                        .foregroundStyle(
                            Colormanager.Typography.placeholder
                        ),
                    axis: .vertical
                )
                .foregroundStyle(Colormanager.Typography.primaryText)
                .tint(Colormanager.Accent.button)
                .lineLimit(0...4)
            }
            .listRowBackground(Colormanager.card)

            if !entries.isEmpty || !newExercises.isEmpty {
                Section("Exercises") {
                    ForEach(entries, id: \.objectID) { entry in
                        WorkoutTemplateEntryEditor(entry: entry)
                            .foregroundStyle(Colormanager.Typography.secondaryText)
                    }
                    .onDelete(perform: deleteExercises)

                    ForEach($newExercises) { $exercise in
                        ExerciseEditorCard(exercise: $exercise)
                            .foregroundStyle(Colormanager.Typography.secondaryText)
                    }
                    .onDelete { offsets in
                        newExercises.remove(atOffsets: offsets)
                    }
                }
                .listRowBackground(Colormanager.card)
            }

            Section {
                HStack(spacing: 12) {
                    Button {
                        addExercise()
                    } label: {
                        Text("Add Exercise")
                            .font(.headline)
                            .foregroundStyle(
                                Colormanager.Typography.primaryText
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Colormanager.card)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 18,
                                    style: .continuous
                                )
                            )
                    }
                    .buttonStyle(.borderless)
                    .disabled(!allowAddExercise)
                    .opacity(allowAddExercise ? 1 : 0.5)

                    Button {
                        saveChanges()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Colormanager.Accent.button)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 18,
                                    style: .continuous
                                )
                            )
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .scrollContentBackground(.hidden)
        .background(Colormanager.Workout.sand)
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .alert("Could not save workout", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func addExercise() {
        newExercises.append(DraftWorkoutExercise())
    }

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(entries[index])
        }
    }

    private func saveChanges() {
        let validNewExercises = newExercises.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        let invalidNewExercises = newExercises.filter {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        if !invalidNewExercises.isEmpty {
            showingError = true
            errorMessage = "Please fill all values of Exercise."
            return
        }

        for (index, draft) in validNewExercises.enumerated() {
            let entry = WorkoutTemplateEntry(context: viewContext)
            entry.id = UUID()
            entry.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.sets = Int16(draft.sets)
            entry.reps = Int16(draft.reps)
            entry.weight = draft.weight
            entry.createdAt = .now.addingTimeInterval(Double(index))
            entry.template = template
        }
        dismiss()
    }
}


private struct WorkoutTemplateEntryEditor: View {
    @ObservedObject var entry: WorkoutTemplateEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField(
                "",
                text: Binding(
                    get: { entry.name ?? "" },
                    set: { entry.name = $0 }
                ),
                prompt: Text("Exercise name")
                    .foregroundStyle(
                        Colormanager.Typography.placeholder
                    )
            )
            .font(.title3.weight(.semibold))
            .foregroundStyle(Colormanager.Typography.primaryText)
            .tint(Colormanager.Accent.button)
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(Colormanager.secondaryBg)
            .clipShape(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        Colormanager.border.opacity(0.7),
                        lineWidth: 1
                    )
            }

            HStack(spacing: 10) {
                WorkoutNumberField(
                    title: "SETS",
                    value: Binding(
                        get: { Int(entry.sets) },
                        set: { entry.sets = Int16($0) }
                    ),
                    format: .number,
                    keyboardType: .numberPad
                )

                WorkoutNumberField(
                    title: "REPS",
                    value: Binding(
                        get: { Int(entry.reps) },
                        set: { entry.reps = Int16($0) }
                    ),
                    format: .number,
                    keyboardType: .numberPad
                )

                WorkoutNumberField(
                    title: "WEIGHT (kg)",
                    value: Binding(
                        get: { entry.weight },
                        set: { entry.weight = $0 }
                    ),
                    format: .number.precision(
                        .fractionLength(0...2)
                    ),
                    keyboardType: .decimalPad
                )
            }
        }
        .padding(14)
        .background(Colormanager.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }
}
