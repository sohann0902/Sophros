//
//  MainTabView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
                HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "book.pages")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(Colormanager.Accent.selected)
        .toolbarBackgroundVisibility(.hidden, for: .tabBar)
    }
}


#Preview {
    MainTabView()
}
