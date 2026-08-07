//
//  HomeView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI

struct HomeView : View {
    
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                
                ZStack(alignment: .topLeading) {
                    Colormanager.baseBackground
                        .ignoresSafeArea()
                    
                    //titleView
                    VStack(alignment: .leading) {
                        
                        HStack(alignment: .top) {
                            Text("Welcome back,\nSohan")
                                .font(.system(size: 32, weight: .heavy))
                            
                            Spacer()
                            
                            StreakView(streakCount: 1)
                        }
                        .foregroundStyle(Colormanager.Typography.primaryText)
                        .padding()
                        
                        // dashboard
                        CardsView()
                        
                    }
                }
                
            }
        }
    }
}

#Preview {
    HomeView()
}
