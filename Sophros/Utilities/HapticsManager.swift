//
//  HapticsManager.swift
//  Sophros
//
//  Created by Sohan Maurya on 19/09/26.
//

import SwiftUI

enum HapticManager {

	static func light() {
		UIImpactFeedbackGenerator(style: .light).impactOccurred()
	}

	static func medium() {
		UIImpactFeedbackGenerator(style: .medium).impactOccurred()
	}

	static func heavy() {
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
	}

	static func success() {
		UINotificationFeedbackGenerator()
			.notificationOccurred(.success)
	}

	static func error() {
		UINotificationFeedbackGenerator()
			.notificationOccurred(.error)
	}

	static func warning() {
		UINotificationFeedbackGenerator()
			.notificationOccurred(.warning)
	}

	static func selection() {
		UISelectionFeedbackGenerator()
			.selectionChanged()
	}
}
