//
//  StreakView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI

struct StreakView: View {
    @State var streakCount: Int
    
    var body: some View {
        
        Button {
            
        } label: {
            Text("\(streakCount)🔥")
                .font(.system(size: 16, weight: .heavy))
        }
        .buttonStyle(.glass)

    }
}

#Preview {
    StreakView(streakCount: 1)
}
