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
    
    let region = AWSRegionType.USEast1
    let cognitoIdentityPoolId = "us-east-1:6db4d1c8-f3f5-4466-b135-535279ff6077"
    
    var badgeNumber = 0

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        GMSServices.provideAPIKey(Constants.Settings.gKey)
        GMSPlacesClient.provideAPIKey(Constants.Settings.gKey)
        
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: region,
            identityPoolId: cognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(
            region: region,
            credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        // For the FacebookSDK
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        if let window = window {
            window.layer.backgroundColor = Constants.Colors.colorStatusBar.CGColor
        }
        
        let mapViewController: MapViewController = MapViewController()
//        self.navController!.pushViewController(mapViewController, animated: false)
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
//        self.navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
//        self.navController.viewControllers = [mapViewController]
//        self.window!.rootViewController = navController
        self.window!.rootViewController = mapViewController
        self.window!.makeKeyAndVisible()
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        print("!!!!!! ASSIGNED ROOT VIEW CONTROLLER !!!!!!")
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge , .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        print("IN APP DID ENTER BACKGROUND")
        
        Constants.inBackground = true
        
        print("APPLYING LOCATION MANAGER")
        Constants.appDelegateLocationManager.delegate = self
        Constants.appDelegateLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        Constants.appDelegateLocationManager.requestAlwaysAuthorization()
        Constants.appDelegateLocationManager.pausesLocationUpdatesAutomatically = false
        Constants.appDelegateLocationManager.allowsBackgroundLocationUpdates = true
//        Constants.appDelegateLocationManager.startMonitoringSignificantLocationChanges()
        Constants.appDelegateLocationManager.startUpdatingLocation()
        print("EXISTING LOCATION MANAGER: \(Constants.appDelegateLocationManager.description)")
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
        self.saveContext()
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
    
    // Process the new location data passed by the locationManager to create new notifications if needed
    func processNewLocationDataForNotifications(userLocation: CLLocation) {
        
        // Determine the range of accuracy around those coordinates
        let userRangeRadius = userLocation.horizontalAccuracy
        
        // Check to ensure that the location accuracy is reasonable - if too high, do not update data and wait for more accuracy
        if userRangeRadius <= Constants.Settings.locationAccuracyMax {
            
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
                    
                    // Ensure that the Blob data has not already been requested - if it has, do not notify (already has
                    // been notified, or has been seen on map list)
                    // If so, append the Blob to the Location Blob Array
                    if !blob.blobExtraRequested {
                        blob.blobExtraRequested = true
                        print("AD - REQUESTING BLOB EXTRA")
                        
                        // Only request the extra Blob data if it has not already been requested
//                        getBlobData(blob.blobID)
                        
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
//                            self.getSingleUserData(blob.blobUserID)
                            
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
                notification.fireDate = NSDate().dateByAddingTimeInterval(0) //Show the notification now
                
                UIApplication.sharedApplication().scheduleLocalNotification(notification)
                
                // Add to the number shown on the badge (count of notifications)
                self.badgeNumber += 1
                print("BADGE NUMBER: \(self.badgeNumber)")
                UIApplication.sharedApplication().applicationIconBadgeNumber = self.badgeNumber
                
                break loopUserObjectCheck
            }
        }
    }
    

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.blobjot.Blobjot" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Blobjot", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

