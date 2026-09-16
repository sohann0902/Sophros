//
//  PressableButtonStyle.swift
//  Sophros
//
//  Created by Sohan Maurya on 07/08/26.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.3), value: configuration.isPressed)
    }
}

struct SelectableListCell: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.frame(maxWidth: .infinity, alignment: .leading)
			.contentShape(Rectangle())
			.background {
				if configuration.isPressed {
					Color.primary.opacity(0.12)
				}
			}
	}
}
