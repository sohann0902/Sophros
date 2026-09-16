//
//  SettingsView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            Colormanager.baseBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Settings")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Colormanager.Typography.primaryText)

                Button("Reset app data", role: .destructive) {
                    resetAppData()
                }
                .font(.system(size: 16, weight: .semibold))
            }
        }
    }

    private func resetAppData() {
        guard let entities = context.persistentStoreCoordinator?.managedObjectModel.entities else {
            return
        }

        do {
            for entity in entities {
                guard let entityName = entity.name else { continue }
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let objects = try context.fetch(request)
                objects.forEach(context.delete)
            }

            try context.save()

            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
            }
            hasCompletedOnboarding = false
        } catch {
            print("Failed to reset app data: \(error)")
        }
    }
}
