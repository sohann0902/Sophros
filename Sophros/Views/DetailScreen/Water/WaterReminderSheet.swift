//
//  WaterReminderSheet.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI
import CoreData

struct WaterReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @Binding var detent: PresentationDetent

    @AppStorage("waterReminderEnabled") private var savedIsEnabled = false
    @AppStorage("waterReminderIntervalHours") private var savedIntervalHours = 1
    @AppStorage("waterReminderStartMinutes") private var savedStartMinutes = 8 * 60
    @AppStorage("waterReminderEndMinutes") private var savedEndMinutes = 20 * 60
    @AppStorage("waterReminderID") private var legacyReminderID = ""

    @State private var isEnabled = false
    @State private var intervalHours = 1
    @State private var startTime = Date()
    @State private var endTime = Date()

    private var hasValidWindow: Bool {
        minutesSinceMidnight(startTime) < minutesSinceMidnight(endTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(Colormanager.Water.deepBlue)
                    .frame(width: 42, height: 42)
                    .background(Colormanager.Water.lightBlue, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Water reminders")
						.fontStyle(.title)

                    Text("Get a gentle nudge during your day.")
						.fontStyle(.lightBody)
                }
            }

            Toggle("Remind me to drink water", isOn: $isEnabled)
				.fontStyle(.headline)
                .tint(Colormanager.Water.deepBlue)
                .onChange(of: isEnabled) { _, enabled in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        detent = enabled ? .fraction(0.5) : .fraction(0.28)
                    }
                }

            if isEnabled {
                HStack {
                    Text("Every")
						.fontStyle(.headline)
					Spacer()
                    Picker("Interval", selection: $intervalHours) {
                        ForEach(1...5, id: \.self) { hours in
                            Text(hours == 1 ? "1 hour" : "\(hours) hours").tag(hours)
								.fontStyle(.lightBody)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Colormanager.Water.deepBlue)
                }
                .padding(14)
                .background(Colormanager.card, in: RoundedRectangle(cornerRadius: 14))


                    HStack(spacing: 16) {
						
						Text("Reminder between")
							.fontStyle(.body)
                        
						DatePicker("From", selection: $startTime, displayedComponents: .hourAndMinute)
							.labelsHidden()
						
						DatePicker("To", selection: $endTime, displayedComponents: .hourAndMinute)
							.labelsHidden()
                    }
                    .tint(Colormanager.Water.deepBlue)

                    if !hasValidWindow {
                        Text("Choose an end time later than the start time.")
							.fontStyle(.caption)
                    }
            }

            Button(action: save) {
                Text("Save")
                    .foregroundStyle(.white)
					.fontStyle(.title)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Colormanager.Water.deepBlue,
                        in: RoundedRectangle(cornerRadius: 15)
                    )
            }
            .disabled(isEnabled && !hasValidWindow)
            .opacity(isEnabled && !hasValidWindow ? 0.45 : 1)
			.padding(.top)
			
        }
        .padding(20)
        .onAppear {
            isEnabled = savedIsEnabled
            intervalHours = savedIntervalHours
            startTime = date(for: savedStartMinutes)
            endTime = date(for: savedEndMinutes)
            detent = isEnabled ? .fraction(0.5) : .fraction(0.28)
        }
		.onDisappear{
			detent = .fraction(0.28)
		}
    }

    private func save() {
		HapticManager.medium()
        savedIsEnabled = isEnabled
        savedIntervalHours = intervalHours
        savedStartMinutes = minutesSinceMidnight(startTime)
        savedEndMinutes = minutesSinceMidnight(endTime)

        if isEnabled {
            WaterReminderNotificationService.sync(
                intervalHours: intervalHours,
                from: startTime,
                to: endTime
            )
        } else {
            WaterReminderNotificationService.cancel()
        }

        dismiss()
    }

    private func minutesSinceMidnight(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func date(for minutes: Int) -> Date {
        Calendar.current.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: .now
        ) ?? .now
    }
}
