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
                                    Label("Delete", systemImage: "trash")
                                }
								.tint(Colormanager.Status.error)
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
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
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
                .font(.title2)
                .foregroundStyle(Colormanager.Accent.button)

            Text(selectedList == .upcoming ? "No upcoming reminders" : "No completed reminders yet")
                .font(.headline)
                .foregroundStyle(Colormanager.Typography.primaryText)

            Text(selectedList == .upcoming ? "Add a reminder to keep your day on track." : "Completed reminders will appear here.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Colormanager.Typography.secondaryText)
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
        HStack(spacing: 14) {
            Button(action: toggleCompletion) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? Colormanager.Reminder.periwinkle : Colormanager.Typography.secondaryText)
            }
            .buttonStyle(.borderless)


            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title ?? "Untitled reminder")
                    .font(.headline)
                    .strikethrough(isCompleted, color: Colormanager.Typography.secondaryText)
                    .foregroundStyle(isCompleted ? Colormanager.Typography.secondaryText : Colormanager.Typography.primaryText)

                if let dueAt = reminder.dueAt {
                    Text(dueAt.reminderDisplayText)
                        .font(.subheadline)
                        .foregroundStyle(Colormanager.Typography.secondaryText)
                }
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

private struct ReminderEditorSheet: View {
    let reminder: Reminder?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    @State private var title: String
    @State private var hasDueDate: Bool
    @State private var dueAt: Date
    @State private var repeatRule: ReminderRepeatRule
    @FocusState private var isTitleFocused: Bool

    init(reminder: Reminder?) {
        self.reminder = reminder
        _title = State(initialValue: reminder?.title ?? "")
        _hasDueDate = State(initialValue: reminder?.dueAt != nil)
        _dueAt = State(initialValue: reminder?.dueAt ?? .now)
        _repeatRule = State(initialValue: reminder?.repeatRule ?? .never)
    }

    private var isEditing: Bool {
        reminder != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Colormanager.baseBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reminder")
                                .font(.headline)
                                .foregroundStyle(Colormanager.Typography.primaryText)

                            TextField(
                                "What do you need to do?",
                                text: $title,
                                axis: .vertical
                            )
                                .textInputAutocapitalization(.sentences)
                                .focused($isTitleFocused)
                                .lineLimit(1...4)
                                .padding(16)
                                .background(Colormanager.card)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Toggle("Set date & time", isOn: $hasDueDate)
                                .font(.headline)
                                .tint(Colormanager.Accent.button)
                                .onChange(of: hasDueDate) { _, _ in
                                    isTitleFocused = false
                                }

                            if hasDueDate {
                                DatePicker(
                                    "Date & time",
                                    selection: $dueAt,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .padding(12)
                                .background(Colormanager.card)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .onChange(of: dueAt) { _, _ in
                                    isTitleFocused = false
                                }

                                HStack {
                                    Text("Repeat")
                                        .font(.headline)

                                    Spacer()

                                    Picker("Repeat", selection: $repeatRule) {
                                        ForEach(ReminderRepeatRule.allCases) { rule in
                                            Text(rule.title).tag(rule)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Colormanager.Accent.button)
                                }
                                .padding(16)
                                .background(Colormanager.card)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 16,
                                        style: .continuous
                                    )
                                )
                            }
                        }
                        .foregroundStyle(Colormanager.Typography.primaryText)
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let reminder = reminder ?? Reminder(context: context)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if reminder.id == nil {
            reminder.id = UUID()
            reminder.createdAt = .now
            reminder.sortOrder = nextSortOrder
        }

        reminder.title = trimmedTitle
        reminder.dueAt = hasDueDate ? dueAt : nil
        reminder.repeatRule = hasDueDate ? repeatRule : .never
        reminder.updatedAt = .now

        do {
            try context.save()

            if let id = reminder.id {
                ReminderNotificationService.syncNotification(
                    id: id,
                    title: trimmedTitle,
                    dueAt: reminder.dueAt,
                    repeatRule: reminder.repeatRule,
                    isCompleted: reminder.completedAt != nil
                )
            }
            dismiss()
			HapticManager.success()
        } catch {
            print("Could not save reminder: \(error.localizedDescription)")
        }
    }

    private var nextSortOrder: Double {
        let request = NSFetchRequest<Reminder>(entityName: "Reminder")
        request.predicate = NSPredicate(format: "completedAt == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.sortOrder, ascending: false)]
        request.fetchLimit = 1

        return ((try? context.fetch(request).first?.sortOrder) ?? -1) + 1
    }
}

private extension Date {
    var reminderDisplayText: String {
        let calendar = Calendar.current
        let time = formatted(date: .omitted, time: .shortened)

        if calendar.isDateInToday(self) {
            return "Today, \(time)"
        }
        if calendar.isDateInTomorrow(self) {
            return "Tomorrow, \(time)"
        }
        return formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}
