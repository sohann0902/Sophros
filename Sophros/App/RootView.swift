//
//  RootView.swift
//  Sophros
//
//  Created by Sohan Maurya on 07/09/26.
//

import SwiftUI
import CoreData

/// Chooses between the onboarding flow and the main app based on whether
/// setup has been completed. The onboarding keeps showing until a `UserProfile`
/// is saved and the flag is set.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    RootView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
