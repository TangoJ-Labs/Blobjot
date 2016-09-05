//
//  CurrentUser+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 9/3/16.
//  Copyright © 2016 blobjot. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CurrentUser {

    @NSManaged var userID: String?
    @NSManaged var userName: String?
    @NSManaged var facebookID: String?
    @NSManaged var userImageKey: String?
    @NSManaged var userImage: NSData?

}
