//
//  Blob+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 11/6/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension BlobCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlobCD> {
        return NSFetchRequest<BlobCD>(entityName: "BlobCD");
    }

    @NSManaged public var blobDatetime: NSDate?
    @NSManaged public var blobID: String?
    @NSManaged public var blobLat: NSNumber?
    @NSManaged public var blobLong: NSNumber?
    @NSManaged public var blobMediaID: String?
    @NSManaged public var blobMediaType: NSNumber?
    @NSManaged public var blobRadius: NSNumber?
    @NSManaged public var blobText: String?
    @NSManaged public var blobThumbnail: NSData?
    @NSManaged public var blobThumbnailID: String?
    @NSManaged public var blobType: NSNumber?
    @NSManaged public var blobUserID: String?

}
