//
//  UserProfile+CoreDataClass.swift
//  Sophros
//
//  Created by Sohan Maurya on 07/08/26.
//
//

public import Foundation
public import CoreData

public typealias UserProfileCoreDataClassSet = NSSet

@objc(UserProfile)
public class UserProfile: NSManagedObject {
    var name : String {
		
		get {
			return displayName ?? ""
		}
		set {
			displayName = newValue
		}
    }

    var gender: Gender {
        get {
            return Gender(rawValue: genderRaw ?? "") ?? .preferNotToSay
        }
        set {
            genderRaw = newValue.rawValue
        }
    }

	var activityLevel: ActivityLevel {
		get {
			return ActivityLevel(rawValue: activityLevelRaw ?? "") ?? .sedentary
		}
		set {
			activityLevelRaw = newValue.rawValue
		}
	}

	var nutritionGoal: NutritionGoalType {
		get {
			return NutritionGoalType(rawValue: nutritionGoalRaw ?? "") ?? .maintain
		}
		set {
			nutritionGoalRaw = newValue.rawValue
		}
	}
}

enum Gender: String, CaseIterable, Identifiable {
    case female
    case male
    case other
    case preferNotToSay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}
