//
//  CardsView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct CardsView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @State private var cards = DashboardCard.cards
    @State private var otherCards = DashboardCard.otherCards
    @State private var draggedCard: DashboardCard?
    @State private var isRearranging = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 2 x 3 
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(cards) { card in
                            cardView(card, height: geometry.size.height / 4)
                                .onDrop(
                                    of: [UTType.text],
                                    delegate: CardDropDelegate(
                                        destination: card,
                                        cards: $cards,
                                        draggedCard: $draggedCard,
                                        isRearranging: isRearranging
                                    )
                                )
                        }
                    }
                    
                    // 1 x 2
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(otherCards) { card in
                            cardView(card, height: geometry.size.height / 4)
                                .onDrop(
                                    of: [UTType.text],
                                    delegate: CardDropDelegate(
                                        destination: card,
                                        cards: $otherCards,
                                        draggedCard: $draggedCard,
                                        isRearranging: isRearranging
                                    )
                                )
                        }
                    }
                }
                .padding()
            }
        }
        .toolbar {
            if isRearranging {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isRearranging = false
                        draggedCard = nil
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func cardView(_ card: DashboardCard, height: CGFloat) -> some View {
        Group {
            if isRearranging {
                DashboardCardView(card: card, height: height)
            } else {
                NavigationLink {
                    Navigator.openCardView(for: card)
                } label: {
                    DashboardCardView(card: card, height: height)
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onLongPressGesture(minimumDuration: 0.45) {
            beginRearranging(card)
        }
        .onDrag {
            beginRearranging(card)
            draggedCard = card
            return NSItemProvider(object: card.id.uuidString as NSString)
        }
        .opacity(draggedCard?.id == card.id ? 0.55 : 1)
        .rotationEffect(isRearranging ? .degrees(card.id.uuidString.hashValue.isMultiple(of: 2) ? -1 : 1) : .zero)
        .animation(
            isRearranging
                ? .easeInOut(duration: 0.14).repeatForever(autoreverses: true)
                : .default,
            value: isRearranging
        )
    }

    private func beginRearranging(_ card: DashboardCard) {
        guard !isRearranging else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
            isRearranging = true
        }
    }
}

private struct CardDropDelegate: DropDelegate {
    let destination: DashboardCard
    @Binding var cards: [DashboardCard]
    @Binding var draggedCard: DashboardCard?
    let isRearranging: Bool

    func dropEntered(info: DropInfo) {
        guard
            isRearranging,
            let draggedCard,
            draggedCard.id != destination.id,
            let fromIndex = cards.firstIndex(where: { $0.id == draggedCard.id }),
            let toIndex = cards.firstIndex(where: { $0.id == destination.id })
        else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cards.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedCard = nil
        return true
    }
}


struct DashboardCardView: View {
    let card: DashboardCard
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: card.icon)
                .font(.headline)
                .foregroundStyle(card.iconColor)
                .frame(width: 34, height: 34)
                .background(card.iconColor.opacity(0.12))
                .clipShape(Circle())
            
            Spacer(minLength: 0)
            
            Text(card.title)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Colormanager.Typography.primaryText)
            
            Text(card.value)
                .font(.headline)
                .foregroundStyle(Colormanager.Typography.primaryText)
            
            if let progress = card.progress {
                ProgressView(value: progress)
                    .tint(card.iconColor)
                
                Text(card.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(card.iconColor)
            } else {
                Text(card.subtitle)
                    .font(.caption)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .padding(14)
        .background(Colormanager.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}
