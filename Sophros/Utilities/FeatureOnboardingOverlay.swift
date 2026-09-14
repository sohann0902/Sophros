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
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
//                Image(systemName: icon)
//                    .font(.system(size: 30, weight: .bold))
//                    .foregroundStyle(tint)
//                    .frame(width: 58, height: 58)
//                    .background(tint.opacity(0.14), in: Circle())

                Text(title)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Colormanager.Typography.primaryText)

                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Colormanager.Typography.secondaryText)

                content

                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
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

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Colormanager.Typography.primaryText)
            Spacer()
            TextField(placeholder, text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 76)
                .font(.system(size: 17, weight: .bold))
            Text(unit)
                .foregroundStyle(Colormanager.Typography.secondaryText)
        }
        .padding(14)
		.background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 13))
    }
}
