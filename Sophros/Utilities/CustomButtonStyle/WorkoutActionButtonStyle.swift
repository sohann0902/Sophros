//
//  WorkoutActionButtonStyle.swift
//  Sophros
//
//  Created by Sohan Maurya on 11/08/26.
//

import SwiftUI

struct WorkoutActionButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
			.foregroundStyle(
				isPrimary ? .white : Colormanager.Workout.terracotta
			)
            .fontStyle(.headline)
            .padding(.vertical)
            .background(
                isPrimary
                    ? Colormanager.Workout.terracotta
                    : Colormanager.card
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
