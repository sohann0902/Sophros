//
//  CreateWorkoutView.swift
//  Sophros
//
//  Created by Sohan Maurya on 11/08/26.
//

import SwiftUI
import CoreData

struct CreateWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
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
    
    @State private var title = ""
    @State private var note = ""
    @State private var exercises: [DraftWorkoutExercise] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var deleteConfirmation = DeleteConfirmation()
    
    private var allowAddExercise : Bool {
        return exercises.last?.name != ""
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "",
                        text: $title,
                        prompt: Text("Workout name eg. Push day")
                            .foregroundStyle(Colormanager.Typography.placeholder)
                    )
                    .foregroundStyle(Colormanager.Typography.primaryText)
                    .tint(Colormanager.Accent.button)

                    TextField(
                        "",
                        text: $note,
                        prompt: Text("Note (optional)")
                            .foregroundStyle(Colormanager.Typography.placeholder),
                        axis: .vertical
                    )
                    .foregroundStyle(Colormanager.Typography.primaryText)
                    .tint(Colormanager.Accent.button)
                    .lineLimit(0...4)
                }
                .listRowBackground(Colormanager.card)
                
                Section("Exercises") {
                    ForEach($exercises) { $exercise in
                        ExerciseEditorCard(exercise: $exercise)
                            .listRowBackground(Colormanager.card)
                            .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        Task {
                            guard await deleteConfirmation.confirm(
                                title: "Delete exercise?",
                                message: "This exercise will be removed from this workout.",
                                tint: Colormanager.Workout.terracotta
                            ) else { return }
                            exercises.remove(atOffsets: indexSet)
                        }
                    }
                }
                
                Section {
                    HStack(spacing: 12) {
                        Button {
                            exercises.append(DraftWorkoutExercise())
                        } label: {
                            Text("Add Exercise")
                                .font(.headline)
                                .foregroundStyle(Colormanager.Typography.primaryText)
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
                            saveTemplate()
                        } label: {
                            Text("Save")
                                .font(.headline)
                                .foregroundStyle(.white)
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
                        .buttonStyle(.borderless)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                
                Section("Workouts") {
                    ForEach(templates, id: \.objectID) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            HStack {
                                Text(template.title ?? "Untitled Workout")

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(
                                Colormanager.Typography.secondaryText
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                Task {
                                    guard await deleteConfirmation.confirm(
                                        title: "Delete workout?",
                                        message: "This saved workout and its exercises will be permanently removed.",
                                        tint: Colormanager.Workout.terracotta
                                    ) else { return }
                                    deleteTemplate(template: template)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
							.tint(Colormanager.Status.error)
                        }
                    }
                    .listRowBackground(Colormanager.card)
                }
                .colorMultiply(Colormanager.Typography.primaryText)
            }
            .scrollContentBackground(.hidden)
            .background(Colormanager.Workout.sand)
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(id: "closeCreateWorkout", placement: .topBarTrailing) {
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
            .alert("Could not save workout", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(item: $selectedTemplate) { template in
                WorkoutTemplateDetailView(template: template)
            }
        }
        .deleteConfirmationOverlay(deleteConfirmation)
    }

    private func saveTemplate() {
        let cleanedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let validExercises = exercises.filter {
            !$0.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        }

        guard !cleanedTitle.isEmpty else {
            errorMessage = "Please give your workout a name."
            showingError = true
            return
        }

        guard !validExercises.isEmpty else {
            errorMessage = "Add at least one exercise."
            showingError = true
            return
        }

        let template = WorkoutTemplate(context: viewContext)
        template.id = UUID()
        template.title = cleanedTitle
        template.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        template.createdAt = .now

        for (index, draft) in validExercises.enumerated() {
            let entry = WorkoutTemplateEntry(context: viewContext)
            entry.id = UUID()
            entry.name = draft.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            entry.sets = Int16(draft.sets)
            entry.reps = Int16(draft.reps)
            entry.weight = draft.weight
            entry.createdAt = .now.addingTimeInterval(Double(index))
            entry.template = template
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func deleteTemplate(template: WorkoutTemplate) {
        viewContext.delete(template)
        
        do {
            try viewContext.save()
        } catch {
            print("Could not delete water entry: \(error.localizedDescription)")
        }
    }
}


#Preview {
    CreateWorkoutView()
        .environment(
            \.managedObjectContext,
            PersistenceController.preview.container.viewContext
        )
}
