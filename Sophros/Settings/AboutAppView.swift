//
//  AboutAppView.swift
//  Sophros
//
//  Created by Sohan Maurya on 18/09/26.
//


import SwiftUI

struct AboutAppView: View {
	var body: some View {
		ScrollView {
			
			VStack(alignment: .leading, spacing: 16) {
				
				VStack(spacing: 0) {
					Image("App-logo")
						.resizable()
						.scaledToFit()
						.frame(width: 100)
						.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
						.padding(.horizontal)
						.padding(.top)
						.shadow(radius: 3)
					
					Image("Sophros")
						.resizable()
						.renderingMode(.template)
						.scaledToFit()
						.frame(height: 100)
						.foregroundStyle(Colormanager.Surfaces.logoColor)
				}
				.frame(maxWidth: .infinity, alignment: .center)
				
				Text("""
					I built Sophros because I wanted a simpler way to take care of different parts of my lifestyle in one place.

					When I looked at the apps I was using, different parts of staying healthy often lived in different places — one app for diet, another for workouts, another for water, and so on.

					I wanted to build something that brought these things together.

					Sophros is built around the idea of balance — helping you keep track of the different habits that contribute to a healthier lifestyle, without needing to manage everything across multiple apps.

					I'm building Sophros with the goal of making healthy habits feel more connected, simple, and manageable.

					Thanks for being part of the journey.
					""")
				
				Text("Sophros")
					.font(.headline)
				
				Text("Build healthy balance, one day at a time.")
					.italic()
					.padding(.top, -16)
				
			}
			.frame(maxWidth: .infinity)
			.padding()
			.multilineTextAlignment(.leading)
		}
	}
}

#Preview {
	AboutAppView()
}
