//
//  BlobCD+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 1/19/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension BlobCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlobCD> {
        return NSFetchRequest<BlobCD>(entityName: "BlobCD");
    }

    @NSManaged public var blobAccess: NSNumber?
    @NSManaged public var blobAccount: NSNumber?
    @NSManaged public var blobDatetime: NSDate?
    @NSManaged public var blobFeature: NSNumber?
    @NSManaged public var blobID: String?
    @NSManaged public var blobLat: NSNumber?
    @NSManaged public var blobLong: NSNumber?
    @NSManaged public var blobRadius: NSNumber?
    @NSManaged public var blobType: NSNumber?
    @NSManaged public var lastUsed: NSDate?

}
