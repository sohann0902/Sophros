//
//  MainTabView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//


import SwiftUI
import CoreData

struct MainTabView: View {
    var body: some View {
        TabView {
			HomeView()
			.tabItem {
				Label("Home", systemImage: "house.fill")
			}
            
			SettingsView()
			.tabItem {
				Label("Settings", systemImage: "gear")

			}
		}
		.tint(.logo)
        .toolbarBackgroundVisibility(.hidden, for: .tabBar)
        .preferredColorScheme(.light)
		.dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}


#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
