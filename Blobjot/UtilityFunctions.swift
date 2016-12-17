//
//  UtilityFunctions.swift
//  Blobjot
//
//  Created by Sean Hart on 9/25/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSCognito
//import Darwin
import FBSDKLoginKit
import GoogleMaps
import GooglePlaces
import UIKit

class UtilityFunctions
{
    
    // Reset the global User Array with content from Core Data
    func resetUserListWithCoreData()
    {
        // Reset the People array and try to load the people from Core Data
        Constants.Data.userObjects = [User]()
        
        // First load the current user data, if saved
        // Check to see if the current user data is already in Core Data
        // Try to retrieve the current user data from Core Data
        let currentUserArray = CoreDataFunctions().currentUserRetrieve()
        if let currentUserID = Constants.Data.currentUser.userID
        {
            // If the return has content, use it to populate the user elements
            // Ensure that the saved userID is the same as the global current user (it should be - should be reset when first logged in)
            if currentUserArray.count > 0 && currentUserArray[0].userID == currentUserID
            {
                // Create a new User object to store the currently logged in user
                let currentUser = User()
                if let userID = currentUserArray[0].userID
                {
                    currentUser.userID  = userID
                }
                if let facebookID = currentUserArray[0].facebookID
                {
                    currentUser.userName  = facebookID
                }
                if let userName = currentUserArray[0].userName
                {
                    currentUser.userName  = userName
                }
                if let imageData = currentUserArray[0].userImage
                {
                    currentUser.userImage = UIImage(data: imageData as Data)
                }
                
                // Add the current user object to the global user object array
                Constants.Data.userObjects.append(currentUser)
            }
            
            let savedUsers = CoreDataFunctions().userRetrieve()
            for sUser in savedUsers
            {
                // Check to ensure the user does not already exist in the global User array
                var userObjectExists = false
                loopUserObjectCheck: for userObject in Constants.Data.userObjects
                {
                    if userObject.userID == sUser.userID || userObject.facebookID == sUser.facebookID
                    {
                        userObjectExists = true
                        break loopUserObjectCheck
                    }
                }
                if !userObjectExists
                {
                    Constants.Data.userObjects.append(sUser)
                }
            }
        }
    }
    
    // The calculator for zoom to Blob size ratio
    func mapZoomForBlobSize(_ meters: Float) -> Float
    {
        let zoom = (0 - (1/98)) * meters + (985/49)
        return zoom
    }
    
//    // Clear any place Blobs from the global mapBlobs
//    func clearPlaceBlobsFromMapBlobs()
//    {
//        for (bIndex, blob) in Constants.Data.mapBlobs.enumerated()
//        {
//            if blob.blobType == Constants.BlobTypes.blobjot
//            {
//                Constants.Data.mapBlobs.remove(at: bIndex)
//            }
//        }
//    }
    
    // Sort the global mapBlobs array
    func sortMapBlobs()
    {
//        print("UF - SORTING MAP BLOBS")
        // Sort the Map Blobs first by blobType, then from newest to oldest
        Constants.Data.mapBlobs.sort(by: {
            if $0.blobType !=  $1.blobType
            {
                return $0.blobType.rawValue <  $1.blobType.rawValue
            }
            else
            {
                return $0.blobDatetime.timeIntervalSince1970 > $1.blobDatetime.timeIntervalSince1970
            }
        })
    }
    
    // Sort the global userBlobs array
    func sortUserBlobs()
    {
        // Sort the User Blobs from newest to oldest
        Constants.Data.userBlobs.sort(by: {$0.blobDatetime.timeIntervalSince1970 > $1.blobDatetime.timeIntervalSince1970})
    }
    
    // Calculate the needed textview height for text - need to use font size 10
    func textHeightForAttributedText(text: NSAttributedString, width: CGFloat) -> CGFloat
    {
        let calculationView = UITextView()
        calculationView.attributedText = text
        let size = calculationView.sizeThatFits(CGSize(width: width, height: CGFloat(FLT_MAX)))
        return size.height
    }
    
    func toggleLocationManagerSettings()
    {
        if Constants.Settings.locationManagerSetting == Constants.LocationManagerSettingType.always
        {
            Constants.appDelegateLocationManager.pausesLocationUpdatesAutomatically = false
            Constants.appDelegateLocationManager.startUpdatingLocation()
            Constants.appDelegateLocationManager.disallowDeferredLocationUpdates()
            
            // Save an action in Core Data
            CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: "LOCATION MANAGER: ALWAYS")
        }
        else if Constants.Settings.locationManagerSetting == Constants.LocationManagerSettingType.off
        {
            Constants.appDelegateLocationManager.stopMonitoringSignificantLocationChanges()
            Constants.appDelegateLocationManager.stopUpdatingLocation()
            
            // Save an action in Core Data
            CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: "LOCATION MANAGER: OFF")
        }
        else
        {
            // Significant is the default
            Constants.appDelegateLocationManager.pausesLocationUpdatesAutomatically = true
            Constants.appDelegateLocationManager.startMonitoringSignificantLocationChanges()
//            Constants.appDelegateLocationManager.allowDeferredLocationUpdates(untilTraveled: Constants.Settings.locationAccuracyDeferredDistance, timeout: Constants.Settings.locationAccuracyDeferredInterval)
            
            // Save an action in Core Data
            CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: "LOCATION MANAGER: SIGNIFICANT")
        }
    }
    
    // Create an alert screen with only an acknowledgment option (an "OK" button)
    func createAlertOkView(_ title: String, message: String) -> UIAlertController
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        
        return alertController
    }
    
    // Create an alert screen with only an acknowledgment option (an "OK" button)
    func createAlertOkViewInTopVC(_ title: String, message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
//        self.present(alertController, animated: true, completion: nil)
        alertController.show()
    }
    
    func displayLocalBlobNotification(_ blob: Blob)
    {
        // Find the user for the Blob
        loopUserObjectCheck: for userObject in Constants.Data.userObjects
        {
            if userObject.userID == blob.blobUserID
            {
                // Create a notification of the new Blob at the current location
                let notification = UILocalNotification()
                
                // Ensure that the Blob Text is not nil
                // If it is nil, just show the Blob userName
                if let blobUserName = userObject.userName
                {
                    if let blobText = blob.blobText
                    {
                        notification.alertBody = "\(blobUserName): \(blobText)"
                    }
                    else
                    {
                        notification.alertBody = "\(blobUserName)"
                    }
                    notification.alertAction = "open"
                    notification.hasAction = false
//                    notification.alertTitle = "\(userObject.userName)"
                    notification.userInfo = ["blobID" : blob.blobID]
                    notification.fireDate = Date().addingTimeInterval(0) //Show the notification now
                    
                    UIApplication.shared.scheduleLocalNotification(notification)
                    
                    // Add to the number shown on the badge (count of notifications)
                    Constants.Data.badgeNumber += 1
                    UIApplication.shared.applicationIconBadgeNumber = Constants.Data.badgeNumber
                    
                }
                else
                {
                    print("***** ERROR CREATING LOCAL BLOB NOTIFICATION *****")
                }
                
                break loopUserObjectCheck
            }
        }
        
        // Save the Blob notification in Core Data (so that the user is not notified again)
        CoreDataFunctions().blobNotificationSave(blobID: blob.blobID)
    }
    
    func displayNewBlobNotification(blob: Blob, userName: String)
    {
        let notification = UILocalNotification()
        notification.alertBody = "\(userName) added a new Blob for you."
        notification.alertAction = "open"
        notification.hasAction = false
        // notification.alertTitle = "\(userObject.userName)"
        notification.userInfo = ["blobID" : blob.blobID]
        notification.fireDate = Date().addingTimeInterval(0) //Show the notification now
        
        UIApplication.shared.scheduleLocalNotification(notification)
        
        // Add to the number shown on the badge (count of notifications)
        Constants.Data.badgeNumber += 1
        UIApplication.shared.applicationIconBadgeNumber = Constants.Data.badgeNumber
    }
    
    // Process a notification for a new blob
    func displayNewBlobNotificationOLD(newBlobID: String)
    {
        // Recall the Blob data
        loopBlobCheck: for blob in Constants.Data.mapBlobs
        {
            if blob.blobID == newBlobID
            {
                // Ensure that the passed Blob was not created by the current user
                if blob.blobUserID != Constants.Data.currentUser.userID
                {
                    // Recall the userObject needed based on recalled Blob data
                    loopUserCheck: for user in Constants.Data.userObjects
                    {
                        if user.userID == blob.blobUserID
                        {
                            if let userName = user.userName
                            {
                                // Create a notification of the new Blob at the current location
                                let notification = UILocalNotification()
                                
                                notification.alertBody = "\(userName) added a new Blob for you."
                                notification.alertAction = "open"
                                notification.hasAction = false
//                            notification.alertTitle = "\(userObject.userName)"
                                notification.userInfo = ["blobID" : blob.blobID]
                                notification.fireDate = Date().addingTimeInterval(0) //Show the notification now
                                
                                UIApplication.shared.scheduleLocalNotification(notification)
                                
                                // Add to the number shown on the badge (count of notifications)
                                Constants.Data.badgeNumber += 1
                                UIApplication.shared.applicationIconBadgeNumber = Constants.Data.badgeNumber
                            }
                            
                            break loopUserCheck
                        }
                    }
                }
                
                break loopBlobCheck
            }
        }
    }
    
    // Create a solid color UIImage
    func getImageWithColor(_ color: UIColor, size: CGSize) -> UIImage
    {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
}
