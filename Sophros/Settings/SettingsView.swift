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

                // Dev aid: replay the onboarding flow from scratch.
                Button("Reset onboarding", role: .destructive) {
                    resetOnboarding()
                }
                .font(.system(size: 16, weight: .semibold))
            }
        }
    }

    private func resetOnboarding() {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        if let profiles = try? context.fetch(request) {
            profiles.forEach(context.delete)
            try? context.save()
        }
        hasCompletedOnboarding = false
    }
}
