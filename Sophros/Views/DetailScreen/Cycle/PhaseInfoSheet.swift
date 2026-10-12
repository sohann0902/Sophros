//
//  PhaseInfoSheet.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI

struct PhaseInfoSheet: View {
	let phase: CyclePhase?
	@Environment(\.dismiss) private var dismiss
	
	var phaseText: AttributedString {
		var text = AttributedString("It's likely you're in\n")
		
		var phaseTitle = AttributedString(phase?.title ?? "")
		phaseTitle.foregroundColor = UIColor(
			Colormanager.MenstrualCycle.dustyRose
		)
		
		text.append(phaseTitle)
		
		return text
	}
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					
					// MARK: - Cycle Illustration
					Image("CyclePhase")
						.resizable()
						.scaledToFit()
						.frame(maxWidth: .infinity)
						.padding(.horizontal, 4)
					
					
					// MARK: - Introduction
					
					VStack(alignment: .leading, spacing: 12) {
						
						Text(phaseText)
							.fontStyle(.largeTitle, size: 30)
							.multilineTextAlignment(.leading)
							.padding(.bottom)
						
						Text("Know Your Cycle")
							.fontStyle(.headline)
						
						Text("""
   Your menstrual cycle is a natural process in which your body moves through a series of hormonal changes. These changes prepare your body for a possible pregnancy and can also influence your energy, mood, appetite, sleep, and how you feel physically.
   
   A cycle is commonly described in four phases: menstrual, follicular, ovulation, and luteal. The length and experience of each phase can vary from person to person, and even from one cycle to the next.
   
   Think of these phases as a way to better understand your body, rather than as a strict schedule you need to follow.
   """)
						.fontStyle(.body)
						.lineSpacing(5)
					}
					
					
					// MARK: - Menstrual Phase
					
					CyclePhaseSection(
						title: "Menstrual Phase",
						subtitle: "A time to slow down and reset",
						text: """
   The menstrual phase begins on the first day of your period. During this time, the uterus sheds the lining it built during the previous cycle, resulting in menstrual bleeding. Estrogen and progesterone levels are relatively low, and some people may experience lower energy, cramps, bloating, headaches, or changes in mood.
   
   This can be a natural time to slow down and give your body some extra care. Prioritizing sleep, staying hydrated, and eating nourishing meals can help you feel supported. Gentle movement such as walking, stretching, or yoga may feel comfortable, but there is no need to exercise at a particular intensity if your body is asking for rest.
   """
					)
					
					
					// MARK: - Follicular Phase
					
					CyclePhaseSection(
						title: "Follicular Phase",
						subtitle: "Energy begins to rise",
						text: """
   The follicular phase begins on the first day of your period and continues until ovulation, which means it overlaps with the menstrual phase. During this phase, follicles in the ovaries develop as your body prepares an egg for ovulation. Estrogen gradually rises and the uterine lining begins to build again.
   
   As hormone levels change, some people notice that their energy, motivation, and mood begin to improve after their period. You may naturally feel more ready for activity or new challenges. Balanced meals, adequate hydration, regular movement, and good sleep can support your body as it moves toward ovulation.
   """
					)
					
					
					// MARK: - Ovulation Phase
					
					CyclePhaseSection(
						title: "Ovulation Phase",
						subtitle: "A moment of transition",
						text: """
   Ovulation occurs when an ovary releases a mature egg. This is triggered by a rise in luteinizing hormone and usually happens around the middle of the cycle, although the timing can vary considerably between people and between cycles.
   
   Some people notice increased energy, changes in cervical mucus, or mild pelvic discomfort around ovulation, while others may not notice any obvious changes at all. If you feel energetic during this time, you can continue with your usual activities and workouts. Your body does not need to be pushed simply because you are ovulating—how you feel is still the best guide.
   """
					)
					
					
					// MARK: - Luteal Phase
					
					CyclePhaseSection(
						title: "Luteal Phase",
						subtitle: "A time to nourish and recover",
						text: """
   The luteal phase begins after ovulation and continues until your next period. During this phase, progesterone rises as the body prepares for a possible pregnancy. If pregnancy does not occur, estrogen and progesterone eventually fall, which signals the beginning of the next menstrual period.
   
   You may notice changes in appetite, energy, mood, sleep, or physical comfort during this phase. Some people experience symptoms associated with premenstrual syndrome, such as bloating, breast tenderness, irritability, or fatigue, while others experience very few noticeable changes.
   
   This can be a good time to focus on nourishment, hydration, sleep, and recovery. Your appetite may change naturally, so rather than ignoring hunger, focus on balanced meals that provide protein, fiber, carbohydrates, healthy fats, and plenty of nutrients. Exercise can remain part of your routine, but adjusting the intensity according to your energy and comfort is completely okay.
   """
					)
					
					
					// MARK: - Your Cycle Is Unique
					
					VStack(alignment: .leading, spacing: 12) {
						
						Text("Your Cycle Is Unique")
							.fontStyle(.subheadline)
						
						Text("""
   There is no single way a menstrual cycle should feel. Cycle length, hormone patterns, symptoms, energy levels, and the timing of each phase can differ from person to person. Even your own cycle may not feel exactly the same every month.
   
   Use this information as a guide to become more aware of your body, not as a set of rules you have to follow. Listen to your energy, notice your patterns, and give your body what it needs.
   """)
						.fontStyle(.body)
						.lineSpacing(5)
					}
					
					
					// MARK: - Disclaimer
					
					VStack(alignment: .leading, spacing: 8) {
						
						Text("""
   This information is intended for general education and is not a substitute for medical advice. If you experience severe pain, unusually heavy bleeding, significant changes in your cycle, or symptoms that concern you, consider speaking with a qualified healthcare professional.
   """)
						.fontStyle(.caption)
					}
				}
				.padding()
			}
			.scrollIndicators(.hidden)
			.mask {
				LinearGradient(
					stops: [
						.init(color: .clear, location: 0),
						.init(color: .black, location: 0.05),
						.init(color: .black, location: 0.98),
						.init(color: .clear, location: 1)
					],
					startPoint: .top,
					endPoint: .bottom
				)
			}
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark")
					}
					.buttonStyle(.glassProminent)
					.tint(Colormanager.MenstrualCycle.dustyRose)
				}
			}
		}
		.presentationDetents([.medium, .large])
		.presentationBackground(Colormanager.card)
	}
}


struct CyclePhaseSection: View {
	
	let title: String
	let subtitle: String
	let text: String
	
	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			
			VStack(alignment: .leading, spacing: 4) {
				
				Text(title)
					.fontStyle(.headline)
				
				Text(subtitle)
					.foregroundStyle(Colormanager.MenstrualCycle.dustyRose)
					.fontStyle(.subheadline)
			}
			
			Text(text)
				.fontStyle(.body)
				.lineSpacing(5)
		}
	}
}
