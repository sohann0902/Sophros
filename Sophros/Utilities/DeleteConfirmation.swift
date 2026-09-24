//
//  DeleteConfirmation.swift
//  Sophros
//

import SwiftUI
import Observation

/// Coordinates a single custom delete confirmation and lets callers await its result.
@MainActor
@Observable
final class DeleteConfirmation {
	
    struct Request {
        let title: String
        let message: String
        let tint: Color
    }

    private(set) var request: Request?
    @ObservationIgnored private var continuation: CheckedContinuation<Bool, Never>?

    func confirm(
        title: String = "Delete item?",
        message: String = "This action cannot be undone.",
        tint: Color? = nil
    ) async -> Bool {
        guard request == nil else { return false }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            request = Request(
                title: title,
                message: message,
                tint: tint ?? Colormanager.Status.error
            )
        }
    }

    func accept() {
        resolve(true)
    }

    func cancel() {
        resolve(false)
    }

    private func resolve(_ result: Bool) {
        let continuation = continuation
        self.continuation = nil
        request = nil
        continuation?.resume(returning: result)
    }
}


struct DeleteConfirmationOverlay: View {
    let confirmation: DeleteConfirmation

    var body: some View {
        FadeOverlay(isPresented: isPresented) {
            if let request = confirmation.request {
                ZStack {
                    Color.black.opacity(0.52)
                        .ignoresSafeArea()
                        .onTapGesture { confirmation.cancel() }

                    VStack(alignment: .leading, spacing: 16) {
						
						HStack {
							Image(systemName: "trash.fill")
								.font(.title2.weight(.bold))
								.foregroundStyle(request.tint)
								.padding()
								.background(request.tint.opacity(0.14), in: Circle())
							
							Text(request.title)
								.font(.title3.weight(.heavy))
								.foregroundStyle(Colormanager.Typography.primaryText)
						}

                        Text(request.message)
                            .font(.body)
                            .foregroundStyle(Colormanager.Typography.secondaryText)
							.multilineTextAlignment(.leading)
							.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
							Button {
								confirmation.cancel()
								HapticManager.selection()
							} label: {
								Text("Cancel")
									.font(.headline)
									.foregroundStyle(.white)
									.frame(maxWidth: .infinity)
									.padding(.vertical, 14)
									.contentShape(
										RoundedRectangle(cornerRadius: 15, style: .continuous)
									)
									.background(
										request.tint,
										in: RoundedRectangle(cornerRadius: 15, style: .continuous)
									)
							}
							
							Button {
								confirmation.accept()
								HapticManager.warning()
							} label: {
								Text("Delete")
									.font(.headline)
									.foregroundStyle(.white)
									.frame(maxWidth: .infinity)
									.padding(.vertical, 14)
									.contentShape(
										RoundedRectangle(cornerRadius: 15, style: .continuous)
									)
									.background(
										request.tint,
										in: RoundedRectangle(cornerRadius: 15, style: .continuous)
									)
							}
							
                        }
                    }
					.frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Colormanager.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(24)
                }
                .accessibilityAddTraits(.isModal)
            }
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { confirmation.request != nil },
            set: { if !$0 { confirmation.cancel() } }
        )
    }
}

extension View {
    func deleteConfirmationOverlay(_ confirmation: DeleteConfirmation) -> some View {
        overlay {
            DeleteConfirmationOverlay(confirmation: confirmation)
        }
    }
}

