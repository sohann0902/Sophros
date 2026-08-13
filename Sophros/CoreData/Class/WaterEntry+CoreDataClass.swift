//
//  WaterEntry+CoreDataClass.swift
//  Sophros
//
//  Created by Sohan Maurya on 07/08/26.
//
//

public import Foundation
public import CoreData

public typealias WaterEntryCoreDataClassSet = NSSet

@objc(WaterEntry)
public class WaterEntry: NSManagedObject {
    var source: WaterEntrySource {
        get {
            return WaterEntrySource(rawValue: sourceRaw ?? "") ?? .preset
        }
        set {
            sourceRaw = newValue.rawValue
        }
    }
}

enum WaterEntrySource: String {
    case preset
    case custom
}
