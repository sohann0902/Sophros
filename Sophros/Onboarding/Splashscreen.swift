//
//  Splashscreen.swift
//  Sophros
//
//  Created by Sohan Maurya on 11/09/26.
//

import SwiftUI

struct Splashscreen : View {
	@State var animate: Bool = false
	let onFinished: () -> Void

    var body: some View {
        ZStack {
            Colormanager.baseBackground
				.ignoresSafeArea()
			
			VStack(spacing: 0) {
				Image("Sophros")
					.resizable()
					.renderingMode(.template)
					.scaledToFit()
					.frame(height: 200)
					.foregroundStyle(Colormanager.Surfaces.logoColor)
				
				Text("One app. Every part of you.")
					.foregroundStyle(Colormanager.Surfaces.logoColor)
					.fontStyle(.italic)
					.mask(
						GeometryReader { geometry in
							Rectangle()
								.frame(width: animate ? geometry.size.width : 0)
								.frame(maxWidth: .infinity, alignment: .leading)
						}
					)
					.offset(y: -60)
					
			}
        }
		.onAppear {
			Task {
				try? await Task.sleep(for: .seconds(0.5))
				
				withAnimation(.easeInOut(duration: 1.2)) {
					animate = true
				}
				
				// Wait for the animation to finish
				try? await Task.sleep(for: .seconds(1.8))
				//
				await MainActor.run {
					onFinished()
				}
			}
		}
    }
}

#Preview {
	Splashscreen {
		
	}
}


struct FlowerBloom: View {
	let shouldBloom: Bool
	@State private var bloom = false

	var body: some View {
		GeometryReader { geometry in
			Image("splash")
				.resizable()
				.scaledToFit()
				.frame(width: geometry.size.width * 0.9)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.scaleEffect(bloom ? 1.0 : 0.65)
				.rotationEffect(.degrees(bloom ? 0 : -5))
				.opacity(bloom ? 1 : 0)
				.animation(
					.spring(
						response: 1.6,
						dampingFraction: 0.7
					),
					value: bloom
				)
				.onAppear { startBloomIfNeeded() }
				.onChange(of: shouldBloom) { _, isVisible in
					if isVisible { startBloomIfNeeded() }
				}
		}
	}

	private func startBloomIfNeeded() {
		guard shouldBloom, !bloom else { return }
		bloom = true
	}
}
