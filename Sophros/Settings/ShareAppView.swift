//
//  ShareAppView.swift
//  Sophros
//
//  Created by Sohan Maurya on 17/09/26.
//

import SwiftUI

struct ShareAppView: View {
	var body: some View {
		ZStack {
			Colormanager.card
			
			VStack(alignment: .leading) {
				Text("Share Feedback")
					.font(.largeTitle)
					.fontWeight(.heavy)
					.padding()
				
				Text("""
					Have a suggestion, found a problem, or just want to share your thoughts?

					I'd love to hear from you. Your feedback helps me make Sophros better. 
					""")
				.padding()
				
				Text("Send Feedback")
					.padding(.horizontal)
				
				Link(destination: URL(string: "mailto:support.sophros.app@gmail.com")!) {
					Text("support.sophros.app@gmail.com")
				}
				.tint(Colormanager.Water.deepBlue)
				.padding(.horizontal)
				
				Spacer()
			}
			.frame(maxWidth: .infinity)
			.multilineTextAlignment(.leading)
		}
	}
}


#Preview {
	ShareAppView()
}
