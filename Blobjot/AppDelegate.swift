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
import DigitsKit
import Fabric
import GoogleMaps
import GooglePlaces
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AWSRequestDelegate
{
    var window: UIWindow?
//    let navController = UINavigationController()
    var mapViewController: MapViewController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
//        let thisClass: String = NSStringFromClass(type(of: self))
        
        // Register with Digits (Fabric)
        Fabric.with([AWSCognito.self, Digits.self])
        
        // Register the device with Apple's Push Notification Service
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
        let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
        application.registerUserNotificationSettings(pushNotificationSettings)
        application.registerForRemoteNotifications()
        
        // Google Maps Prep
        GMSServices.provideAPIKey(Constants.Settings.gKey)
        GMSPlacesClient.provideAPIKey(Constants.Settings.gKey)
        
//        // AWS Cognito Prep
//        let configuration = AWSServiceConfiguration(region: Constants.Strings.awsRegion, credentialsProvider: Constants.credentialsProvider)
//        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // Prepare the root View Controller and make visible
//        let mainViewController = MainViewController()
        let loginViewController = LoginViewController()
//        self.navController.pushViewController(mainViewController, animated: false)
//        self.mapViewController = MapViewController()
//        self.navController.pushViewController(mapViewController, animated: false)
//        let cameraViewController = CameraViewController()
//        self.navController.pushViewController(cameraViewController, animated: false)
        
//        // stackoverflow.com/questions/24402000/uinavigationbar-text-color-in-swift
//        let navigationBarAppearace = UINavigationBar.appearance()
//        navigationBarAppearace.tintColor = Constants.Colors.colorTextNavBar
//        navigationBarAppearace.barTintColor = Constants.Colors.colorStatusBar
//        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName: Constants.Colors.colorTextNavBar]
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
//        self.navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
//        self.navController.navigationBar.tintColor = Constants.Colors.colorTextNavBar
//        self.navController.viewControllers = [mainViewController] // [cameraViewController] //
        self.window!.rootViewController = loginViewController
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
        
//        let coreDataFunctionsInstance = CoreDataFunctions()
//        coreDataFunctionsInstance.blobContentDeleteOld()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        CoreDataFunctions().processLogs()
        
        Constants.inBackground = true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        Constants.inBackground = true
        
//        // Delete Blobs and Users not recently used to save space
//        let coreDataFunctionsInstance = CoreDataFunctions()
//        coreDataFunctionsInstance.blobContentDeleteOld()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        Constants.inBackground = false
        
        Constants.appDelegateLocationManager.stopUpdatingLocation()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Constants.inBackground = false
        
        // Clear the badges
        Constants.Data.badgeNumber = 0
        UIApplication.shared.applicationIconBadgeNumber = Constants.Data.badgeNumber
        
        Constants.appDelegateLocationManager.stopUpdatingLocation()
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
//        AWSPrepRequest(requestToCall: AWSRegisterForPushNotifications(deviceToken: stringToken), delegate: self as AWSRequestDelegate).prepRequest()
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
        }
    }
    
    
    // MARK:  CUSTOM FUNCTIONS
    
    
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
