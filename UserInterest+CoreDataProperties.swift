//
//  UserInterest+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 1/21/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension UserInterest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserInterest> {
        return NSFetchRequest<UserInterest>(entityName: "UserInterest");
    }

    @NSManaged public var interest: String?

}
