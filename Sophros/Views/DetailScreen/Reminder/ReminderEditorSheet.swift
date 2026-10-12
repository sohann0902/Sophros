//
//  ReminderEditorSheet.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI
import CoreData

struct ReminderEditorSheet: View {
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
				.scrollIndicators(.hidden)
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

extension Date {
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
