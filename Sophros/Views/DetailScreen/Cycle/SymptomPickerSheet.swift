//
//  SymptomPickerSheet.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI

struct SymptomPickerSheet: View {
    let date: Date
    @State private var selectedKeys: Set<String>
    let onToggle: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 10)]

    init(date: Date, selectedKeys: Set<String>, onToggle: @escaping (String) -> Void) {
        self.date = date
        _selectedKeys = State(initialValue: selectedKeys)
        self.onToggle = onToggle
    }

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Colormanager.MenstrualCycle.mauve.opacity(0.18))
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Colormanager.MenstrualCycle.mauve)
                }
                .padding(.top, 10)

            Text("Symptoms")
                .padding(.top, 14)
                .foregroundStyle(Colormanager.MenstrualCycle.mauve)
				.fontStyle(.headline)

            Text("Choose everything that applies")
				.fontStyle(.footer)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(CycleSymptomOption.allCases) { symptom in
                        Button {
                            onToggle(symptom.key)
                            if selectedKeys.contains(symptom.key) {
                                selectedKeys.remove(symptom.key)
                            } else {
                                selectedKeys.insert(symptom.key)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(symptom.emoji)
                                Text(symptom.title).font(.subheadline.weight(.medium)).lineLimit(1)
                                Spacer(minLength: 0)
                                if selectedKeys.contains(symptom.key) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Colormanager.MenstrualCycle.mauve)
                                }
                            }
                            .padding(12)
                            .background(selectedKeys.contains(symptom.key) ? Colormanager.MenstrualCycle.mauve.opacity(0.16) : Colormanager.card)
                            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .stroke(selectedKeys.contains(symptom.key) ? Colormanager.MenstrualCycle.mauve.opacity(0.32) : .black.opacity(0.04), lineWidth: 1)
                            }
                        }
                        .foregroundStyle(Colormanager.Typography.primaryText)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 12)
                }
                .padding(.top, 20)
            }
            .mask{
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.1),
                    .init(color: .black, location: 0.9),
                    .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            }

			Button{
				dismiss()
				HapticManager.success()
			} label: {
                Text("Done")
                    .foregroundStyle(.white)
					.fontStyle(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Colormanager.MenstrualCycle.mauve)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
                .padding(.top, 14)
        }
        .padding(.horizontal, 24)
    }
}


enum CycleSymptomOption: String, CaseIterable, Identifiable {
	case cramps, headache, fatigue, cravings, bloating, acne, backache, insomnia
	case tenderBreasts = "tender_breasts"
	case moodSwings = "mood_swings"

	var id: String { rawValue }
	var key: String { rawValue }

	var title: String {
		switch self {
		case .cramps: "Cramps"
		case .headache: "Headache"
		case .fatigue: "Fatigue"
		case .cravings: "Cravings"
		case .bloating: "Bloating"
		case .acne: "Acne"
		case .backache: "Backache"
		case .insomnia: "Insomnia"
		case .tenderBreasts: "Tender breasts"
		case .moodSwings: "Mood swings"
		}
	}

	var emoji: String {
		switch self {
		case .cramps: "😣"
		case .headache: "😖"
		case .fatigue: "😴"
		case .cravings: "🍫"
		case .bloating: "🎈"
		case .acne: "🫧"
		case .backache: "🌀"
		case .insomnia: "🌙"
		case .tenderBreasts: "💗"
		case .moodSwings: "🎭"
		}
	}

	static func option(for key: String) -> CycleSymptomOption {
		CycleSymptomOption(rawValue: key) ?? .cramps
	}
}
