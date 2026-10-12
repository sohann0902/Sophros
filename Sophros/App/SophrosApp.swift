//
//  SophrosApp.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData
import UserNotifications

@main
struct SophrosApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        UNUserNotificationCenter.current().delegate = ReminderNotificationDelegate.shared
		
		setNavBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
				.dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
    }
	
	
	func setNavBarAppearance() {
		let appearance = UINavigationBarAppearance()
		
		// 1. Font style for small, centered inline titles
		appearance.titleTextAttributes = [
			.foregroundColor: UIColor(named: "Logo-color") ?? .black,
			.font: AppFont.title.uiFont
		]
		
		// 2. Font style for large, expanding titles
		appearance.largeTitleTextAttributes = [
			.font: AppFont.largeTitle.uiFont,
			.foregroundColor: UIColor(named: "Logo-color") ?? .black
		]
		
		// Apply globally across standard and scrolled states
		UINavigationBar.appearance().standardAppearance = appearance
		UINavigationBar.appearance().scrollEdgeAppearance = appearance
		
		
		UITextField.appearance(
			whenContainedInInstancesOf: [UISearchBar.self]
		).font = AppFont.body.uiFont
	}
}
