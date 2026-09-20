//
//  KeyboardInputSheet.swift
//  Sophros
//
//  Created by Sohan Maurya on 17/09/26.
//


//
//  KeyboardInputSheet.swift


import SwiftUI
import UIKit

// MARK: - Confirm Accessory Bar

struct ConfirmAccessoryBar: View {

	var title: String = "Confirm"
	var backgroundColor: Color = Color(
		red: 0.14,
		green: 0.18,
		blue: 0.27
	)

	var action: () -> Void

	var body: some View {
		Button(action: action) {
			Text(title)
				.font(.headline.weight(.semibold))
				.foregroundStyle(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 18)
		}
		.background(backgroundColor)
		.clipShape(
			RoundedRectangle(
				cornerRadius: 20,
				style: .continuous
			)
		)
		.padding()
	}
}


// MARK: - UIKit Text Field Controller

final class KeyboardTextFieldController: UIViewController, UITextFieldDelegate {

	let textField = UITextField()

	var onTextChange: ((String) -> Void)?
	var onConfirmText: ((String) -> Void)?
	var onKeyboardDismiss: (() -> Void)?

	var accessoryTitle = "Confirm"
	var keyboardType: UIKeyboardType = .decimalPad
	var font: UIFont = .systemFont(
		ofSize: 64,
		weight: .semibold
	)

	var textAlignment: NSTextAlignment = .center

	private var didBecomeFirstResponder = false


	// MARK: View Did Load

	override func viewDidLoad() {
		super.viewDidLoad()

		setupTextField()
		installAccessoryBar()
	}


	// MARK: Text Field Setup

	private func setupTextField() {

		textField.delegate = self
		textField.borderStyle = .none
		textField.font = font
		textField.textAlignment = textAlignment
		textField.tintColor = .systemBlue
		textField.keyboardType = keyboardType

		textField.addTarget(
			self,
			action: #selector(textChanged),
			for: .editingChanged
		)

		view.addSubview(textField)

		textField.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			textField.leadingAnchor.constraint(
				equalTo: view.leadingAnchor
			),

			textField.trailingAnchor.constraint(
				equalTo: view.trailingAnchor
			),

			textField.topAnchor.constraint(
				equalTo: view.safeAreaLayoutGuide.topAnchor,
				constant: 24
			),

			textField.bottomAnchor.constraint(
				equalTo: view.safeAreaLayoutGuide.bottomAnchor
			)
		])
	}


	// MARK: Accessory Bar

	private func installAccessoryBar() {

		let bar = ConfirmAccessoryBar(
			title: accessoryTitle
		) { [weak self] in

			guard let self else {
				return
			}

			// Get the CURRENT text directly from UITextField.
			let currentText = self.textField.text ?? ""

			self.onConfirmText?(currentText)
		}

		let hostingController = UIHostingController(
			rootView: bar
		)

		addChild(hostingController)

		hostingController.view.backgroundColor = .clear

		let screenWidth = view.window?.windowScene?.screen.bounds.width ?? 0
		let width = max(screenWidth, max(view.bounds.width, 1))

		let height = hostingController.sizeThatFits(
			in: CGSize(
				width: width,
				height: .greatestFiniteMagnitude
			)
		).height

		hostingController.view.frame = CGRect(
			x: 0,
			y: 0,
			width: width,
			height: height
		)

		hostingController.didMove(
			toParent: self
		)

		textField.inputAccessoryView =
			hostingController.view
	}


	// MARK: First Responder

	override func viewWillAppear(
		_ animated: Bool
	) {
		super.viewWillAppear(animated)

		guard !didBecomeFirstResponder else {
			return
		}

		didBecomeFirstResponder = true

		textField.becomeFirstResponder()
	}


	// MARK: Text Changed

	@objc
	private func textChanged() {

		onTextChange?(
			textField.text ?? ""
		)
	}


	// MARK: Keyboard Return

	func textFieldShouldReturn(
		_ textField: UITextField
	) -> Bool {

		let currentText = textField.text ?? ""

		onConfirmText?(currentText)

		return true
	}


	// MARK: Keyboard Dismissed

	func textFieldDidEndEditing(
		_ textField: UITextField
	) {

		onKeyboardDismiss?()
	}
}


// MARK: - SwiftUI Bridge

struct KeyboardTextField: UIViewControllerRepresentable {

	@Binding var text: String

	var keyboardType: UIKeyboardType = .decimalPad

	var accessoryTitle: String = "Confirm"

	var font: UIFont = .systemFont(
		ofSize: 64,
		weight: .semibold
	)

	var onConfirm: (String) -> Void

	var onKeyboardDismiss: () -> Void = {}


	// MARK: Create Controller

	func makeUIViewController(
		context: Context
	) -> KeyboardTextFieldController {

		let controller =
			KeyboardTextFieldController()

		controller.keyboardType = keyboardType
		controller.accessoryTitle = accessoryTitle
		controller.font = font

		controller.textField.text = text


		// Keep SwiftUI binding updated
		// while the user types.
		controller.onTextChange = { newText in
			text = newText
		}


		// Confirm gives us the ACTUAL current
		// UITextField text.
		controller.onConfirmText = { currentText in
			onConfirm(currentText)
		}


		controller.onKeyboardDismiss =
			onKeyboardDismiss

		return controller
	}


	// MARK: Update Controller

	func updateUIViewController(
		_ controller: KeyboardTextFieldController,
		context: Context
	) {

		if controller.textField.text != text {
			controller.textField.text = text
		}
	}
}


// MARK: - Numeric Goal Sheet

struct NumericGoalSheet: View {

	let title: String

	@Binding var value: String

	var keyboardType: UIKeyboardType = .decimalPad

	var onConfirm: (String) -> Void

	@Environment(\.dismiss)
	private var dismiss


	var body: some View {

		VStack(spacing: 12) {
			
			Color.clear
				.frame(height: 30)

			Text(title)
				.font(.title2.bold())
				.padding(.top, 16)


			KeyboardTextField(
				text: $value,
				keyboardType: keyboardType,
				onConfirm: { currentText in

					// currentText is the actual
					// current UITextField value.
					onConfirm(currentText)

					dismiss()
				},
				onKeyboardDismiss: {

					dismiss()
				}
			)
			.frame(height: 80)
		}

//		.ignoresSafeArea(
//			.keyboard
//		)

		.presentationDetents([
			.height(160)
		])
	}
}


// MARK: - Example

private struct ExampleView: View {

	@State private var showSheet = false

	@State private var calorieGoal = 2000.0

	var body: some View {

		Button(
			"Set calorie goal: \(Int(calorieGoal))"
		) {
			showSheet = true
		}

		.sheet(
			isPresented: $showSheet
		) {

			NumericGoalSheet(
				title: "Calorie goal",

				value: Binding(
					get: {
						String(
							format: "%.0f",
							calorieGoal
						)
					},

					set: { newValue in
						if let number = Double(newValue) {
							calorieGoal = number
						}
					}
				),

				keyboardType: .decimalPad,

				onConfirm: { newValue in

					print(
						"Confirmed calorie goal:",
						newValue
					)

					// Save your Core Data value here.
				}
			)
		}
	}
}
