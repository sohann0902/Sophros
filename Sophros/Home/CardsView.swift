//
//  CardsView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI

struct CardsView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 2 x 3 
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(DashboardCard.cards) { card in
                            NavigationLink {
                                Navigator.openCardView(for: card)
                            } label: {
                                DashboardCardView(card: card, height: geometry.size.height / 4)
                            }
                            
                        }
                    }
                    
                    // 1 x 2
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(1...2, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.blue)
                                .frame(height: geometry.size.height / 4)
                        }
                    }
                }
                .padding()
            }
        }
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
