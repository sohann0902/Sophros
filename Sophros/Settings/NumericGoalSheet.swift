//
//  NumericGoalSheet.swift
//  Sophros
//
//  Created by Sohan Maurya on 13/10/26.
//

import SwiftUI

struct NumericGoalSheet: View {

	let title: String

	@Binding var value: String

	var keyboardType: UIKeyboardType = .decimalPad

	var onConfirm: (String) -> Void

	@Environment(\.dismiss)
	private var dismiss


	var body: some View {

		VStack(spacing: 12) {
			
			Color.clear
				.frame(height: 30)
			
			Text(title)
				.fontStyle(.largeTitle)
				.padding(.top, 16)
			
			
			KeyboardTextField(
				text: $value,
				keyboardType: keyboardType,
				onConfirm: { currentText in
					
					onConfirm(currentText)
					
					dismiss()
				},
				onKeyboardDismiss: {
					
					dismiss()
				}
			)
			.frame(height: 80)
		}

		.presentationDetents([
			.height(160)
		])
	}
}
