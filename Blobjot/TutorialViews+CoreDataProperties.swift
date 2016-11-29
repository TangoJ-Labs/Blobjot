//
//  TutorialViews+CoreDataProperties.swift
//  Blobjot
//
//  Created by Sean Hart on 11/21/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import Foundation
import CoreData


extension TutorialViews {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TutorialViews> {
        return NSFetchRequest<TutorialViews>(entityName: "TutorialViews");
    }

    @NSManaged public var tutorialAccountViewDatetime: NSDate?
    @NSManaged public var tutorialBlobAddViewDatetime: NSDate?
    @NSManaged public var tutorialMapViewDatetime: NSDate?

}
