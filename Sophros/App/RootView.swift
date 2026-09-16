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
    @State private var showSplash = true
    @State private var isLaunchContentVisible = false

    var body: some View {
        ZStack {
//            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
//            } else {
//                OnboardingView(shouldAnimateWelcome: isLaunchContentVisible)
//                    .transition(.opacity)
//            }
//
            if showSplash {
                Splashscreen {
                    dismissSplash()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
        .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
    }

    private func dismissSplash() {
        withAnimation(.easeInOut(duration: 0.6)) {
            showSplash = false
        }

        Task {
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            isLaunchContentVisible = true
        }
    }
}

#Preview {
    RootView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
