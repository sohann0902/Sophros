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
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .toastHost()
        }
    }
}
