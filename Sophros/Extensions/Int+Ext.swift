//
//  Int+Ext.swift
//  Sophros
//
//  Created by Sohan Maurya on 19/08/26.
//

import Foundation

extension Int {
    var ordinalSuffix: String {
        switch self % 100 {
        case 11, 12, 13:
            return "th"
        default:
            switch self % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
}
