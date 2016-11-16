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
        // Try to retrieve the current user data from Core Data
        let currentUserArray = currentUserRetrieve()
        let moc = DataController().managedObjectContext
        
        // If the return has no content, the current user has not yet been saved
        if currentUserArray.count == 0
        {
            // Save the current user data in Core Data
            let entity = NSEntityDescription.insertNewObject(forEntityName: "CurrentUser", into: moc) as! CurrentUser
            entity.setValue(user.userID, forKey: "userID")
            entity.setValue(user.userName, forKey: "userName")
//            entity.setValue(user.userImageKey, forKey: "userImageKey")
            if let userImage = user.userImage
            {
                entity.setValue(UIImagePNGRepresentation(userImage), forKey: "userImage")
            }
        }
        else
        {
            // Replace the current user data to ensure that the latest data is used
            currentUserArray[0].userID = user.userID
            currentUserArray[0].userName = user.userName
//            currentUserArray[0].userImageKey = user.userImageKey
            currentUserArray[0].userImage = UIImagePNGRepresentation(user.userImage!) as NSData?
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
    }
    
    func currentUserRetrieve() -> [CurrentUser]
    {
        // Access Core Data
        // Retrieve the Current User Blob data from Core Data
        let moc = DataController().managedObjectContext
        let currentUserFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CurrentUser")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var currentUser = [CurrentUser]()
        do
        {
            currentUser = try moc.fetch(currentUserFetch) as! [CurrentUser]
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        
        return currentUser
    }
    
    
    // MARK: LOCATION MANAGER SETTING
    func locationManagerSettingSave(_ locationManagerConstant: Bool)
    {
        // Try to retrieve the locationManagerSetting from Core Data
        let locationManagerSettingArray = locationManagerSettingRetrieve()
        let moc = DataController().managedObjectContext
        
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
        let locationManagerSettingFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationManagerSetting")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var locationManagerSetting = [LocationManagerSetting]()
        do
        {
            locationManagerSetting = try moc.fetch(locationManagerSettingFetch) as! [LocationManagerSetting]
        }
        catch
        {
            fatalError("Failed to fetch locationManagerSetting: \(error)")
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
        let blobFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "BlobNotification")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var blobNotifications = [BlobNotification]()
        do
        {
            blobNotifications = try moc.fetch(blobFetch) as! [BlobNotification]
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("Failed to fetch frames: \(error)")
        }
        
        return blobNotifications
    }
    
    
    // MARK: BLOBS
    func blobSave(blob: Blob)
    {
        print("CDF - BLOB SAVE: \(blob.blobText)")
        
        let moc = DataController().managedObjectContext
        
        // Check for the Blob already in Core Data
        let blobArray = blobRetrieve()
        
        var blobExists = false
        blobLoop: for (blobIndex, cdBlob) in blobArray.enumerated()
        {
            if cdBlob.blobID == blob.blobID
            {
                blobExists = true
                
                // Edit the user with the new data
                blobArray[blobIndex].blobDatetime = blob.blobDatetime
                blobArray[blobIndex].blobLat = blob.blobLat
                blobArray[blobIndex].blobLong = blob.blobLong
                blobArray[blobIndex].blobRadius = blob.blobRadius
                blobArray[blobIndex].blobType = blob.blobType
                blobArray[blobIndex].blobUserID = blob.blobUserID
                blobArray[blobIndex].blobText = blob.blobText
                blobArray[blobIndex].blobMediaType = blob.blobMediaType
                blobArray[blobIndex].blobMediaID = blob.blobMediaID
                blobArray[blobIndex].blobThumbnailID = blob.blobThumbnailID
                blobArray[blobIndex].blobThumbnail = blob.blobThumbnail
                
                break blobLoop
            }
        }
        // Save a Blob in Core Data if it does not already exist
        if !blobExists
        {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "BlobCD", into: moc) as! BlobCD
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
            fatalError("CDF - BLOB SAVE - Failure to save context: \(error)")
        }
    }
    
    func blobRetrieve() -> [Blob]
    {
        print("CDF - RETRIEVING BLOBS")
        
        // Retrieve the Blob notification data from Core Data
        let moc = DataController().managedObjectContext
        let blobFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "BlobCD")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var blobsCD = [BlobCD]()
        do
        {
            blobsCD = try moc.fetch(blobFetch) as! [BlobCD]
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("CDF - BLOB RETRIEVE - Failed to fetch frames: \(error)")
        }
        
        // Convert the Blobs to a Blob class
        var blobs = [Blob]()
        for cdBlob in blobsCD
        {
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
        }
        
        return blobs
    }
    
    // MARK: USERS
    func userSave(user: User)
    {
        let moc = DataController().managedObjectContext
        
        // Check for the User already in Core Data
        let userArray = userRetrieve()
        var userExists = false
        userLoop: for (userIndex, cdUser) in userArray.enumerated()
        {
            if cdUser.userID == user.userID
            {
                userExists = true
                
                // Edit the user with the new data
                userArray[userIndex].userName = user.userName
//                userArray[userIndex].userImageKey = user.userImageKey
                userArray[userIndex].userImage = user.userImage
                userArray[userIndex].userStatus = user.userStatus
                
                break userLoop
            }
        }
        
        // Save a User in Core Data if it does not already exist
        if !userExists
        {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "UserCD", into: moc) as! UserCD
            entity.setValue(user.userID, forKey: "userID")
            entity.setValue(user.userName, forKey: "userName")
//            entity.setValue(user.userImageKey, forKey: "userImageKey")
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
    }
    
    func userRetrieve() -> [User]
    {
        // Retrieve the Blob notification data from Core Data
        let moc = DataController().managedObjectContext
        let userFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserCD")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var usersCD = [UserCD]()
        do
        {
            usersCD = try moc.fetch(userFetch) as! [UserCD]
        }
        catch
        {
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
            fatalError("Failed to fetch frames: \(error)")
        }
        
        // Convert the Blobs to a Blob class
        var users = [User]()
        for cdUser in usersCD
        {
            let addUser = User()
            addUser.userID = cdUser.userID
            addUser.userName = cdUser.userName
//            addUser.userImageKey = cdUser.userImageKey
            addUser.userStatus = cdUser.userStatus.map { Constants.UserStatusTypes(rawValue: Int($0)) }!!
            
            if let imageData = cdUser.userImage
            {
                addUser.userImage = UIImage(data: imageData as Data)
            }
            users.append(addUser)
        }
        
        return users
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
        let logErrorFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "LogError")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var logErrors = [LogError]()
        do
        {
            logErrors = try moc.fetch(logErrorFetch) as! [LogError]
            
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
        let logUserflowFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "LogUserflow")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var logUserflows = [LogUserflow]()
        do
        {
            logUserflows = try moc.fetch(logUserflowFetch) as! [LogUserflow]
            
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
