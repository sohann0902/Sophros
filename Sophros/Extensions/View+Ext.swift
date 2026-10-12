//
//  View+Ext.swift
//  Sophros
//
//  Created by Sohan Maurya on 11/09/26.
//

import SwiftUI

extension View {
	func dismissKeyboard() {
		UIApplication.shared.sendAction(
			#selector(UIResponder.resignFirstResponder),
			to: nil,
			from: nil,
			for: nil
		)
	}
	
	func fontStyle(_ style: AppFont, size: CGFloat? = nil) -> some View {
		self
			.font(
				.custom(
					style.fontName,
					size: size ?? style.fontSize
				)
			)
			.foregroundStyle(style.color)
	}
}
