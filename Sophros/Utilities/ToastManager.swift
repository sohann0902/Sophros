//
//  ToastManager.swift
//  Sophros
//
//  Created by Sohan Maurya on 20/08/26.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class ToastManager {
    static let shared = ToastManager()

    private(set) var message: String?

    @ObservationIgnored
    private var dismissTask: Task<Void, Never>?

    private init() { }

    func showToast(_ message: String, duration: TimeInterval = 2) {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.message = message
        }

        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))

            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self?.message = nil
            }
        }
    }
}

struct ToastHost: ViewModifier {
    private let manager = ToastManager.shared

    func body(content: Content) -> some View {
        content.overlay(alignment: .center) {
            if let message = manager.message {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(Colormanager.Typography.primaryText)
                    .padding(8)
                    .background(Colormanager.Diet.softPeach)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
        }
    }
}

extension View {
    func toastHost() -> some View {
        modifier(ToastHost())
    }
}
