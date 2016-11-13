//
//  LogUserflow+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 11/3/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension LogUserflow {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LogUserflow> {
        return NSFetchRequest<LogUserflow>(entityName: "LogUserflow");
    }

    @NSManaged public var action: String?
    @NSManaged public var timestamp: NSNumber?
    @NSManaged public var viewController: String?

}
