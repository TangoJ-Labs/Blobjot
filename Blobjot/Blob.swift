//
//  Blob.swift
//  Blobjot
//
//  Created by Sean Hart on 8/2/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import CoreData
import UIKit

class Blob
{
    var blobID: String!
    var blobDatetime: Date!
    var blobLat: Double!
    var blobLong: Double!
    var blobRadius: Double!
    var blobType: Constants.BlobTypes!
    var blobUserID: String!
    var blobText: String?
    var blobMediaType: Int?
    var blobMediaID: String?
    var blobThumbnailID: String?
    var blobThumbnail: UIImage?
    
    var blobExtraRequested = false
    var blobSelected = false
    var blobViewed = false
    
    convenience init(blobID: String, blobUserID: String, blobLat: Double, blobLong: Double, blobRadius: Double, blobType: Constants.BlobTypes, blobMediaType: Int, blobText: String)
    {
        self.init()
        
        self.blobID = blobID
        self.blobUserID = blobUserID
        self.blobLat = blobLat
        self.blobLong = blobLong
        self.blobRadius = blobRadius
        self.blobType = blobType
        self.blobMediaType = blobMediaType
        self.blobText = blobText
    }
    
}
