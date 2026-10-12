//
//  FontManager.swift
//  Sophros
//
//  Created by Sohan Maurya on 25/09/26.
//

import SwiftUI

enum AppFont {
	case body
	case lightBody
	case italic
	case headline
	case subheadline
	case title
	case largeTitle
	case footer
	case caption

	var font: Font {
		switch self {
		case .body:
			.custom("Nunito-Regular", size: 16)
			
		case .lightBody:
			.custom("Nunito-Light", size: 16)

		case .italic:
			.custom("Nunito-Italic", size: 16)

		case .headline:
			.custom("Nunito-Bold", size: 20)

		case .subheadline:
			.custom("Nunito-SemiBold", size: 18)

		case .title:
			.custom("Nunito-ExtraBold", size: 22)

		case .largeTitle:
			.custom("Nunito-Black", size: 24)

		case .footer:
			.custom("Nunito-ExtraLight", size: 15)

		case .caption:
			.custom("Nunito-ExtraLightItalic", size: 14)
		}
	}

	var color: Color {
		switch self {
		case .body, .italic, .headline, .title, .subheadline, .lightBody, .largeTitle:
			Colormanager.Typography.primaryText

		case .caption, .footer:
			Colormanager.Typography.secondaryText
		}
	}
	
	var uiFont: UIFont {
		let (name, size): (String, CGFloat) = {
			switch self {
			case .body: ("Nunito-Regular", 18)
			case .italic: ("Nunito-Italic", 18)
			case .headline: ("Nunito-Bold", 21)
			case .subheadline: ("Nunito-SemiBold", 19)
			case .title: ("Nunito-ExtraBold", 22)
			case .largeTitle: ("Nunito-Black", 34)
			case .footer: ("Nunito-ExtraLight", 16)
			case .caption: ("Nunito-ExtraLightItalic", 14)
			case .lightBody:
				("Nunito-Light", 17)
			}
		}()
		return UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
	}
	
	var fontName: String {
			switch self {
			case .body:
				"Nunito-Regular"
			case .lightBody:
				"Nunito-Light"
			case .italic:
				"Nunito-Italic"
			case .headline:
				"Nunito-Bold"
			case .subheadline:
				"Nunito-SemiBold"
			case .title:
				"Nunito-ExtraBold"
			case .largeTitle:
				"Nunito-Black"
			case .footer:
				"Nunito-ExtraLight"
			case .caption:
				"Nunito-ExtraLightItalic"
			}
		}

		var fontSize: CGFloat {
			switch self {
			case .body, .lightBody, .italic:
				17
			case .headline:
				20
			case .subheadline:
				18
			case .title:
				22
			case .largeTitle:
				24
			case .footer:
				16
			case .caption:
				14
			}
		}
}
