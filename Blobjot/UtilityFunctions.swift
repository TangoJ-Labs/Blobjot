//
//  UtilityFunctions.swift
//  Blobjot
//
//  Created by Sean Hart on 9/25/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSCognito
import Darwin
import GoogleMaps
import GooglePlaces
import UIKit

class UtilityFunctions: AWSRequestDelegate
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
                if let digitsID = currentUserArray[0].digitsID
                {
                    currentUser.digitsID  = digitsID
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
                
                // Request the Facebook Info (Name and Image)
                // Always request the FB data to ensure the latest is used
                AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: currentUser.userID, forPreviewData: false), delegate: self as AWSRequestDelegate).prepRequest()
            }
            
            let savedUsers = CoreDataFunctions().userRetrieve()
            for sUser in savedUsers
            {
                // Check to ensure the user does not already exist in the global User array
                var userObjectExists = false
                loopUserObjectCheck: for userObject in Constants.Data.userObjects
                {
                    if userObject.userID == sUser.userID || userObject.digitsID == sUser.digitsID
                    {
                        userObjectExists = true
                        break loopUserObjectCheck
                    }
                }
                if !userObjectExists
                {
                    Constants.Data.userObjects.append(sUser)
                }
                
                // Request the Facebook Info (Name and Image)
                // Always request the FB data to ensure the latest is used
                AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: sUser.userID, forPreviewData: false), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
    }
    
    // Reset the preview Blobs list and set the current preview index to nil
    func resetPreviewData()
    {
        Constants.Data.previewBlobContent = [BlobContent]()
        Constants.Data.previewCurrentIndex = nil
    }
    
    // The calculator for zoom to Blob size ratio
    func mapZoomForBlobSize(_ meters: Float) -> Float
    {
//        let zoom = (0 - (1/98)) * meters + (985/49)
        let zoom = (0 - (1/30)) * meters + (985/49)
        return zoom
    }
    
    // Calculate edge coordinates of a Blob
    func blobEdgeCoordinates(_ center: CLLocationCoordinate2D, radius: Double, east: Bool) -> CLLocationCoordinate2D
    {
        let earthRad: Double = 6378100 // Radius of the Earth in meters
        
        var bearing: Double = 1.5708 // Bearing is 90 degrees converted to radians.
        if !east
        {
            bearing = 4.71239 // Bearing is 270 degrees converted to radians.
        }
        
        let lat1 = center.latitude.degreesToRadians // Current lat point converted to radians
        let lon1 = center.longitude.degreesToRadians // Current long point converted to radians
        
        var lat2 = asin(sin(lat1) * cos(radius/earthRad) + cos(lat1) * sin(radius/earthRad) * cos(bearing))
        var lon2 = lon1 + atan2(sin(bearing) * sin(radius/earthRad) * cos(lat1), cos(radius/earthRad) - sin(lat1) * sin(lat2))
        
        lat2 = lat2.radiansToDegrees
        lon2 = lon2.radiansToDegrees
        
        print("UF - EDGE COORDS - LAT: \(lat2)")
        print("UF - EDGE COORDS - LON: \(lon2)")
        
        return CLLocationCoordinate2DMake(lat2, lon2)
    }
    
//    // Clear any place Blobs from the global mapBlobs
//    func clearPlaceBlobsFromMapBlobs()
//    {
//        for (bIndex, blob) in Constants.Data.mapBlobs.enumerated()
//        {
//            if blob.blobType == Constants.BlobType.blobjot
//            {
//                Constants.Data.mapBlobs.remove(at: bIndex)
//            }
//        }
//    }
    
    // Sort the passed Blobs array
    func sortBlobs(blobs: [Blob]) -> [Blob]
    {
        print("UF - SORTING BLOBS")
        // Sort the Blobs first by blobAccount (standard on top), then blobFeature (invisible on top), 
        // then blobAccess (followed on top), then blobType (origin on top), then from newest to oldest
        let sortedBlobs = blobs.sorted {
            if $0.blobAccount !=  $1.blobAccount
            {
                return $0.blobAccount.rawValue <  $1.blobAccount.rawValue
            }
            else if $0.blobFeature !=  $1.blobFeature
            {
                return $0.blobFeature.rawValue >  $1.blobFeature.rawValue
            }
            else if $0.blobAccess !=  $1.blobAccess
            {
                return $0.blobAccess.rawValue >  $1.blobAccess.rawValue
            }
            else if $0.blobType !=  $1.blobType
            {
                return $0.blobType.rawValue <  $1.blobType.rawValue
            }
            else
            {
                return $0.blobDatetime.timeIntervalSince1970 > $1.blobDatetime.timeIntervalSince1970
            }
        }
        
        return sortedBlobs
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
    
    func displayLocalBlobNotification(_ blobContent: BlobContent)
    {
        // Find the user for the Blob
        loopUserObjectCheck: for userObject in Constants.Data.userObjects
        {
            if userObject.userID == blobContent.userID
            {
                // Create a notification of the new Blob at the current location
                let notification = UILocalNotification()
                
                // Ensure that the Blob Text is not nil
                // If it is nil, just show the Blob userName
                if let blobContentUserName = userObject.userName
                {
                    if let blobContentText = blobContent.contentText
                    {
                        notification.alertBody = "\(blobContentUserName): \(blobContentText)"
                    }
                    else
                    {
                        notification.alertBody = "\(blobContentUserName)"
                    }
                    notification.alertAction = "open"
                    notification.hasAction = false
//                    notification.alertTitle = "\(userObject.userName)"
                    notification.userInfo = ["blobContentID" : blobContent.blobContentID]
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
        
//        // Save the Blob notification in Core Data (so that the user is not notified again)
//        CoreDataFunctions().blobNotificationSave(blobID: blob.blobID)
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
    func displayNewBlobNotificationOLD(newBlobContentID: String)
    {
        // Recall the Blob data
        loopBlobCheck: for blobContent in Constants.Data.blobContent
        {
            if blobContent.blobContentID == newBlobContentID
            {
                // Ensure that the passed Blob was not created by the current user
                if blobContent.userID != Constants.Data.currentUser.userID
                {
                    // Recall the userObject needed based on recalled Blob data
                    loopUserCheck: for user in Constants.Data.userObjects
                    {
                        if user.userID == blobContent.userID
                        {
                            if let userName = user.userName
                            {
                                // Create a notification of the new Blob at the current location
                                let notification = UILocalNotification()
                                
                                notification.alertBody = "\(userName) added a new Blob for you."
                                notification.alertAction = "open"
                                notification.hasAction = false
//                            notification.alertTitle = "\(userObject.userName)"
                                notification.userInfo = ["blobContentID" : blobContent.blobContentID]
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
    
    func jsonToString(withJSONObject: Any) -> String
    {
        var result: String = "ERROR"
        
        do
        {
            let jsonData: NSData = try JSONSerialization.data(withJSONObject: withJSONObject, options: JSONSerialization.WritingOptions.prettyPrinted) as NSData
            let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            print("PVC - JSON: \(jsonString)")
            result = jsonString
        }
        catch let error as NSError
        {
            print("PVC - ERROR JSON CREATION: \(error)")
        }
        
        return result
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("BAVC - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSGetSingleUserData:
                    // Updates to the UserData are commanded from FBGetUserProfileData, so no action is needed
                    print("UF-FBGUPD RETURN")
                default:
                    print("UF-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                }
        })
    }
}
