//
//  RemindersDetailView.swift
//  Sophros
//
//  Created by Sohan Maurya on 21/08/26.
//

import SwiftUI
import CoreData

struct RemindersDetailView: View {
    let card: DashboardCard

    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Reminder.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Reminder.createdAt, ascending: true)
        ],
        predicate: NSPredicate(format: "completedAt == nil"),
        animation: .default
    )
    private var upcomingReminders: FetchedResults<Reminder>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Reminder.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Reminder.completedAt, ascending: false)
        ],
        predicate: NSPredicate(format: "completedAt != nil"),
        animation: .default
    )
    private var completedReminders: FetchedResults<Reminder>

    @State private var selectedList: ReminderList = .upcoming
    @State private var reminderBeingEdited: Reminder?
    @State private var showingNewReminder = false
    @State private var editMode: EditMode = .inactive
    @AppStorage("showRemindersOnboarding") private var showRemindersOnboarding = true
    @State private var deleteConfirmation = DeleteConfirmation()

    private var displayedReminders: [Reminder] {
        selectedList == .upcoming
            ? Array(upcomingReminders)
            : Array(completedReminders)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Colormanager.border
                .ignoresSafeArea()

            List {
                Picker("Reminder list", selection: $selectedList) {
                    ForEach(ReminderList.allCases) { list in
                        Text(list.title).tag(list)
							.fontStyle(.body)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
				.colorMultiply(Colormanager.Reminder.periwinkle)
				.onChange(of: selectedList) { oldValue, newValue in
					HapticManager.selection()
				}

                if displayedReminders.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(displayedReminders, id: \.objectID) { reminder in
                            ReminderRow(
                                reminder: reminder,
                                toggleCompletion: { toggleCompletion(for: reminder) }
                            ) {
                                reminderBeingEdited = reminder
                            }
                            .listRowInsets(
                                EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16)
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    Task {
                                        guard await deleteConfirmation.confirm(
                                            title: "Delete reminder?",
                                            message: "This reminder and its notification will be permanently removed.",
                                            tint: Colormanager.Reminder.periwinkle
                                        ) else { return }
                                        delete(reminder)
                                    }
                                } label: {
                                    Image(systemName: "trash.fill")
                                }
								.tint(Colormanager.Status.error)
								.fontStyle(.italic)
                            }
                        }
                        .onMove(perform: move)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $editMode)

            Button {
                showingNewReminder = true
				HapticManager.selection()
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(.white)
					.fontStyle(.largeTitle)
                    .frame(width: 58, height: 58)
                    .background(Colormanager.Reminder.periwinkle)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.trailing, 24)
            .padding(.bottom, 22)

			
			FadeOverlay(isPresented: $showRemindersOnboarding) {
                FeatureOnboardingOverlay(
					tint: Colormanager.Reminder.softPurple, background: Colormanager.Reminder.periwinkle,
                    title: "Stay on top of what matters",
                    message: "Add one-off or repeating reminders for habits, appointments, and anything you do not want to forget.",
                    content: { EmptyView() }
                ) {
                    showRemindersOnboarding = false
                }
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
		.deleteConfirmationOverlay(deleteConfirmation)
        .sheet(isPresented: $showingNewReminder) {
            ReminderEditorSheet(reminder: nil)
        }
        .sheet(item: $reminderBeingEdited) { reminder in
            ReminderEditorSheet(reminder: reminder)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: selectedList == .upcoming ? "checklist" : "checkmark.circle")
                .foregroundStyle(Colormanager.Reminder.periwinkle)
				.fontStyle(.largeTitle)

            Text(selectedList == .upcoming ? "No upcoming reminders" : "No completed reminders yet")
				.fontStyle(.headline)

            Text(selectedList == .upcoming ? "Add a reminder to keep your day on track." : "Completed reminders will appear here.")
                .multilineTextAlignment(.center)
				.fontStyle(.footer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Colormanager.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func toggleCompletion(for reminder: Reminder) {
        reminder.completedAt = reminder.completedAt == nil ? .now : nil
        reminder.updatedAt = .now
        save()
        context.processPendingChanges()
        syncNotification(for: reminder)
		HapticManager.success()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reorderedReminders = displayedReminders
        reorderedReminders.move(fromOffsets: source, toOffset: destination)

        for (index, reminder) in reorderedReminders.enumerated() {
            reminder.sortOrder = Double(index)
            reminder.updatedAt = .now
        }
        save()
    }

    private func delete(_ reminder: Reminder) {
        if let id = reminder.id {
            ReminderNotificationService.cancelNotification(for: id)
        }
        context.delete(reminder)
        save()
    }

    private func syncNotification(for reminder: Reminder) {
        guard let id = reminder.id else { return }
        ReminderNotificationService.syncNotification(
            id: id,
            title: reminder.title ?? "Reminder",
            dueAt: reminder.dueAt,
            repeatRule: reminder.repeatRule,
            isCompleted: reminder.completedAt != nil
        )
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("Could not save reminder: \(error.localizedDescription)")
        }
    }
}

#Preview {
    RemindersDetailView(card: DashboardCard.cards[3])
        .preferredColorScheme(.light)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)

}

private enum ReminderList: String, CaseIterable, Identifiable {
    case upcoming
    case completed

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

private struct ReminderRow: View {
    let reminder: Reminder
    let toggleCompletion: () -> Void
    let editReminder: () -> Void

    private var isCompleted: Bool {
        reminder.completedAt != nil
    }

    var body: some View {
		HStack( spacing: 14) {
			VStack(alignment: .leading, spacing: 4) {
				Button(action: toggleCompletion) {
					Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
						.foregroundStyle(isCompleted ? Colormanager.Reminder.periwinkle : Colormanager.Typography.secondaryText)
						.fontStyle(.headline)
				}
				.buttonStyle(.borderless)
				Spacer()
			}


            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title ?? "Untitled reminder")
					.fontStyle(.headline)
                    .strikethrough(isCompleted, color: Colormanager.Typography.secondaryText)
                    .foregroundStyle(isCompleted ? Colormanager.Typography.secondaryText : Colormanager.Typography.primaryText)

                if let dueAt = reminder.dueAt {
                    Text(dueAt.reminderDisplayText)
						.fontStyle(.footer)
                }
				
				Spacer()
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Colormanager.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(
            .dragPreview,
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .onTapGesture(perform: editReminder)
    }
}
