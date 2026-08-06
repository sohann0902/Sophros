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
                        ForEach(1...6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.red)
                                .frame(height: geometry.size.height / 4)
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
