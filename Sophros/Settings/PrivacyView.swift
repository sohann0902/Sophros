//
//  PrivacyView.swift
//  Sophros
//
//  Created by Sohan Maurya on 17/09/26.
//

import SwiftUI

struct PrivacyView: View {
	var body: some View {
		
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					Text("Privacy")
						.fontStyle(.largeTitle)
						.padding(.bottom)
					
					
					Text("Last updated: September 2026")
						.fontStyle(.headline)
					
					Text("At Sophros, we believe your health and nutrition information should remain under your control. This Privacy Policy explains what information Sophros stores, how it is used, and the choices you have.")
					
					Text("Information You Provide")
						.fontStyle(.headline)
					
					Text("""
						Sophros may store information you enter into the app, such as your profile details, nutrition goals, meals, saved meals, and other preferences you choose to provide.

						This information is used to provide and personalize the features of Sophros, including calculating nutrition targets, displaying your progress, and helping you keep track of your meals.
						""")
					
					
					Text("How Your Data Is Stored")
						.fontStyle(.headline)
					
					Text("""
						Our app data is primarily stored locally on your device using Apple's local storage technologies.

						Sophros does not require you to create an account to use the app, and your locally stored information is not uploaded to a Sophros server unless a feature specifically indicates otherwise.
						""")
					
					Text("How We Use Your Information")
						.fontStyle(.headline)
					
					Text("""
						Information stored within Sophros is used to operate the app and provide its features. For example, your age, height, weight, and other profile information may be used to calculate personalized nutrition goals.

						Your meal and nutrition information is used to display your nutrition history and help you understand your daily intake.

						We do not use your personal information to sell products or build advertising profiles.
						""")
					
					Text("Sharing of Information")
						.fontStyle(.headline)
					
					Text("""
						Sophros does not sell your personal information.
						We do not share your personal nutrition or profile information with third parties for advertising purposes.
						If Sophros introduces features that require sending information to an external service, we will provide appropriate information about that feature and how your data is handled.
						""")
					
					Text("Device Permissions")
						.fontStyle(.headline)
					
					Text("""
						Sophros may request access to certain device features when a feature requires it. Permissions are requested through Apple's system controls, and you can change or revoke these permissions at any time through your device's Settings.
						Sophros only uses permissions for the functionality they are intended to support.
						""")
					
					Text("Changes to This Privacy Policy")
						.fontStyle(.headline)
					
					Text("""
						We may update this Privacy Policy when Sophros's features or data practices change. When we make changes, we will update the date shown at the top of this page.
						We encourage you to review this page periodically to stay informed about how your information is handled.

						""")
					
					
					Text("Contact Us")
						.fontStyle(.headline)
					
					Text("If you have questions, concerns, or requests regarding privacy or your data, you can contact us at")
					
					Text("support.sophros.app@gmail.com")
						.fontStyle(.subheadline)
					
				}
				.fontStyle(.body)
				.multilineTextAlignment(.leading)
				.padding()
				.dynamicTypeSize(...DynamicTypeSize.xxLarge)
			}
			.scrollIndicators(.hidden)
			.background(Colormanager.card)
			.frame(maxWidth: .infinity, alignment: .leading)
	}
}

#Preview {
	PrivacyView()
}
