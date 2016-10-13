//
//  UtilityFunctions.swift
//  Blobjot
//
//  Created by Sean Hart on 9/25/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSCognito
import GoogleMaps
import UIKit

class UtilityFunctions {
    
    // Create a thumbnail-sized image from a large image
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    // Create an alert screen with only an acknowledgment option (an "OK" button)
    func createAlertOkView(_ title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        
        return alertController
    }
    
    // Create an alert screen with only an acknowledgment option (an "OK" button)
    func createAlertOkViewInTopVC(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
//        self.present(alertController, animated: true, completion: nil)
        alertController.show()
    }
    
    func displayLocalBlobNotification(_ blob: Blob) {
        print("SHOWING NOTIFICATION FOR BLOB: \(blob.blobID) WITH TEXT: \(blob.blobText)")
        
        // Find the user for the Blob
        loopUserObjectCheck: for userObject in Constants.Data.userObjects {
            if userObject.userID == blob.blobUserID {
                
                // Create a notification of the new Blob at the current location
                let notification = UILocalNotification()
                
                // Ensure that the Blob Text is not nil
                // If it is nil, just show the Blob userName
                if let blobUserName = userObject.userName {
                    if let blobText = blob.blobText {
                        notification.alertBody = "\(blobUserName): \(blobText)"
                    } else {
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
                    
                } else {
                    print("***** ERROR CREATING LOCAL BLOB NOTIFICATION *****")
                }
                
                break loopUserObjectCheck
            }
        }
        
        // Save the Blob notification in Core Data (so that the user is not notified again)
        let moc = DataController().managedObjectContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "BlobNotification", into: moc) as! BlobNotification
        entity.setValue(blob.blobID, forKey: "blobID")
        // Save the Entity
        do {
            try moc.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    // Process a notification for a new blob
    func displayNewBlobNotification(newBlobID: String)
    {
        // Recall the Blob data
        loopBlobCheck: for blob in Constants.Data.mapBlobs
        {
            if blob.blobID == newBlobID
            {
                // Recall the userObject needed based on recalled Blob data
                loopUserCheck: for user in Constants.Data.userObjects
                {
                    if user.userID == blob.blobUserID
                    {
                        if let userName = user.userName
                        {
//                            print("AD - TRYING TO SHOW NEW BLOB ALERT")
//                            self.createAlertOkViewInTopVC("New Blob", message: "\(userName) added a new Blob for you.")
                            
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
                
                break loopBlobCheck
            }
        }
    }
    
    // Create a solid color UIImage
    func getImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func pathForCoordinate(_ coordinate: CLLocationCoordinate2D, withMeterRadius: Double) -> GMSMutablePath {
        let degreesBetweenPoints = 8.0
        
        let path = GMSMutablePath()
        
        // 45 sides
        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
        let distRadians: Double = withMeterRadius / 6371000.0
        let varianceRadians: Double = (withMeterRadius / 10) / 6371000.0
        
        // earth radius in meters
        let centerLatRadians: Double = coordinate.latitude * M_PI / 180
        let centerLonRadians: Double = coordinate.longitude * M_PI / 180
        
        //array to hold all the points
        for index in 0 ..< Int(numberOfPoints) {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * M_PI / 180
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * 180 / M_PI
            let pointLon: Double = pointLonRadians * 180 / M_PI
            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
            path.add(point)
        }
        
        return path
    }
    
    // Sort the Global mapBlobs array
    // Sort first by type (see enumeration raw values), and then by date added (latest on top)
    func sortMapBlobs()
    {
        Constants.Data.mapBlobs.sort
            { b1, b2 in
                if b1.blobType == b2.blobType
                {
                    return b1.blobDatetime > b2.blobDatetime
                }
                else
                {
                    return b1.blobType.rawValue < b2.blobType.rawValue
                }
        }
    }
}
