//
//  CoreDataFunctions.swift
//  Blobjot
//
//  Created by Sean Hart on 11/3/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import CoreData
import UIKit


class CoreDataFunctions: AWSRequestDelegate
{
 
    // MARK: CURRENT USER
    func currentUserSave(user: User)
    {
        print("CD-CUS: CHECK 1")
        // Try to retrieve the current user data from Core Data
        var currentUserArray = [CurrentUser]()
        let moc = DataController().managedObjectContext
        let currentUserFetch: NSFetchRequest<CurrentUser> = CurrentUser.fetchRequest()
        // Create an empty blobNotifications list in case the Core Data request fails
        do
        {
            currentUserArray = try moc.fetch(currentUserFetch)
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        print("CD-CUS: CHECK 2 - COUNT: \(currentUserArray.count)")
        // If the return has no content, the current user has not yet been saved
        if currentUserArray.count == 0
        {
            print("CD-CUS: CHECK 3")
            // Save the current user data in Core Data
            let entity = NSEntityDescription.insertNewObject(forEntityName: "CurrentUser", into: moc) as! CurrentUser
            entity.setValue(user.userID, forKey: "userID")
            entity.setValue(user.facebookID, forKey: "facebookID")
            entity.setValue(user.userName, forKey: "userName")
            if let userImage = user.userImage
            {
                entity.setValue(UIImagePNGRepresentation(userImage), forKey: "userImage")
            }
        }
        else
        {
            print("CD-CUS: CHECK 4")
            // Replace the current user data to ensure that the latest data is used
            print("CD-CUS: CHECK 4a: CUR: \(currentUserArray[0].userID), FUT: \(user.userID)")
            currentUserArray[0].userID = user.userID
            print("CD-CUS: CHECK 4b: CUR: \(currentUserArray[0].facebookID), FUT: \(user.facebookID)")
            currentUserArray[0].userID = user.facebookID
            print("CD-CUS: CHECK 4c: CUR: \(currentUserArray[0].userName), FUT: \(user.userName)")
            currentUserArray[0].userName = user.userName
            print("CD-CUS: CHECK 4d: CUR: \(currentUserArray[0].userImage?.bytes), FUT: \(user.userImage?.size)")
            if let userImage = user.userImage
            {
                currentUserArray[0].userImage = UIImagePNGRepresentation(userImage) as NSData?
            }
            print("CD-CUS: CHECK 4e")
        }
        print("CD-CUS: CHECK 5")
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("Failure to save context: \(error)")
        }
        print("CD-CUS: CHECK 6")
    }
    
    func currentUserRetrieve() -> [CurrentUser]
    {
        print("CD-CUR: CHECK 1")
        // Access Core Data
        // Retrieve the Current User Blob data from Core Data
        let moc = DataController().managedObjectContext
        let currentUserFetch: NSFetchRequest<CurrentUser> = CurrentUser.fetchRequest()
        
        print("CD-CUR: CHECK 2")
        // Create an empty blobNotifications list in case the Core Data request fails
        var currentUser = [CurrentUser]()
        do
        {
            currentUser = try moc.fetch(currentUserFetch)
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }

        for cUser in currentUser
        {
            print("CD-CUR: CHECK 3 - CURRENT USER: \(cUser.userID), \(cUser.userName)")
        }
        return currentUser
    }
    
    
    // MARK: LOCATION MANAGER SETTING
    func locationManagerSettingSave(_ locationManagerConstant: Bool)
    {
        // Try to retrieve the location manager setting from Core Data
        let moc = DataController().managedObjectContext
        let locationManagerSettingFetch: NSFetchRequest<LocationManagerSetting> = LocationManagerSetting.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var locationManagerSettingArray = [LocationManagerSetting]()
        do
        {
            locationManagerSettingArray = try moc.fetch(locationManagerSettingFetch)
        }
        catch
        {
            fatalError("Failed to fetch locationManagerSetting: \(error)")
        }
        
        // If the return has no content, the locationManagerSetting has not yet been saved
        if locationManagerSettingArray.count == 0
        {
            // Save the locationManagerSetting in Core Data
            let entity = NSEntityDescription.insertNewObject(forEntityName: "LocationManagerSetting", into: moc) as! LocationManagerSetting
            entity.setValue("constant", forKey: "locationManagerSetting")
            print("UF-CDLMS - LOCATION MANAGER SETTING VALUE \"constant\"")
        }
        else
        {
            // Replace the locationManagerSetting to ensure that the latest setting is used
            if locationManagerConstant
            {
                locationManagerSettingArray[0].setValue("constant", forKey: "locationManagerSetting")
                print("UF-CDLMS - LOCATION MANAGER SETTING VALUE \"constant\"")
            }
            else
            {
                locationManagerSettingArray[0].setValue("significant_change", forKey: "locationManagerSetting")
                print("UF-CDLMS - LOCATION MANAGER SETTING VALUE \"significant_change\"")
            }
        }
        
        // Save the Entity
        do
        {
            try moc.save()
            print("UF-CDLMS - SAVED NEW LOCATION MANAGER SETTING VALUE")
        }
        catch
        {
            fatalError("UF-CDLMS - Failure to save context: \(error)")
        }
    }
    
    // Retrieve the CurrentUser data
    func locationManagerSettingRetrieve() -> [LocationManagerSetting]
    {
        // Try to retrieve the location manager setting from Core Data
        let moc = DataController().managedObjectContext
        let locationManagerSettingFetch: NSFetchRequest<LocationManagerSetting> = LocationManagerSetting.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var locationManagerSetting = [LocationManagerSetting]()
        do
        {
            locationManagerSetting = try moc.fetch(locationManagerSettingFetch)
        }
        catch
        {
            fatalError("Failed to fetch locationManagerSetting: \(error)")
        }
        
        for item in locationManagerSetting
        {
            print("CD-LMS: ITEM: \(item.locationManagerSetting)")
        }
        
        return locationManagerSetting
    }
    
    
    // MARK: BLOB NOTIFICATIONS
    func blobNotificationSave(blobID: String)
    {
        // Save a Blob notification in Core Data (so that the user is not notified of the viewed Blob)
        // Because the Blob notification is not checked for already existing, multiple entries with the same blobID may exist
        let moc = DataController().managedObjectContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "BlobNotification", into: moc) as! BlobNotification
        entity.setValue(blobID, forKey: "blobID")
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    func blobNotificationRetrieve() -> [BlobNotification]
    {
        // Retrieve the Blob notification data from Core Data
        let moc = DataController().managedObjectContext
        let blobFetch: NSFetchRequest<BlobNotification> = BlobNotification.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var blobNotifications = [BlobNotification]()
        do
        {
            blobNotifications = try moc.fetch(blobFetch)
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("Failed to fetch frames: \(error)")
        }
        
        for item in blobNotifications
        {
            print("CD-BN: ITEM: \(item.blobID)")
        }
        
        return blobNotifications
    }
    
    
    // MARK: BLOBS
    func blobSave(blob: Blob)
    {
        print("CD-BS - BLOB SAVE: \(blob.blobText)")
        
        // Retrieve the Blob data from Core Data
        let moc = DataController().managedObjectContext
        let blobFetch: NSFetchRequest<BlobCD> = BlobCD.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var blobArray = [BlobCD]()
        do
        {
            blobArray = try moc.fetch(blobFetch)
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("CD-BS - BLOB RETRIEVE - Failed to fetch frames: \(error)")
        }
        
        var blobExists = false
        blobLoop: for (blobIndex, cdBlob) in blobArray.enumerated()
        {
            if cdBlob.blobID == blob.blobID
            {
                blobExists = true
                
                // Edit the user with the new data
                blobArray[blobIndex].lastUsed = Date() as NSDate?
                blobArray[blobIndex].blobDatetime = blob.blobDatetime as NSDate?
                blobArray[blobIndex].blobLat = blob.blobLat as NSNumber?
                blobArray[blobIndex].blobLong = blob.blobLong as NSNumber?
                blobArray[blobIndex].blobRadius = blob.blobRadius as NSNumber?
                blobArray[blobIndex].blobType = blob.blobType.rawValue as NSNumber?
                blobArray[blobIndex].blobUserID = blob.blobUserID
                blobArray[blobIndex].blobText = blob.blobText
                blobArray[blobIndex].blobMediaType = blob.blobMediaType as NSNumber?
                blobArray[blobIndex].blobMediaID = blob.blobMediaID
                blobArray[blobIndex].blobThumbnailID = blob.blobThumbnailID
                if let thumbnail = blob.blobThumbnail
                {
                    blobArray[blobIndex].blobThumbnail = UIImagePNGRepresentation(thumbnail) as NSData?
                }
                
                break blobLoop
            }
        }
        // Save a Blob in Core Data if it does not already exist
        if !blobExists
        {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "BlobCD", into: moc) as! BlobCD
            entity.setValue(Date(), forKey: "lastUsed")
            entity.setValue(blob.blobID, forKey: "blobID")
            entity.setValue(blob.blobDatetime, forKey: "blobDatetime")
            entity.setValue(blob.blobLat, forKey: "blobLat")
            entity.setValue(blob.blobLong, forKey: "blobLong")
            entity.setValue(blob.blobRadius, forKey: "blobRadius")
            entity.setValue(blob.blobType.rawValue, forKey: "blobType")
            entity.setValue(blob.blobUserID, forKey: "blobUserID")
            entity.setValue(blob.blobText, forKey: "blobText")
            entity.setValue(blob.blobMediaType, forKey: "blobMediaType")
            entity.setValue(blob.blobMediaID, forKey: "blobMediaID")
            entity.setValue(blob.blobThumbnailID, forKey: "blobThumbnailID")
            
            if let bThumbnail = blob.blobThumbnail
            {
                entity.setValue(UIImagePNGRepresentation(bThumbnail), forKey: "blobThumbnail")
            }
        }
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-BS - BLOB SAVE - Failure to save context: \(error)")
        }
    }
    
    func blobRetrieve() -> [Blob]
    {
        print("CD-BR - RETRIEVING BLOBS")
        
        // Retrieve the Blob data from Core Data
        let moc = DataController().managedObjectContext
        let blobFetch: NSFetchRequest<BlobCD> = BlobCD.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var blobsCD = [BlobCD]()
        do
        {
            blobsCD = try moc.fetch(blobFetch)
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("CD-BR - BLOB RETRIEVE - Failed to fetch frames: \(error)")
        }
        
        print("CD-BR - BLOBS CD COUNT: \(blobsCD.count)")
        
        // Convert the Blobs to a Blob class
        var blobs = [Blob]()
        for (cdIndex, cdBlob) in blobsCD.enumerated()
        {
            // Update the lastUsed record
            blobsCD[cdIndex].lastUsed = Date() as NSDate?
            
            let addBlob = Blob()
            addBlob.blobID = cdBlob.blobID
            addBlob.blobDatetime = cdBlob.blobDatetime as Date!
            addBlob.blobLat = cdBlob.blobLat as Double!
            addBlob.blobLong = cdBlob.blobLong as Double!
            addBlob.blobRadius = cdBlob.blobRadius as Double!
            addBlob.blobType = cdBlob.blobType.map { Constants.BlobTypes(rawValue: Int($0)) }!
            addBlob.blobUserID = cdBlob.blobUserID
            addBlob.blobText = cdBlob.blobText
            addBlob.blobMediaType = cdBlob.blobMediaType as Int?
            addBlob.blobMediaID = cdBlob.blobMediaID
            addBlob.blobThumbnailID = cdBlob.blobThumbnailID
            
            if let thumbnailData = cdBlob.blobThumbnail
            {
                addBlob.blobThumbnail = UIImage(data: thumbnailData as Data)
            }
            blobs.append(addBlob)
            
            print("CD-BR: BLOB: \(addBlob.blobID)")
        }
        
        // Save the changes to the lastUsed records
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-BR - BLOB SAVE UPDATES - Failure to save context: \(error)")
        }
        
        return blobs
    }
    
    func blobsDeleteOld()
    {
        // Retrieve the Blob data from Core Data
        let moc = DataController().managedObjectContext
        let blobFetch: NSFetchRequest<BlobCD> = BlobCD.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var blobsCD = [BlobCD]()
        do
        {
            blobsCD = try moc.fetch(blobFetch)
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("CD-BRD - BLOB RETRIEVE DELETE - Failed to fetch frames: \(error)")
        }
        
        print("CD-BRD - BLOB COUNT: \(blobsCD.count)")
        
        // Delete each object one at a time if not used recently
        for cdBlob in blobsCD
        {
            if let lastUsed = cdBlob.lastUsed
            {
                if Date().timeIntervalSince1970 - lastUsed.timeIntervalSince1970 > Constants.Settings.maxBlobObjectSaveWithoutUse
                {
                    moc.delete(cdBlob)
                    print("CD-BRD - BLOB DELETE: \(cdBlob.blobID)")
                }
            }
            else
            {
                moc.delete(cdBlob)
            }
        }
        
        // Save the changes to the lastUsed records
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-BRD - BLOB SAVE UPDATES - Failure to save context: \(error)")
        }
    }
    
    
    // MARK: USERS
    func userSave(user: User)
    {
        print("CD-US - SAVING USER: \(user.userID), \(user.userName), \(user.facebookID)")
        
        let moc = DataController().managedObjectContext
        
        // Check for the User already in Core Data
        // Retrieve the Blob notification data from Core Data
        let userFetch: NSFetchRequest<UserCD> = UserCD.fetchRequest()
        
        // Create an empty user array in case the Core Data request fails
        var userArray = [UserCD]()
        do
        {
            userArray = try moc.fetch(userFetch)
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("Failed to fetch frames: \(error)")
        }
        
        // Check for the user already in Core Data and edit, otherwise add a new entity
        var userExists = false
        userLoop: for (userIndex, cdUser) in userArray.enumerated()
        {
            if cdUser.userID == user.userID
            {
                userExists = true
                
                // Edit the user with the new data
                userArray[userIndex].lastUsed = Date() as NSDate?
                userArray[userIndex].facebookID = user.facebookID
                userArray[userIndex].userName = user.userName
                userArray[userIndex].userStatus = user.userStatus.rawValue as NSNumber?
                if let image = user.userImage
                {
                    userArray[userIndex].userImage = UIImagePNGRepresentation(image) as NSData?
                }
                
                break userLoop
            }
        }
        
        // Save a User in Core Data if it does not already exist
        if !userExists
        {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "UserCD", into: moc) as! UserCD
            entity.setValue(Date(), forKey: "lastUsed")
            entity.setValue(user.userID, forKey: "userID")
            entity.setValue(user.facebookID, forKey: "facebookID")
            entity.setValue(user.userName, forKey: "userName")
            entity.setValue(user.userStatus.rawValue, forKey: "userStatus")
        }
        
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("Failure to save context: \(error)")
        }
        
        // If the passed user is the current user, update the Current User data in Core Data as well
        if user.userID == Constants.Data.currentUser
        {
            currentUserSave(user: user)
        }
    }
    
    func userRetrieve() -> [User]
    {
        // Retrieve the Blob notification data from Core Data
        let moc = DataController().managedObjectContext
        let userFetch: NSFetchRequest<UserCD> = UserCD.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var usersCD = [UserCD]()
        do
        {
            usersCD = try moc.fetch(userFetch)
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("Failed to fetch frames: \(error)")
        }
        
        // Convert the Blobs to a Blob class
        var users = [User]()
        for (cdIndex, cdUser) in usersCD.enumerated()
        {
            // Update the lastUsed record
            usersCD[cdIndex].lastUsed = Date() as NSDate?
            
            print("CD-UR - USER: \(cdUser.userID), \(cdUser.userName), \(cdUser.facebookID)")
            
            let addUser = User()
            addUser.userID = cdUser.userID
            addUser.facebookID = cdUser.facebookID
            addUser.userName = cdUser.userName
            addUser.userStatus = cdUser.userStatus.map { Constants.UserStatusTypes(rawValue: Int($0)) }!!
            
            if let imageData = cdUser.userImage
            {
                addUser.userImage = UIImage(data: imageData as Data)
            }
            users.append(addUser)
        }
        
        // Save the changes to the lastUsed records
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-UR - USER SAVE UPDATES - Failure to save context: \(error)")
        }
        
        return users
    }
    
    func usersDeleteOld()
    {
        // Retrieve the Blob notification data from Core Data
        let moc = DataController().managedObjectContext
        let userFetch: NSFetchRequest<UserCD> = UserCD.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var usersCD = [UserCD]()
        do
        {
            usersCD = try moc.fetch(userFetch)
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("Failed to fetch frames: \(error)")
        }
        
        print("CD-URD - USER COUNT: \(usersCD.count)")
        
        // Delete each object one at a time if not used recently
        for cdUser in usersCD
        {
            if let lastUsed = cdUser.lastUsed
            {
                if Date().timeIntervalSince1970 - lastUsed.timeIntervalSince1970 > Constants.Settings.maxUserObjectSaveWithoutUse
                {
                    moc.delete(cdUser)
                    print("CD-URD - USER DELETE: \(cdUser.userID)")
                }
//                moc.delete(cdUser)
//                print("CD-URD - USER DELETE: \(cdUser.userID)")
            }
            else
            {
                moc.delete(cdUser)
            }
        }
        
        // Save the changes to the lastUsed records
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-URD - USER SAVE UPDATES - Failure to save context: \(error)")
        }
    }
    
    // MARK: TUTORIAL VIEWS
    func tutorialViewSave(tutorialViews: TutorialViews)
    {
        print("CD-TVS: CHECK 1")
        // Try to retrieve the Tutorial Views data from Core Data
        var tutorialViewsArray = [TutorialViews]()
        let moc = DataController().managedObjectContext
        let tutorialViewsFetch: NSFetchRequest<TutorialViews> = TutorialViews.fetchRequest()
        // Create an empty Tutorial Views list in case the Core Data request fails
        do
        {
            tutorialViewsArray = try moc.fetch(tutorialViewsFetch)
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        print("CD-TVS: CHECK 2 - COUNT: \(tutorialViewsArray.count)")
        // If the return has no content, no Tutorial Views have been saved
        if tutorialViewsArray.count == 0
        {
            print("CD-TVS: CHECK 3")
            // Save the Tutorial Views data in Core Data
            let entity = NSEntityDescription.insertNewObject(forEntityName: "TutorialViews", into: moc) as! TutorialViews
            if let tutorialMapViewDatetime = tutorialViews.tutorialMapViewDatetime
            {
                entity.setValue(tutorialMapViewDatetime, forKey: "tutorialMapViewDatetime")
            }
            if let tutorialAccountViewDatetime = tutorialViews.tutorialAccountViewDatetime
            {
                entity.setValue(tutorialAccountViewDatetime, forKey: "tutorialAccountViewDatetime")
            }
            if let tutorialBlobAddViewDatetime = tutorialViews.tutorialBlobAddViewDatetime
            {
                entity.setValue(tutorialBlobAddViewDatetime, forKey: "tutorialBlobAddViewDatetime")
            }
        }
        else
        {
            print("CD-TVS: CHECK 4")
            // Replace the Tutorial Views data to ensure that the latest data is used
            print("CD-TVS: CHECK 4a: CUR: \(tutorialViewsArray[0].tutorialMapViewDatetime)")
            if let tutorialMapViewDatetime = tutorialViews.tutorialMapViewDatetime
            {
                tutorialViewsArray[0].tutorialMapViewDatetime = tutorialMapViewDatetime
            }
            if let tutorialAccountViewDatetime = tutorialViews.tutorialAccountViewDatetime
            {
                tutorialViewsArray[0].tutorialAccountViewDatetime = tutorialAccountViewDatetime
            }
            if let tutorialBlobAddViewDatetime = tutorialViews.tutorialBlobAddViewDatetime
            {
                tutorialViewsArray[0].tutorialBlobAddViewDatetime = tutorialBlobAddViewDatetime
            }
            print("CD-TVS: CHECK 4b")
        }
        print("CD-TVS: CHECK 5")
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("Failure to save context: \(error)")
        }
        print("CD-TVS: CHECK 6")
    }
    
    func tutorialViewRetrieve() -> TutorialViews
    {
        print("CD-TVR: CHECK 1")
        // Access Core Data
        // Retrieve the Tutorial Views data from Core Data
        let moc = DataController().managedObjectContext
        let tutorialViewsFetch: NSFetchRequest<TutorialViews> = TutorialViews.fetchRequest()
        
        print("CD-TVR: CHECK 2")
        // Create an empty Tutorial Views list in case the Core Data request fails
        var tutorialViewsArray = [TutorialViews]()
        print("CD-TVR: CHECK 3")
        // Create a new Tutorial Views entity
        let tutorialViews = NSEntityDescription.insertNewObject(forEntityName: "TutorialViews", into: moc) as! TutorialViews
        print("CD-TVR: CHECK 4")
        do
        {
            tutorialViewsArray = try moc.fetch(tutorialViewsFetch)
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        print("CD-TVR: CHECK 5")
        if tutorialViewsArray.count > 0
        {
            if let tutorialMapViewDatetime = tutorialViewsArray[0].tutorialMapViewDatetime
            {
                tutorialViews.setValue(tutorialMapViewDatetime, forKey: "tutorialMapViewDatetime")
            }
            if let tutorialAccountViewDatetime = tutorialViewsArray[0].tutorialAccountViewDatetime
            {
                tutorialViews.setValue(tutorialAccountViewDatetime, forKey: "tutorialAccountViewDatetime")
            }
            if let tutorialBlobAddViewDatetime = tutorialViewsArray[0].tutorialBlobAddViewDatetime
            {
                tutorialViews.setValue(tutorialBlobAddViewDatetime, forKey: "tutorialBlobAddViewDatetime")
            }
        }
        print("CD-TVR: CHECK 6a: \(tutorialViews.tutorialMapViewDatetime)")
        print("CD-TVR: CHECK 6b: \(tutorialViews.tutorialAccountViewDatetime)")
        print("CD-TVR: CHECK 6c: \(tutorialViews.tutorialBlobAddViewDatetime)")
        return tutorialViews
    }
    
    
    // MARK: LOGS - ERRORS
    func logErrorSave(function: String, errorString: String)
    {
        let timestamp: Double = Date().timeIntervalSince1970
        
        // Save a log entry for a function or AWS error
        let moc = DataController().managedObjectContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "LogError", into: moc)
        entity.setValue(function, forKey: "function")
        entity.setValue(errorString, forKey: "errorString")
        entity.setValue(timestamp, forKey: "timestamp")
        
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("Failure to save context: \(error)")
        }
        
        print("CDF - SAVING LOG ERROR: \(function), \(errorString), \(timestamp)")
    }
    
    func logErrorRetrieve(andDelete: Bool) -> [LogError]
    {
        // Retrieve the Blob notification data from Core Data
        let moc = DataController().managedObjectContext
        let logErrorFetch: NSFetchRequest<LogError> = LogError.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var logErrors = [LogError]()
        do
        {
            logErrors = try moc.fetch(logErrorFetch)
            
            // If indicated, delete each object one at a time
            if andDelete
            {
                for logError in logErrors
                {
                    moc.delete(logError)
                }
                
                // Save the Deletions
                do
                {
                    try moc.save()
                }
                catch
                {
                    fatalError("Failure to save context: \(error)")
                }
            }
        }
        catch
        {
            fatalError("Failed to fetch log errors: \(error)")
        }
        
        for item in logErrors
        {
            print("CD-LE: ITEM: \(item.errorString)")
        }
        
        // logErrors will return EVEN IF DELETED (they are not deleted from array, just Core Data)
        return logErrors
    }
    
    
    // MARK: LOGS - USERFLOW
    
    func logUserflowSave(viewController: String, action: String)
    {
        let timestamp: Double = Date().timeIntervalSince1970
        
        // Save a log entry for a function or AWS error
        let moc = DataController().managedObjectContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "LogUserflow", into: moc)
        entity.setValue(viewController, forKey: "viewController")
        entity.setValue(action, forKey: "action")
        entity.setValue(timestamp, forKey: "timestamp")
        
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("Failure to save context: \(error)")
        }
        
        print("CDF - SAVING LOG USERFLOW: \(viewController), \(action), \(timestamp)")
    }
    
    func logUserflowRetrieve(andDelete: Bool) -> [LogUserflow]
    {
        // Retrieve the Blob notification data from Core Data
        let moc = DataController().managedObjectContext
        let logUserflowFetch: NSFetchRequest<LogUserflow> = LogUserflow.fetchRequest()
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var logUserflows = [LogUserflow]()
        do
        {
            logUserflows = try moc.fetch(logUserflowFetch)
            
            // If indicated, delete each object one at a time
            if andDelete
            {
                for logUserflow in logUserflows
                {
                    moc.delete(logUserflow)
                }
                
                // Save the Deletions
                do
                {
                    try moc.save()
                }
                catch
                {
                    fatalError("Failure to save context: \(error)")
                }
            }
        }
        catch
        {
            fatalError("Failed to fetch log errors: \(error)")
        }
        
        for item in logUserflows
        {
            print("CD-LU: ITEM: \(item.action)")
        }
        
        // logUserflows will return EVEN IF DELETED (they are not deleted from array, just Core Data)
        return logUserflows
    }
    
    
    
    // MARK: CORE DATA PROCESSING FUNCTIONS
    
    // Called when the app starts up - process the logs saved in the previous session and upload to AWS
    func processLogs()
    {
        print("CDF - PROCESS LOGS")
        // Retrieve the Error Logs
        let logErrors = logErrorRetrieve(andDelete: false)
        
        var logErrorArray = [[String]]()
        for logError in logErrors
        {
            print("CDF - LOG ERROR: \(logError.function), \(logError.timestamp), \(logError.errorString)")
            var logErrorSubArray = [String]()
            logErrorSubArray.append(logError.function!)
            logErrorSubArray.append(String(format:"%f", (logError.timestamp?.doubleValue)!))
            logErrorSubArray.append(logError.errorString!)
            
            logErrorArray.append(logErrorSubArray)
        }
        
        // Upload to AWS
        AWSPrepRequest(requestToCall: AWSLog(logType: Constants.LogType.error, logArray: logErrorArray), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Delete all Error Logs
        let logErrorDeleteReturn = logErrorRetrieve(andDelete: true)
        print("CDF - DELETED ERROR LOGS RETURN COUNT: \(logErrorDeleteReturn.count)")
        
        // Retrieve the Userflow Logs
        let logUserflows = logUserflowRetrieve(andDelete: false)
        
        var logUserflowArray = [[String]]()
        for logUserflow in logUserflows
        {
            print("CDF - LOG USERFLOW: \(logUserflow.viewController), \(logUserflow.timestamp), \(logUserflow.action)")
            var logUserflowSubArray = [String]()
            logUserflowSubArray.append(logUserflow.viewController!)
            logUserflowSubArray.append(String(format:"%f", (logUserflow.timestamp?.doubleValue)!))
            logUserflowSubArray.append(logUserflow.action!)
            
            logUserflowArray.append(logUserflowSubArray)
        }
        
        // Upload to AWS
        AWSPrepRequest(requestToCall: AWSLog(logType: Constants.LogType.userflow, logArray: logUserflowArray), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Delete all Userflow Logs
        let logUserflowDeleteReturn = logUserflowRetrieve(andDelete: true)
        print("CDF - DELETED USERFLOW LOGS RETURN COUNT: \(logUserflowDeleteReturn.count)")
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("CDF - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSLog:
                    if !success
                    {
                        print("CDF - AWSLog ERROR")
                    }
                default:
                    print("CDF - DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                }
        })
    }
    
}
