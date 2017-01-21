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
    var blobType: Constants.BlobType!
    var blobAccount = Constants.BlobAccount.standard
    var blobFeature = Constants.BlobFeature.standard
    var blobAccess = Constants.BlobAccess.followers
    
    var blobSelected = false
    
    convenience init(blobID: String, blobDatetime: Date, blobLat: Double, blobLong: Double, blobRadius: Double, blobType: Constants.BlobType, blobAccount: Constants.BlobAccount, blobFeature: Constants.BlobFeature, blobAccess: Constants.BlobAccess)
    {
        self.init()
        
        self.blobID = blobID
        self.blobDatetime = blobDatetime
        self.blobLat = blobLat
        self.blobLong = blobLong
        self.blobRadius = blobRadius
        self.blobType = blobType
        self.blobAccount = blobAccount
        self.blobFeature = blobFeature
        self.blobAccess = blobAccess
    }
    
}
