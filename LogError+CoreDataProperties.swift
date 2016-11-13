//
//  LogError+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 11/3/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension LogError {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LogError> {
        return NSFetchRequest<LogError>(entityName: "LogError");
    }

    @NSManaged public var errorString: String?
    @NSManaged public var function: String?
    @NSManaged public var timestamp: NSNumber?

}
