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
}
