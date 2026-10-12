//
//  PeriodLogSheet.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI

struct PeriodLogSheet: View {
	let date: Date
	let isPeriodLogged: Bool
	let onConfirm: () -> Void
	
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				Circle()
					.fill(Colormanager.MenstrualCycle.dustyRose.opacity(0.72))
					.frame(width: 58, height: 58)
					.overlay {
						Image(systemName: "drop.fill")
							.font(.title3.weight(.semibold))
							.foregroundStyle(Colormanager.MenstrualCycle.blush)
					}
					.padding(.top, 10)
				
				Text(isPeriodLogged
					 ? "This day is marked as a period day."
					 : "Mark selected date as a period day. You can log the remaining days as they happen.")
				.fontStyle(.footer)
				.multilineTextAlignment(.center)
				.lineLimit(5)
				.fixedSize(horizontal: false, vertical: true)
				.frame(maxWidth: 270)
				.padding(.top, 12)
				
				Button {
					onConfirm()
					dismiss()
				} label: {
					Label(
						isPeriodLogged ? "Remove period log" : "Log period",
						systemImage: isPeriodLogged ? "trash" : "drop.fill"
					)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 16)
				}
				.foregroundStyle(isPeriodLogged ? Colormanager.MenstrualCycle.dustyRose : .white)
				.fontStyle(.subheadline)
				.background(isPeriodLogged ? Colormanager.MenstrualCycle.blush.opacity(0.68) : Colormanager.MenstrualCycle.dustyRose)
				.clipShape(Capsule())
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
}
