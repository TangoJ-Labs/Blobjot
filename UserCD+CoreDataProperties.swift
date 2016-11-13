//
//  User+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 11/6/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension UserCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserCD> {
        return NSFetchRequest<UserCD>(entityName: "UserCD");
    }

    @NSManaged public var userID: String?
    @NSManaged public var userImage: NSData?
    @NSManaged public var userImageKey: String?
    @NSManaged public var userName: String?
    @NSManaged public var userStatus: NSNumber?

}
