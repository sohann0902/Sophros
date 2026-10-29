//
//  ShareFeedbackView.swift
//  Sophros
//
//  Created by Sohan Maurya on 17/09/26.
//

import SwiftUI

struct ShareFeedbackView: View {
	var body: some View {
		ZStack {
			Colormanager.card
			
			VStack(alignment: .leading) {
				Text("Share Feedback")
					.fontStyle(.largeTitle)
					.padding()
				
				Text("""
					Have a suggestion, found a problem, or just want to share your thoughts?

					I'd love to hear from you. Your feedback helps me make Sophros better. 
					""")
				.padding()
				
				Text("Send Feedback")
					.fontStyle(.subheadline)
					.padding(.horizontal)
				
				Link(destination: URL(string: "mailto:support.sophros.app@gmail.com")!) {
					Text("support.sophros.app@gmail.com")
				}
				.fontStyle(.subheadline)
				.tint(Colormanager.Water.deepBlue)
				.padding(.horizontal)
				
				Spacer()
			}
			.fontStyle(.body)
			.frame(maxWidth: .infinity)
			.multilineTextAlignment(.leading)
		}
	}
}


#Preview {
	ShareFeedbackView()
}
