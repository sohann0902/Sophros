//
//  HomeView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData

struct HomeView : View {

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: true)],
        animation: nil
    ) private var profiles: FetchedResults<UserProfile>

    private var greetingName: String {
        let name = profiles.first?.name ?? ""
        return name.isEmpty ? "there" : name
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in

                ZStack(alignment: .topLeading) {
                    Colormanager.baseBackground
                        .ignoresSafeArea()

                    //titleView
                    VStack(alignment: .leading) {

                        HStack(alignment: .top) {
                            Text("Welcome back,\n\(greetingName)")
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
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
