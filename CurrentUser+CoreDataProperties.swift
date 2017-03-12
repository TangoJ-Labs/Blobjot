//
//  CurrentUser+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 11/15/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension CurrentUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CurrentUser> {
        return NSFetchRequest<CurrentUser>(entityName: "CurrentUser");
    }

    @NSManaged public var digitsID: String?
    @NSManaged public var userID: String?
    @NSManaged public var userImage: NSData?
    @NSManaged public var userName: String?

}
