//
//  MealLog+CoreDataClass.swift
//  Sophros
//
//  Created by Sohan Maurya on 13/08/26.
//
//

public import Foundation
public import CoreData

public typealias MealLogCoreDataClassSet = NSSet

@objc(MealLog)
public class MealLog: NSManagedObject {
    
    var mealType : MealType {
        get {
            return MealType(rawValue: mealTypeRaw ?? "") ?? .breakfast
        }
        set {
            mealTypeRaw = newValue.rawValue
        }
    }
    
    var kind : MealKind {
        get {
            return MealKind(rawValue: kindRaw ?? "") ?? .log
        }
        set {
            kindRaw = newValue.rawValue
        }
    }
    
    var sortedItems: [MealItem] {
        let items = (items as? Set<MealItem>) ?? []
        
        return items.sorted {
            ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
        }
    }
}

enum MealType : String, CaseIterable, Hashable, Identifiable {
    case breakfast
    case dinner
    case lunch
    case snack
    
    var id: String { rawValue }
    
    var title: String {
        rawValue.capitalized
    }
}

enum MealKind : String {
    case log
    case template
}
