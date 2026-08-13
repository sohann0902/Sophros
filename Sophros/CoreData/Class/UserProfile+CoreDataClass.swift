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
        return displayName ?? ""
    }
}
