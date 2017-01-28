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
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, AWSRequestDelegate
{

    var window: UIWindow?
    let navController = UINavigationController()
    var mapViewController: MapViewController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
//        let thisClass: String = NSStringFromClass(type(of: self))
        
        // Register the device with Apple's Push Notification Service
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
        let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
        application.registerUserNotificationSettings(pushNotificationSettings)
        application.registerForRemoteNotifications()
        
        // Google Maps Prep
        GMSServices.provideAPIKey(Constants.Settings.gKey)
        GMSPlacesClient.provideAPIKey(Constants.Settings.gKey)
        
        // AWS Cognito Prep
        let configuration = AWSServiceConfiguration(region: Constants.Strings.awsRegion, credentialsProvider: Constants.credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // FacebookSDK Prep
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Prepare the root View Controller and make visible
        self.mapViewController = MapViewController()
        self.navController.pushViewController(mapViewController, animated: false)
        
//        // stackoverflow.com/questions/24402000/uinavigationbar-text-color-in-swift
//        let navigationBarAppearace = UINavigationBar.appearance()
//        navigationBarAppearace.tintColor = Constants.Colors.colorTextNavBar
//        navigationBarAppearace.barTintColor = Constants.Colors.colorStatusBar
//        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName: Constants.Colors.colorTextNavBar]
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
        self.navController.navigationBar.tintColor = Constants.Colors.colorTextNavBar
        self.navController.viewControllers = [mapViewController]
        self.window!.rootViewController = navController
        self.window!.makeKeyAndVisible()
        
        // Change the color of the default background (try to change the color of the background seen when using a flip transition)
        if let window = window
        {
            window.layer.backgroundColor = Constants.Colors.colorStatusBar.cgColor
        }
        
        // Initialize the notification settings and reset the badge number
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        
        UIApplication.shared.applicationIconBadgeNumber = Constants.Data.badgeNumber
        
        let coreDataFunctionsInstance = CoreDataFunctions()
        coreDataFunctionsInstance.usersDeleteOld()
        coreDataFunctionsInstance.blobsDeleteOld()
        coreDataFunctionsInstance.blobContentDeleteOld()
        
        // Reset the global User list with Core Data
        UtilityFunctions().resetUserListWithCoreData()
        
        // Reset the global User Likes list with Core Data
        Constants.Data.currentUserInterests = CoreDataFunctions().interestsRetrieve()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        CoreDataFunctions().processLogs()
        
        Constants.inBackground = true
        
        self.updateLocationManager()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        Constants.inBackground = true
        
        self.updateLocationManager()
        
        // Delete Blobs and Users not recently used to save space
        let coreDataFunctionsInstance = CoreDataFunctions()
        coreDataFunctionsInstance.usersDeleteOld()
        coreDataFunctionsInstance.blobsDeleteOld()
        coreDataFunctionsInstance.blobContentDeleteOld()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        Constants.inBackground = false
        
        Constants.appDelegateLocationManager.stopUpdatingLocation()
        self.updateLocationManager()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Constants.inBackground = false
        
        // For the FacebookSDK
        FBSDKAppEvents.activateApp()
        
        // Clear the badges
        Constants.Data.badgeNumber = 0
        UIApplication.shared.applicationIconBadgeNumber = Constants.Data.badgeNumber
        
        Constants.appDelegateLocationManager.stopUpdatingLocation()
        self.updateLocationManager()
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
//        // Create a new DataController instance
//        let dataController = DataController()
//        let moc = dataController.managedObjectContext
//        
//        // Try to save the context
//        do
//        {
//            try moc.save()
//        }
//        catch
//        {
//            let nserror = error as NSError
//            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
//            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
//        }
    }
    
    
    // MARK: LOCAL NOTIFICATIONS
    
    // THIS IS NOT FIRING
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void)
    {
        print("AD-N - HANDLE ACTION WITH IDENTIFIER - LOCAL - WITH IDENTIFIER: \(identifier); FOR NOTIFICATION: \(notification)")
    }
    
    // Handles action when a notification is tapped
    func application(_ application: UIApplication, didReceive notification: UILocalNotification)
    {
        print("AD-N - DID RECEIVE LOCAL NOTIFICATION COMMAND: \(notification.userInfo!["blobID"])")
        print("AD-N - APPLICATION STATE: \(application.applicationState.rawValue)")
        
        // Ensure that the app was in the background (inactive) state when the notification was received or interacted with (tapped)
        if application.applicationState == UIApplicationState.inactive
        {
            // Ensure that the notification userInfo is not nil
            if let userInfo = notification.userInfo
            {
                // Ensure that the passed BlobID is not nil
                if let tappedBlobID = userInfo["blobID"] as? String
                {
                    // Find the Blob in the global mapBlobs
                    checkMapBlobLoop: for blob in Constants.Data.allBlobs
                    {
                        if blob.blobID == tappedBlobID
                        {
                            // Center the map on the Blob location
                            // TODO: adjust the zoom based on the Blob size
                            self.mapViewController.setMapCamera(CLLocationCoordinate2D(latitude: blob.blobLat, longitude: blob.blobLong), zoom: 18, viewingAngle: nil)
                            self.mapViewController.mapView.animate(toZoom: UtilityFunctions().mapZoomForBlobSize(Float(blob.blobRadius)))
                            
                            break checkMapBlobLoop
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: REMOTE (PUSH) NOTIFICATIONS
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        // Use the device token from APNS to register with AWS SNS
        var stringToken = ""
        for i in 0..<deviceToken.count
        {
            stringToken = stringToken + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        AWSPrepRequest(requestToCall: AWSRegisterForPushNotifications(deviceToken: stringToken), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        print("AD-RN - ERROR: \(error)")
        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any])
    {
        print("AD-RN - DID RECEIVE - REMOTE - NOTIFICATION: \(userInfo)")
        
        // If the notification is a new Blob, process the notification
        if userInfo["blobID"] != nil
        {
            self.handleBlobPushNotification(userInfo: userInfo)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        print("AD-RN - DID RECEIVE - REMOTE - NOTIFICATION - BACKGROUND: \(userInfo)")
        
        // If the notification is a new Blob, process the notification
        if userInfo["blobID"] != nil
        {
            self.handleBlobPushNotification(userInfo: userInfo)
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void)
    {
        print("AD-RN - HANDLE ACTION WITH IDENTIFIER: \(identifier) FOR REMOTE NOTIFICATION: \(userInfo)")
        
        // If the notification is a new Blob, process the notification
        if userInfo["blobID"] != nil
        {
            self.handleBlobPushNotification(userInfo: userInfo)
        }
    }
    
    // CUSTOM HANDLER FOR PUSH NOTIFICATIONS
    func handleBlobPushNotification(userInfo: [AnyHashable: Any])
    {
        if let blobID = userInfo["blobID"] as? String
        {
            let notificationBlob = Blob()
            notificationBlob.blobID = blobID
            notificationBlob.blobDatetime = Date(timeIntervalSince1970: Double(userInfo["blobTimestamp"] as! String)!)
            notificationBlob.blobLat = Double(userInfo["blobLat"] as! String)!
            notificationBlob.blobLong = Double(userInfo["blobLong"] as! String)!
            notificationBlob.blobRadius = Double(userInfo["blobRadius"] as! String)!
            notificationBlob.blobType = Constants().blobType(Int(userInfo["blobType"] as! String)!)
            if let blobAccount = userInfo["blobAccount"]
            {
                notificationBlob.blobAccount = Constants().blobAccount(blobAccount as! Int)
            }
            if let blobFeature = userInfo["blobFeature"]
            {
                notificationBlob.blobFeature = Constants().blobFeature(blobFeature as! Int)
            }
            if let blobAccess = userInfo["blobAccess"]
            {
                notificationBlob.blobAccess = Constants().blobAccess(blobAccess as! Int)
            }
            
            Constants.Data.allBlobs.append(notificationBlob)
            
            if let userName = userInfo["userName"] as? String
            {
                // Show the new Blob notification
                UtilityFunctions().displayNewBlobNotification(blob: notificationBlob, userName: userName)
            }
            
//            // Only request the extra Blob data if it has not already been requested
//            AWSPrepRequest(requestToCall: AWSGetBlobData(blobID: blobID, notifyUser: true), delegate: self as AWSRequestDelegate).prepRequest()
        }
    }
    
    
    // For the FacebookSDK
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
    {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    
    // FUNCTIONS FOR LOCATION DELEGATE
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error while updating location " + error.localizedDescription)
        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if Constants.inBackground
        {
            // Calculate which Blobs are at the current location
            processNewLocationDataForNotifications(locations[0])
        }
    }
    
    
    // MARK:  CUSTOM FUNCTIONS
    
    func updateLocationManager()
    {
        Constants.appDelegateLocationManager.delegate = self
        Constants.appDelegateLocationManager.requestAlwaysAuthorization()
        Constants.appDelegateLocationManager.activityType = .other
        Constants.appDelegateLocationManager.allowsBackgroundLocationUpdates = true
        Constants.appDelegateLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        Constants.appDelegateLocationManager.distanceFilter = Constants.Settings.locationDistanceFilter
        
        UtilityFunctions().toggleLocationManagerSettings()
    }
    
    // Process the new location data passed by the locationManager to create new notifications if needed
    func processNewLocationDataForNotifications(_ userLocation: CLLocation)
    {
        // Create an empty blobNotifications list in case the Core Data request fails
        let blobNotifications = CoreDataFunctions().blobNotificationRetrieve()
        
        // Determine the range of accuracy around those coordinates
        let userRangeRadius = userLocation.horizontalAccuracy
        
        // Check to ensure that the location accuracy is reasonable - if too high, do not update data and wait for more accuracy
        if userRangeRadius <= Constants.Settings.locationAccuracyMaxBackground
        {
            // Clear the array of current location Blobs and add the default Blob as the first element
            Constants.Data.locationBlobContent = [Constants.Data.defaultBlobContent]
            
            // Loop through the array of map Blobs to find which Blobs are in range of the user's current location
            for blob in Constants.Data.allBlobs
            {
                // Find the minimum distance possible to the Blob center from the user's location
                // Determine the raw distance from the Blob center to the user's location
                // Then subtract the user's location range radius to find the distance from the Blob center to the edge of
                // the user location range circle closest to the Blob
                let blobLocation = CLLocation(latitude: blob.blobLat, longitude: blob.blobLong)
                let userDistanceFromBlobCenter = userLocation.distance(from: blobLocation)
                let minUserDistanceFromBlobCenter: Double! = userDistanceFromBlobCenter - userRangeRadius
                
                // If the minimum distance from the Blob's center to the user is equal to or less than the Blob radius,
                // request the extra Blob data (Blob Text and/or Blob Media)
                if minUserDistanceFromBlobCenter <= blob.blobRadius
                {
                    // Store the requested userIDs to prevent repeated requests
                    var userDataRequests = [String]()
                    
                    // FInd the BlobContent associated with this Blob
                    for blobContent in Constants.Data.blobContent
                    {
                        if blobContent.blobID == blob.blobID
                        {
                            // Ensure that the BlobContent data has not already been requested
                            // If it as been requested, just append the BlobContent to the Location BlobContent Array
                            if !blobContent.contentExtraRequested
                            {
                                blobContent.contentExtraRequested = true
                                
                                // Only request the extra BlobContent data if it has not already been requested
                                AWSPrepRequest(requestToCall: AWSGetBlobContent(blobContentID: blobContent.blobContentID, minimalOnly: false), delegate: self as AWSRequestDelegate).prepRequest()
                                
                                // When downloading BlobContent data, always request the user data if it does not already exist
                                // Find the correct User Object in the global list
                                var userExists = false
                                loopUserObjectCheck: for userObject in Constants.Data.userObjects
                                {
                                    if userObject.userID == blobContent.userID
                                    {
                                        userExists = true
                                        break loopUserObjectCheck
                                    }
                                }
                                // Check whether the userID was recently requested to prevent duplicate requests
                                loopRecentRequests: for userID in userDataRequests
                                {
                                    if userID == blobContent.userID
                                    {
                                        userExists = true
                                        break loopRecentRequests
                                    }
                                }
                                // If the user has not been downloaded, request the user and the userImage and then notify the user
                                if !userExists
                                {
                                    AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: blobContent.userID, forPreviewData: false), delegate: self as AWSRequestDelegate).prepRequest()
                                    
                                    // Store the userID in recent requests to prevent duplicate requests
                                    userDataRequests.append(blobContent.userID)
                                }
                            }
                            else
                            {
                                Constants.Data.locationBlobContent.append(blobContent)
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("AD - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case let awsGetBlobContent as AWSGetBlobContent:
                    if success
                    {
//                        // Show the blob notification if needed
//                        UtilityFunctions().displayLocalBlobNotification(awsGetBlobContentData.blobContentID)
                    }
                    else
                    {
                        // Show the error message
                        UtilityFunctions().createAlertOkViewInTopVC("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    }
//                case let awsGetBlobMinimumData as AWSGetBlobData:
//                    if success
//                    {
//                        // Fire a notification to alert the user that a new Blob has been added
//                        print("AD-PAR-AGBMD - SUCCESS: \(awsGetBlobMinimumData.blobID)")
//                        UtilityFunctions().displayNewBlobNotification(newBlobID: awsGetBlobMinimumData.blobID)
//                        
//                        // Refresh the map so that the circle is added to the map
//                        self.mapViewController.refreshMap()
//                    }
//                    else
//                    {
//                        print("AD-PAR-AGBMD - ERROR")
//                        // Show the error message
//                        UtilityFunctions().createAlertOkViewInTopVC("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
//                    }
                case let awsGetSingleUserData as AWSGetSingleUserData:
                    if success
                    {
                        print("AD - GOT SINGLE USER DATA FOR USER: \(awsGetSingleUserData.user.userName)")
//                        // THIS ASSUMES THAT ONLY AN ACTIVE BLOB (IN RADIUS) NOTIFICATION WILL REQUEST THE SINGLE USER DATA IN APP DELEGATE
//                        if let blob = awsGetSingleUserData.targetBlob
//                        {
//                            // Fire a notification to alert the user that a new Blob has been added
//                            UtilityFunctions().displayNewBlobNotification(newBlobID: blob.blobID)
//                            
//                            // Refresh the map so that the circle is added to the map
//                            self.mapViewController.refreshMap()
//                        }
                    }
                    else
                    {
                        // Show the error message
                        UtilityFunctions().createAlertOkViewInTopVC("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    }
                case _ as AWSRegisterForPushNotifications:
                    if success
                    {
                        print("AD-PAR-ARFPN - SUCCESS")
                        
                    }
                    else
                    {
                        UtilityFunctions().createAlertOkViewInTopVC("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    }
                default:
                    print("AD-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    UtilityFunctions().createAlertOkViewInTopVC("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                }
        })
    }
}
