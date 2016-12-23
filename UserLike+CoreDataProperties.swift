//
//  UserLike+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 12/22/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension UserLike {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserLike> {
        return NSFetchRequest<UserLike>(entityName: "UserLike");
    }

    @NSManaged public var like: String?

}
