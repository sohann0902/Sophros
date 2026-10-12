//
//  CalendarOverlay.swift
//  Sophros
//
//  Created by Sohan Maurya on 01/09/26.
//

import SwiftUI

struct CalendarOverlay: View {
    @Binding var selectedWeek: Date
    @Binding var isPresented: Bool

    let calendar: Calendar
	let backgroundColor: Color
	let tintColor: Color

    @State private var pickedDate: Date

    init(
        selectedWeek: Binding<Date>,
        isPresented: Binding<Bool>,
        calendar: Calendar,
		background: Color,
		tint: Color
    ) {
        _selectedWeek = selectedWeek
        _isPresented = isPresented
        self.calendar = calendar
        _pickedDate = State(initialValue: selectedWeek.wrappedValue)
		self.backgroundColor = background
		self.tintColor = tint
    }

    var body: some View {
        VStack {
            
            DatePicker(
                "Select a day",
                selection: $pickedDate,
                displayedComponents: .date
            )
			.fontStyle(.body)
            .datePickerStyle(.graphical)
            .environment(\.calendar, calendar)
            .tint(tintColor.opacity(0.3))
            .colorMultiply(Colormanager.Typography.primaryText)

            Text("Week: \(weekRangeText)")
				.fontStyle(.footer)

        }
        .padding()
        .background(backgroundColor)
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .onChange(of: pickedDate) {
            selectedWeek = pickedDate
            isPresented = false
        }
        
    }

    private var weekRangeText: String {
        guard let interval = calendar.dateInterval(
            of: .weekOfYear,
            for: pickedDate
        ) else {
            return ""
        }

        let endDate = interval.end.addingTimeInterval(-1)

        return "\(interval.start.formatted(.dateTime.month(.abbreviated).day())) – \(endDate.formatted(.dateTime.month(.abbreviated).day()))"
    }
}

#Preview {
	CalendarOverlay(selectedWeek: .constant(.now), isPresented: .constant(true), calendar: .current, background: .green, tint: .black)
}
