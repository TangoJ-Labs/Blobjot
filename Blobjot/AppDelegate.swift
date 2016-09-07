//
//  AppDelegate.swift
//  Blobjot
//
//  Created by Sean Hart on 7/21/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSCore
import AWSCognito
import CoreData
import CoreLocation
import FBSDKCoreKit
import GoogleMaps
import GooglePlaces
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, AWSMethodsDelegate {

    var window: UIWindow?
    let navController = UINavigationController()
    var mapViewController: MapViewController!
    
    var badgeNumber = 0

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        print("DID FINISH LAUNCHING WITH OPTIONS: \(launchOptions)")
        
        // Push Notifications
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
        let pushNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        application.registerUserNotificationSettings(pushNotificationSettings)
        application.registerForRemoteNotifications()
        
        // Google Maps Prep
        GMSServices.provideAPIKey(Constants.Settings.gKey)
        GMSPlacesClient.provideAPIKey(Constants.Settings.gKey)
        
        // AWS Cognito Prep
//        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.Strings.aws_region, identityPoolId: Constants.Strings.aws_cognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(region: Constants.Strings.aws_region, credentialsProvider: Constants.credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
//        let pool = AWSCognitoUserPool
        
        // FacebookSDK Prep
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Change the color of the default background (try to change the color of the background seen when using a flip transition)
        if let window = window {
            window.layer.backgroundColor = Constants.Colors.colorStatusBar.CGColor
        }
        
        // Prepare the root View Controller and make visible
        self.mapViewController = MapViewController()
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = mapViewController
        self.window!.makeKeyAndVisible()
        print("!!!!!! ASSIGNED ROOT VIEW CONTROLLER !!!!!!")
        
        // Initialize the notification settings and reset the badge number
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge , .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = badgeNumber
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        print("IN APP WILL RESIGN ACTIVE")
        
        Constants.inBackground = true
        
        self.updateLocationManager()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        print("IN APP DID ENTER BACKGROUND")
        
        Constants.inBackground = true
        
        self.updateLocationManager()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        Constants.inBackground = false
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        print("IN APP DID BECOME ACTIVE")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Constants.inBackground = false
        
        // For the FacebookSDK
        FBSDKAppEvents.activateApp()
        
        // Clear the badges
        self.badgeNumber = 0
        UIApplication.sharedApplication().applicationIconBadgeNumber = self.badgeNumber
        
        print("STOPPING LOCATION UPDATING")
        Constants.appDelegateLocationManager.stopUpdatingLocation()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        print("AD - SAVING CONTEXT IN CORE DATA")
        
        // Create a new DataController instance
        let dataController = DataController()
        let moc = dataController.managedObjectContext
        
        // Try to save the context
        do {
            try moc.save()
        } catch {
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    
    // MARK: LOCAL NOTIFICATIONS
    
    // THIS IS NOT FIRING
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        print("HANDLE ACTION WITH IDENTIFIER - LOCAL - WITH IDENTIFIER: \(identifier); FOR NOTIFICATION: \(notification)")
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("DID RECEIVE - LOCAL - NOTIFICATION: \(notification.userInfo!["blobID"])")
        
        // Ensure that the notification userInfo is not nil
        if let userInfo = notification.userInfo {
            
            // Ensure that the passed BlobID is not nil
            if let tappedBlobID = userInfo["blobID"] as? String {
                
                // Find the Blob in the global mapBlobs
                checkMapBlobLoop: for blob in Constants.Data.mapBlobs {
                    if blob.blobID == tappedBlobID {
                        self.mapViewController.setMapCamera(CLLocationCoordinate2D(latitude: blob.blobLat, longitude: blob.blobLong))
                        
                        break checkMapBlobLoop
                    }
                }
            }
        }
    }
    
    
    // MARK: REMOTE (PUSH) NOTIFICATIONS
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("AD-RN - DEVICE TOKEN: \(deviceToken)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("AD-RN - ERROR: \(error)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("AD-RN - DID RECEIVE - REMOTE - NOTIFICATION: \(userInfo)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("AD-RN - DID RECEIVE - REMOTE - NOTIFICATION - BACKGROUND: \(userInfo)")
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        print("AD-RN - HANDLE ACTION WITH IDENTIFIER: \(identifier) FOR REMOTE NOTIFICATION: \(userInfo)")
    }
    
    
    // For the FacebookSDK
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    
    // FUNCTIONS FOR LOCATION DELEGATE
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error while updating location " + error.localizedDescription)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("AD - UPDATED LOCATIONS: \(locations)")
        
        if Constants.inBackground {
            print("AD - UPDATED LOCATIONS - IN BACKGROUND: \(locations[0])")
            
            // Calculate which Blobs are at the current location
            processNewLocationDataForNotifications(locations[0])
        }
    }
    
    
    // MARK:  CUSTOM FUNCTIONS
    
    func updateLocationManager() {
        print("APPLYING LOCATION MANAGER")
        Constants.appDelegateLocationManager.delegate = self
        Constants.appDelegateLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        Constants.appDelegateLocationManager.requestAlwaysAuthorization()
        Constants.appDelegateLocationManager.pausesLocationUpdatesAutomatically = false
        Constants.appDelegateLocationManager.allowsBackgroundLocationUpdates = true
//        Constants.appDelegateLocationManager.startMonitoringSignificantLocationChanges()
        Constants.appDelegateLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        Constants.appDelegateLocationManager.startUpdatingLocation()
        print("EXISTING LOCATION MANAGER: \(Constants.appDelegateLocationManager.description)")
    }
    
    // Process the new location data passed by the locationManager to create new notifications if needed
    func processNewLocationDataForNotifications(userLocation: CLLocation) {
        
        // Retrieve the Blob notification data from Core Data
        let moc = DataController().managedObjectContext
        let blobFetch = NSFetchRequest(entityName: "BlobNotification")
        
        // Create an empty blobNotifications list in case the Core Data request fails
        var blobNotifications = [BlobNotification]()
        do {
            blobNotifications = try moc.executeFetchRequest(blobFetch) as! [BlobNotification]
        } catch {
            fatalError("Failed to fetch frames: \(error)")
        }
        
        // Determine the range of accuracy around those coordinates
        let userRangeRadius = userLocation.horizontalAccuracy
        
        // Check to ensure that the location accuracy is reasonable - if too high, do not update data and wait for more accuracy
        if userRangeRadius <= Constants.Settings.locationAccuracyMaxBackground {
            
            // Clear the array of current location Blobs and add the default Blob as the first element
            Constants.Data.locationBlobs = [Constants.Data.defaultBlob]
            
            // Loop through the array of map Blobs to find which Blobs are in range of the user's current location
            for blob in Constants.Data.mapBlobs {
                
                // Find the minimum distance possible to the Blob center from the user's location
                // Determine the raw distance from the Blob center to the user's location
                // Then subtract the user's location range radius to find the distance from the Blob center to the edge of
                // the user location range circle closest to the Blob
                let blobLocation = CLLocation(latitude: blob.blobLat, longitude: blob.blobLong)
                let userDistanceFromBlobCenter = userLocation.distanceFromLocation(blobLocation)
                let minUserDistanceFromBlobCenter = userDistanceFromBlobCenter - userRangeRadius
                
                // If the minimum distance from the Blob's center to the user is equal to or less than the Blob radius,
                // request the extra Blob data (Blob Text and/or Blob Media)
                if minUserDistanceFromBlobCenter <= blob.blobRadius {
                    print("AD - WITHIN RANGE OF BLOB: \(blob.blobID)")
                    
                    // Check to see if the current user has already been notified of the Blob
                    // Because a Blob notification is saved in BlobViewController each time the Blob is viewed,
                    // multiple entries with the same blobID may exist, but the loop will stop after reaching the first entry
                    var blobNotExists = false
                    checkBlobNotLoop: for blobNotObject in blobNotifications {
                        if blobNotObject.blobID == blob.blobID {
                            blobNotExists = true
                            break checkBlobNotLoop
                        }
                    }
                    if !blobNotExists {
                        
                        // Ensure that the Blob data has not already been requested
                        // If it as been requested, just append the Blob to the Location Blob Array
                        if !blob.blobExtraRequested {
                            blob.blobExtraRequested = true
                            print("AD - REQUESTING BLOB EXTRA")
                            
                            // Only request the extra Blob data if it has not already been requested
                            let awsMethods = AWSMethods()
                            awsMethods.awsMethodsDelegate = self
                            awsMethods.getBlobData(blob.blobID)
                            
                            // When downloading Blob data, always request the user data if it does not already exist
                            // Find the correct User Object in the global list
                            var userExists = false
                            loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                                if userObject.userID == blob.blobUserID {
                                    userExists = true
                                    
                                    break loopUserObjectCheck
                                }
                            }
                            // If the user has not been downloaded, request the user and the userImage and then notify the user
                            if !userExists {
                                
                                let awsMethods = AWSMethods()
                                awsMethods.awsMethodsDelegate = self
                                awsMethods.getSingleUserData(blob.blobUserID, forPreviewBox: false)
                            }
                        } else {
                            Constants.Data.locationBlobs.append(blob)
                            print("AD - APPENDING BLOB")
                        }
                    }
                }
            }
//            print("SORTING LOCATION BLOBS")
//            // Sort the Location Blobs from newest to oldest
//            Constants.Data.locationBlobs.sortInPlace({$0.blobDatetime.timeIntervalSince1970 >  $1.blobDatetime.timeIntervalSince1970})
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func refreshCollectionView() {
    }
    func updateBlobActionTable() {
    }
    func updatePreviewBoxData(user: User) {
    }
    func refreshPreviewUserData(user: User) {
    }
    
    func displayNotification(blob: Blob) {
        print("SHOWING NOTIFICATION FOR BLOB: \(blob.blobID) WITH TEXT: \(blob.blobText)")
        
        // Find the user for the Blob
        loopUserObjectCheck: for userObject in Constants.Data.userObjects {
            if userObject.userID == blob.blobUserID {
                
                // Create a notification of the new Blob at the current location
                let notification = UILocalNotification()
                
                // Ensure that the Blob Text is not nil
                // If it is nil, just show the Blob userName
                if let blobText = blob.blobText {
                    notification.alertBody = "\(userObject.userName): \(blobText)"
                } else {
                    notification.alertBody = "\(userObject.userName)"
                }
                notification.alertAction = "open"
                notification.hasAction = false
//                notification.alertTitle = "\(userObject.userName)"
                notification.userInfo = ["blobID" : blob.blobID]
                notification.fireDate = NSDate().dateByAddingTimeInterval(0) //Show the notification now
                
                UIApplication.sharedApplication().scheduleLocalNotification(notification)
                
                // Add to the number shown on the badge (count of notifications)
                self.badgeNumber += 1
                print("BADGE NUMBER: \(self.badgeNumber)")
                UIApplication.sharedApplication().applicationIconBadgeNumber = self.badgeNumber
                
                break loopUserObjectCheck
            }
        }
        
        // Save the Blob notification in Core Data (so that the user is not notified again)
        let moc = DataController().managedObjectContext
        let entity = NSEntityDescription.insertNewObjectForEntityForName("BlobNotification", inManagedObjectContext: moc) as! BlobNotification
        entity.setValue(blob.blobID, forKey: "blobID")
        // Save the Entity
        do {
            try moc.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }

}

