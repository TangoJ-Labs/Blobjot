//
//  BlobContentCD+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 1/19/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension BlobContentCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlobContentCD> {
        return NSFetchRequest<BlobContentCD>(entityName: "BlobContentCD");
    }

    @NSManaged public var blobContentID: String?
    @NSManaged public var blobID: String?
    @NSManaged public var userID: String?
    @NSManaged public var contentDatetime: NSDate?
    @NSManaged public var contentType: NSNumber?
    @NSManaged public var contentText: String?
    @NSManaged public var contentThumbnailID: String?
    @NSManaged public var contentMediaID: String?
    @NSManaged public var contentThumbnail: NSData?
    @NSManaged public var response: NSNumber?
    @NSManaged public var respondingToContentID: String?
    @NSManaged public var lastUsed: NSDate?

}
