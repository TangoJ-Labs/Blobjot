//
//  InterestCD+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 1/30/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension InterestCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InterestCD> {
        return NSFetchRequest<InterestCD>(entityName: "InterestCD");
    }

    @NSManaged public var delete: NSNumber?
    @NSManaged public var interest: String?
    @NSManaged public var use: NSNumber?

}
