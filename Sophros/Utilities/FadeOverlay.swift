//
//  FadeOverlay.swift
//  Sophros
//
//  Created by Sohan Maurya on 11/09/26.
//

import SwiftUI

struct FadeOverlay<Content: View>: View {
	@Binding private var isPresented: Bool
	private let duration: Double
	private let content: Content

	@State private var isMounted: Bool
	@State private var opacity: Double

	init(
		isPresented: Binding<Bool>,
		duration: Double = 0.2,
		@ViewBuilder content: () -> Content
	) {
		_isPresented = isPresented
		self.duration = duration
		self.content = content()
		_isMounted = State(initialValue: isPresented.wrappedValue)
		_opacity = State(initialValue: isPresented.wrappedValue ? 1 : 0)
	}

	var body: some View {
		Group {
			if isMounted {
				content
					.opacity(opacity)
			}
		}
		.onChange(of: isPresented) { _, isNowPresented in
			isNowPresented ? present() : dismiss()
		}
	}

	private func present() {
		guard !isMounted else { return }
		opacity = 0
		isMounted = true

		Task {
			await Task.yield()
			guard isPresented else { return }
			withAnimation(.easeInOut(duration: duration)) {
				opacity = 1
			}
		}
	}

	private func dismiss() {
		withAnimation(.easeInOut(duration: duration)) {
			opacity = 0
		}

		Task {
			try? await Task.sleep(for: .seconds(duration))
			guard !isPresented else { return }
			isMounted = false
		}
	}
}
