//
//  SexLogSheet.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI

struct SexLogSheet: View {
	let date: Date
	let loggedType: CycleSexType?
	let onSelect: (CycleSexType?) -> Void
	
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				Circle()
					.fill(Colormanager.MenstrualCycle.mauve.opacity(0.18))
					.frame(width: 58, height: 58)
					.overlay {
						Image(systemName: "heart.fill")
							.font(.title3.weight(.semibold))
							.foregroundStyle(Colormanager.MenstrualCycle.mauve)
					}
					.padding(.top, 10)
				
				Text("Log your sexual activity")
					.fontStyle(.footer)
					.multilineTextAlignment(.center)
					.frame(maxWidth: 270)
					.padding(.top, 12)
				
				HStack(spacing: 12) {
					SexLogChoice(
						title: "Protected",
						symbol: "shield.fill",
						isSelected: loggedType == .protected
					) { select(loggedType == .protected ? nil : .protected) }
					SexLogChoice(
						title: "Unprotected",
						symbol: "heart.fill",
						isSelected: loggedType == .unprotected
					) { select(loggedType == .unprotected ? nil : .unprotected) }
				}
				.padding(.top, 22)
				
			}
			.padding(.horizontal, 24)
			.toolbar{
				ToolbarItem(placement: .topBarTrailing){
					SheetCloseButton(action: dismiss.callAsFunction)
				}
				.sharedBackgroundVisibility(.hidden)
			}
		}
	}
	
	private func select(_ type: CycleSexType?) {
		onSelect(type)
		dismiss()
	}
}


struct SexLogChoice: View {
	let title: String
	let symbol: String
	let isSelected: Bool
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			VStack(spacing: 9) {
				Image(systemName: symbol)
					.font(.title3.weight(.semibold))
				Text(title)
			}
			.foregroundStyle(isSelected ? .white : Colormanager.Typography.primaryText)
			.fontStyle(.body)
			.frame(maxWidth: .infinity)
			.padding(.vertical, 17)
			.background(isSelected ? Colormanager.MenstrualCycle.mauve : Colormanager.card)
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			.overlay {
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.stroke(isSelected ? Color.clear : Colormanager.MenstrualCycle.mauve.opacity(0.16), lineWidth: 1)
			}
		}
		.buttonStyle(.plain)
	}
}
