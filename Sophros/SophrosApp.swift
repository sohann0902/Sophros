//
//  SophrosApp.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData

@main
struct SophrosApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
