//
//  FeatureOnboardingOverlay.swift
//  Sophros
//

import SwiftUI

/// A lightweight, first-use explanation or setup prompt shown over a feature.
struct FeatureOnboardingOverlay<Content: View>: View {
    let tint: Color
    let title: String
    let message: String
    let actionTitle: String
    let actionEnabled: Bool
    let content: Content
    let action: () -> Void
	let background: Color
	@Environment(\.dismiss) var dismiss

    init(
        tint: Color,
		background: Color,
        title: String,
        message: String,
        actionTitle: String = "Continue",
        actionEnabled: Bool = true,
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) {
        self.tint = tint
		self.background = background
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionEnabled = actionEnabled
        self.content = content()
        self.action = action
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {

                Text(title)
                    .fontStyle(.largeTitle)

                Text(message)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
					.fontStyle(.subheadline)

                content

                Button(action: action) {
                    Text(actionTitle)
                        .foregroundStyle(.white)
						.fontStyle(.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(background, in: RoundedRectangle(cornerRadius: 15))
                }
                .disabled(!actionEnabled)
                .opacity(actionEnabled ? 1 : 0.45)
            }
            .padding(24)
            .background(
				ZStack {
					Colormanager.card
					LinearGradient(colors: [
						tint.opacity(0.2),
						tint.opacity(0.1),
						tint.opacity(0.2),
						.clear
					], startPoint: .top, endPoint: .bottom)
				})
			.clipShape(
				RoundedRectangle(cornerRadius: 28, style: .continuous)
			)
            .padding(24)
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct OnboardingNumericField: View {
    let title: String
    let unit: String
    let placeholder: String
    @Binding var value: String
	@FocusState var isFocused

    var body: some View {
        HStack {
            Text(title)
                .fontStyle(.headline)

            Spacer()
            TextField(placeholder, text: $value)
				.fontStyle(.body)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 76)
				.focused($isFocused)
			
            Text(unit)
				.fontStyle(.footer)
			
        }
        .padding(14)
		.background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 13))
		.onAppear {
			isFocused = true
		}
    }
}


struct TextFieldOverlay<Content: View>: View {
	let tint: Color
	let title: String
	let message: String
	let actionTitle: String
	let actionEnabled: Bool
	let content: Content
	let action: () -> Void
	let background: Color
	@Binding var showing: Bool

	init(
		tint: Color,
		background: Color,
		title: String,
		message: String,
		actionTitle: String = "Continue",
		actionEnabled: Bool = true,
		@ViewBuilder content: () -> Content,
		action: @escaping () -> Void,
		showing: Binding<Bool>
	) {
		self.tint = tint
		self.background = background
		self.title = title
		self.message = message
		self.actionTitle = actionTitle
		self.actionEnabled = actionEnabled
		self.content = content()
		self.action = action
		self._showing = showing
	}

	var body: some View {
		ZStack {
			Color.black.opacity(0.52)
				.ignoresSafeArea()
				.onTapGesture {
					showing = false
				}

			VStack(alignment: .leading, spacing: 18) {
				
				if !title.isEmpty {
					Text(title)
						.fontStyle(.largeTitle)
				}

				if !message.isEmpty {
					Text(message)
						.fontStyle(.body)
				}

				content

				HStack {
					
					Button(action: cancelAction) {
						Text("Cancel")
							.foregroundStyle(.white)
							.fontStyle(.subheadline)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 15)
							.background(tint, in: RoundedRectangle(cornerRadius: 15))
					}
					
					
					Button(action: action) {
						Text(actionTitle)
							.foregroundStyle(.white)
							.fontStyle(.subheadline)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 15)
							.background(tint, in: RoundedRectangle(cornerRadius: 15))
					}
					.disabled(!actionEnabled)
					.opacity(actionEnabled ? 1 : 0.45)
				}
			}
			.padding(24)
			.background(
				ZStack {
					Colormanager.card
					LinearGradient(colors: [
						background.opacity(0.2),
						background.opacity(0.1),
						background.opacity(0.2),
						.clear
					], startPoint: .top, endPoint: .bottom)
				})
			.clipShape(
				RoundedRectangle(cornerRadius: 28, style: .continuous)
			)
			.padding(24)
		}
		.accessibilityAddTraits(.isModal)
	}
	
	private func cancelAction() {
		HapticManager.selection()
		showing = false
	}
}
