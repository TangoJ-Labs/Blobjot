//
//  AWSClasses.swift
//  Blobjot
//
//  Created by Sean Hart on 9/20/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSCognito
import AWSLambda
import AWSS3
import FBSDKLoginKit
import Foundation
import GoogleMaps


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol AWSRequestDelegate
{
    // A general handler to indicate that an AWS Method finished
    func processAwsReturn(_ requestCalled: AWSRequestObject, success: Bool)
    
    // A function all views should have to show a log in screen if needed
    func showLoginScreen()
}

class MyProvider : NSObject, AWSIdentityProviderManager
{
    var tokens: [NSString : NSString]?
    
    init(tokens: [NSString : NSString])
    {
        self.tokens = tokens
    }
    
    func logins() -> AWSTask<NSDictionary>
    {
        return AWSTask(result: tokens! as NSDictionary)
    }
}

class AWSPrepRequest
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var awsRequestDelegate: AWSRequestDelegate!
    
    var requestToCall: AWSRequestObject!
    
    required init(requestToCall: AWSRequestObject, delegate: AWSRequestDelegate)
    {
        self.requestToCall = requestToCall
        self.awsRequestDelegate = delegate
        self.requestToCall.awsRequestDelegate = delegate
    }
    
    // Use this method to call all other AWS methods to ensure that the user's credentials are still valid
    func prepRequest()
    {
        // If the server refresh time is past the minimum length, refresh the refresh loop catchers
        if Date().timeIntervalSince1970 - Constants.Data.serverLastRefresh > Constants.Settings.maxServerTryRefreshTime
        {
            Constants.Data.serverTries = 0
            Constants.Data.serverLastRefresh = Date().timeIntervalSince1970
        }
        
        // Ensure that the app is not continuously failing to access the server
        if Constants.Data.serverTries <= Constants.Settings.maxServerTries
        {
            // Check to see if the facebook user id is already in the FBSDK
            if let facebookToken = FBSDKAccessToken.current()
            {
                // Assign the Facebook Token to the AWSRequestObject
                self.requestToCall.facebookToken = facebookToken
                
                print("AC - COGNITO ID: \(Constants.credentialsProvider.identityId)")
                // Ensure that the Cognito ID is still valid and is not older than an hour (AWS will invalidate if older)
                if Constants.credentialsProvider.identityId != nil && Constants.Data.lastCredentials - NSDate().timeIntervalSinceNow < 3600
                {
                    // The Cognito ID is valid, so check for a Blobjot ID and then make the request
                    self.getBlobjotID(facebookToken: facebookToken)
                }
                else
                {
                    // If the Cognito credentials have expired, request the credentials again (Cognito Identity ID) and use the current Facebook info
                    self.getCognitoID()
                }
            }
            else
            {
                print("***** USER NEEDS TO LOG IN AGAIN *****")
                
                if let parentVC = self.awsRequestDelegate
                {
                    // Check to see if the parent viewcontroller is already the MapViewController.  If so, call the MVC showLoginScreen function
                    // Otherwise, launch a new MapViewController and show the login screen
                    if parentVC is MapViewController
                    {
                        // PARENT VC IS EQUAL TO MVC
                        parentVC.showLoginScreen()
                    }
                    else
                    {
                        // PARENT VC IS NOT EQUAL TO MVC
                        let newMapViewController = MapViewController()
                        if let rootNavController = UIApplication.shared.windows[0].rootViewController?.navigationController
                        {
                            rootNavController.pushViewController(newMapViewController, animated: true)
                        }
                    }
                }
            }
        }
        else
        {
            // Reset the server try count since the request cycle was stopped - the user can manually try again if needed
            Constants.Data.serverTries = 0
            Constants.Data.serverLastRefresh = Date().timeIntervalSince1970
        }
    }
    
    // Once the Facebook token is gained, request a Cognito Identity ID
    func getCognitoID()
    {
        print("AC - IN GET COGNITO ID: \(requestToCall.facebookToken)")
        if let token = requestToCall.facebookToken
        {
            print("AC - GETTING COGNITO ID: \(Constants.credentialsProvider.identityId)")
            print("AC - TOKEN: \(AWSIdentityProviderFacebook), \(token.tokenString)")
            // Authenticate the user in AWS Cognito
            Constants.credentialsProvider.logins = [AWSIdentityProviderFacebook: token.tokenString]
            
//            let identityProviderManager = MyProvider(tokens: [AWSIdentityProviderFacebook as NSString : token.tokenString as NSString])
//            let customProviderManager = CustomIdentityProvider(tokens: [AWSIdentityProviderFacebook as NSString: token.tokenString as NSString])
//            Constants.credentialsProvider = AWSCognitoCredentialsProvider(
//                regionType: Constants.Strings.awsRegion
//                , identityPoolId: Constants.Strings.awsCognitoIdentityPoolID
//                , identityProviderManager: customProviderManager
//            )
            
            // Retrieve your Amazon Cognito ID
            Constants.credentialsProvider.getIdentityId().continue(
                {(task: AWSTask!) -> AnyObject! in
                    
                    if (task.error != nil)
                    {
                        print("AC - AWS COGNITO GET IDENTITY ID - ERROR: " + task.error!.localizedDescription)
                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: task.error!.localizedDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Go ahead and move to the next login step
                        self.getBlobjotID(facebookToken: token)
                    }
                    else
                    {
                        // the task result will contain the identity id
                        let cognitoId = task.result
                        print("AC - AWS COGNITO GET IDENTITY ID - AWS COGNITO ID: \(cognitoId)")
                        print("AC - AWS COGNITO GET IDENTITY ID - CHECK IDENTITY ID: \(Constants.credentialsProvider.identityId)")
                        
                        // Save the current time to mark when the last CognitoID was saved
                        Constants.Data.lastCredentials = NSDate().timeIntervalSinceNow
                        
                        // Request extra facebook data for the user ON THE MAIN THREAD
                        DispatchQueue.main.async(execute:
                            {
                                print("AC - GOT COGNITO ID - GETTING NEW AWS ID")
                                self.getBlobjotID(facebookToken: token)
                        });
                    }
                    return nil
            })
        }
    }
    
    // After ensuring that the Cognito ID is valid, so check for a Blobjot ID and then make the request
    func getBlobjotID(facebookToken: FBSDKAccessToken!)
    {
        // If the Identity ID is still valid, ensure that the current userID is not nil
        if Constants.Data.currentUser.userID != nil
        {
            // The user is already logged in so go ahead and register for notifications
//            UtilityFunctions().registerPushNotifications()
            
            // FIRING REQUEST
            // All login info is current; go ahead and fire the needed method
            self.requestToCall.facebookToken = facebookToken
            self.requestToCall.makeRequest()
        }
        else
        {
            // The current ID is nil, so request it from AWS, but store the previous request and call it when the
            let awsLoginUser = AWSLoginUser(secondaryAwsRequestObject: self.requestToCall)
            awsLoginUser.awsRequestDelegate = self.awsRequestDelegate
            awsLoginUser.facebookToken = facebookToken
            awsLoginUser.makeRequest()
        }
    }
}


/// A base class to group membership of all AWS request functions
class AWSRequestObject
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var awsRequestDelegate: AWSRequestDelegate?
    
    var facebookToken: FBSDKAccessToken?
    
    func makeRequest() {}
}


/**
 Properties:
 - secondaryAwsRequestObject- An optional property that allows the original request to be carried by the login request, when the login request is fired by the prepRequest class due to no user being logged in.  This property should not be used for AWSLoginUser calls based directly on user interaction
 */
class AWSLoginUser : AWSRequestObject
{
    var secondaryAwsRequestObject: AWSRequestObject?
    
    required init(secondaryAwsRequestObject: AWSRequestObject?)
    {
        self.secondaryAwsRequestObject = secondaryAwsRequestObject
    }
    
    // FBSDK METHOD - Get user data from FB before attempting to log in via AWS
    override func makeRequest()
    {
        print("AC - FBSDK - COGNITO ID: \(Constants.credentialsProvider.identityId)")
        let fbRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, picture"]) //parameters: ["fields": "id,email,name,picture"])
        print("FBSDK - MAKING GRAPH CALL")
        fbRequest?.start
            {(connection: FBSDKGraphRequestConnection?, result: Any?, error: Error?) in
                
                if error != nil
                {
                    print("FBSDK - Error Getting Info \(error)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Getting Info" + error!.localizedDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Try again
                    AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self.awsRequestDelegate!).prepRequest()
                }
                else
                {
                    if let resultDict = result as? [String:AnyObject]
                    {
//                        if let resultPicture = resultDict["picture"] as? [String:AnyObject]
//                        {
//                            if let resultPictureData = resultPicture["data"] as? [String:AnyObject]
//                            {
//                                print("FBSDK - IMAGE URL : \(resultPictureData["url"])")
//                            }
//                        }
                        
                        if let facebookName = resultDict["name"]
                        {
                            var facebookImageUrl = "none"
                            if let resultPicture = resultDict["picture"] as? [String:AnyObject]
                            {
                                if let resultPictureData = resultPicture["data"] as? [String:AnyObject]
                                {
                                    facebookImageUrl = resultPictureData["url"]! as! String
                                }
                            }
                            self.loginUser((facebookName as! String), facebookThumbnailUrl: facebookImageUrl)
                        }
                        else
                        {
                            print("FBSDK - Error Processing Facebook Name")
                            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Processing Facebook Name" + error!.localizedDescription)
                            
                            // Record the server request attempt
                            Constants.Data.serverTries += 1
                            
                            // Try again
                            AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self.awsRequestDelegate!).prepRequest()
                        }
                    }
                    else
                    {
                        print("FBSDK - Error Processing Result")
                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Processing Result" + error!.localizedDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Try again
                        AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self.awsRequestDelegate!).prepRequest()
                    }
                }
        }
    }
    
    // Log in the user or create a new user
    func loginUser(_ facebookName: String, facebookThumbnailUrl: String)
    {
        print("AC - LU - FACEBOOK TOKEN: \(self.facebookToken)")
        print("AC - LU - COGNITO ID: \(Constants.credentialsProvider.identityId)")
        let json: NSDictionary = ["facebook_id" : self.facebookToken!.userID]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-LoginUser", jsonObject: json, completionHandler:
            { (responseData, err) -> Void in
                
                if (err != nil)
                {
                    print("AC - FBSDK LOGIN - ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the login attempt
                    Constants.Data.serverTries += 1
                    
                    DispatchQueue.main.async(execute:
                        {
                            // Notify the parent view that the AWS call completed with an error
                            if let parentVC = self.awsRequestDelegate
                            {
                                parentVC.processAwsReturn(self, success: false)
                                
//                                // Try again
//                                AWSPrepRequest(requestToCall: self, delegate: parentVC).prepRequest()
                                
                                // Check to see if the parent viewcontroller is already the MapViewController.  If so, call the MVC showLoginScreen function
                                // Otherwise, launch a new MapViewController and show the login screen
                                if parentVC is MapViewController
                                {
                                    // PARENT VC IS EQUAL TO MVC
                                    parentVC.showLoginScreen()
                                }
                                
                                // Reset the server try count since the request cycle was stopped - the user can manually try again if needed
                                Constants.Data.serverTries = 0
                                Constants.Data.serverLastRefresh = Date().timeIntervalSince1970
                            }
                    })
                    
                }
                else if (responseData != nil)
                {
                    // Create a user object to save the data
                    let currentUser = User()
                    currentUser.userID = responseData as? String
                    currentUser.facebookID = self.facebookToken!.userID
                    currentUser.userName = facebookName
                    currentUser.userImage = UIImage(named: "PROFILE_DEFAULT.png")
                    
                    // The response will be the userID associated with the facebookID used, save the current user globally
                    Constants.Data.currentUser = currentUser
                    
                    // Save the new login data to Core Data
                    CoreDataFunctions().currentUserSave(user: currentUser)
                    
                    // Reset the global User list with Core Data
                    UtilityFunctions().resetUserListWithCoreData()
                    
//                    UtilityFunctions().registerPushNotifications()
                    
                    // Recall the user's Facebook likes to match with Public Blobs (Blobjot Blobs)
                    AWSPrepRequest(requestToCall: FBGetUserLikes(), delegate: self.awsRequestDelegate!).prepRequest()
                    
                    // If the secondary request object is not nil, process the carried (second) request; no need to
                    // pass the login response to the parent view controller since it did not explicitly call the login request
                    if let secondaryAwsRequestObject = self.secondaryAwsRequestObject
                    {
                        AWSPrepRequest(requestToCall: secondaryAwsRequestObject, delegate: self.awsRequestDelegate!).prepRequest()
                    }
                    else
                    {
                        // Notify the parent view that the AWS Login call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                }
        })
    }
}

class AWSLogoutUser
{
    
}

class AWSGetMapData : AWSRequestObject
{
    // The initial request for Map Blob data - called when the View Controller is instantiated
    override func makeRequest()
    {
        print("AC-GMD - COGNITO ID: \(Constants.credentialsProvider.identityId)")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser.userID!]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetMapData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GMD - GET MAP DATA ERROR: \(err)")
                    print("AC-GMD - GET MAP DATA ERROR CODE: \(err!._code)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Process the error codes and alert the user if needed
                    if err!._code == 1 && Constants.Data.currentUser.userID != nil
                    {
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                }
                else if (response != nil)
                {
                    // Convert the response to an array of AnyObjects
                    // The first item will be an array of JSON Blobs; the second item will be an array of JSON ContentBlobs
                    if let responseData = response as? [String: Any]
                    {
                        // The first item will be an array of JSON Blobs
                        if let newMapBlobs = responseData["blobs"] as? [Any]
                        {
                            print("AC-GMD - BLOB COUNT: \(newMapBlobs.count)")
                            // Always clear the mapCircles before clearing the mapBlobs data otherwise the circles will be unresponsive
                            // Each circle must individually have their map nullified, otherwise the mapView will still display the circle
                            for circle in Constants.Data.mapCircles
                            {
                                circle.map = nil
                            }
                            Constants.Data.mapCircles = [GMSCircle]()
                            
                            // Create a local mapBlobs array to remember which Blobs should be shown on the map
                            var rememberMapBlobIDs = [String]()
                            
                            // Loop through each AnyObject (Blob) in the array
                            for newBlob in newMapBlobs
                            {
                                // Convert the AnyObject to JSON with keys and AnyObject values
                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                if let checkBlob = newBlob as? [String: Any]
                                {
                                    // Finish converting the JSON AnyObjects and assign the data to a new Blob Object
                                    let addBlob = Blob()
                                    addBlob.blobID = checkBlob["blobID"] as! String
                                    addBlob.blobDatetime = Date(timeIntervalSince1970: checkBlob["blobTimestamp"] as! Double)
                                    addBlob.blobLat = checkBlob["blobLat"] as! Double
                                    addBlob.blobLong = checkBlob["blobLong"] as! Double
                                    addBlob.blobRadius = checkBlob["blobRadius"] as! Double
                                    addBlob.blobType = Constants().blobType(checkBlob["blobType"] as! Int)
                                    if let blobAccount = checkBlob["blobAccount"]
                                    {
                                        addBlob.blobAccount = Constants().blobAccount(blobAccount as! Int)
                                    }
                                    if let blobFeature = checkBlob["blobFeature"]
                                    {
                                        addBlob.blobFeature = Constants().blobFeature(blobFeature as! Int)
                                    }
                                    if let blobAccess = checkBlob["blobAccess"]
                                    {
                                        addBlob.blobAccess = Constants().blobAccess(blobAccess as! Int)
                                    }
                                    
                                    // Loop through the global Blobs list and add the Blob if it does not exist (modify the data if it does exist)
                                    var blobExists = false
                                    blobLoop: for blob in Constants.Data.allBlobs
                                    {
                                        if blob.blobID == addBlob.blobID
                                        {
                                            blobExists = true
                                            blob.blobID = addBlob.blobID
                                            blob.blobDatetime = addBlob.blobDatetime
                                            blob.blobLat = addBlob.blobLat
                                            blob.blobLong = addBlob.blobLong
                                            blob.blobRadius = addBlob.blobRadius
                                            blob.blobType = addBlob.blobType
                                            blob.blobAccount = addBlob.blobAccount
                                            blob.blobFeature = addBlob.blobFeature
                                            blob.blobAccess = addBlob.blobAccess
                                            break blobLoop
                                        }
                                    }
                                    if !blobExists
                                    {
                                        Constants.Data.allBlobs.append(addBlob)
                                    }
                                    
                                    // Append the new Blob Object to the local Map BlobIDs Array (it was cleared earlier)
                                    // To remember which ones to add to the global array
                                    rememberMapBlobIDs.append(addBlob.blobID)
                                    print("AC-GMD - ADDED BLOB: \(addBlob.blobID)")
                                }
                            }
                            
                            // Clear global mapBlobs other than place Blobs
                            Constants.Data.mapBlobIDs = [String]()
                            
                            // Sort all Blobs, then using the local mapBlobs array to remember which ones to
                            // include on the map, create a sorted mapBlobIDs array
                            _ = UtilityFunctions().sortBlobs(blobs: Constants.Data.allBlobs)
                            for aBlob in Constants.Data.allBlobs
                            {
                                // Determine if the Blob is in the local mapBlobs array to remember if it should be included
                                rememberBlobLoop: for rBlobID in rememberMapBlobIDs
                                {
                                    if rBlobID == aBlob.blobID
                                    {
                                        // The Blob should be included, so add it to the global MapBlobs array since it will now be in the correct order
                                        Constants.Data.mapBlobIDs.append(rBlobID)
                                        break rememberBlobLoop
                                    }
                                }
                            }
                            
                            // Notify the parent view that the AWS call completed successfully
                            if let parentVC = self.awsRequestDelegate
                            {
                                print("AC-GMD - CALLED PARENT")
                                parentVC.processAwsReturn(self, success: true)
                            }
                        }
                        
                        // The second item will be an array of JSON ContentBlobs
                        if let newContentBlobs = responseData["blob_content"] as? [Any]
                        {
                            print("AC-GMD - BLOB CONTENT COUNT: \(newContentBlobs.count)")
                            
                            // Clear global contentBlobs
                            Constants.Data.blobContent = [BlobContent]()
                            
                            // Loop through each AnyObject (Content) in the array
                            for newContent in newContentBlobs
                            {
                                // Convert the AnyObject to JSON with keys and AnyObject values
                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                if let checkContent = newContent as? [String: Any]
                                {
                                    // Finish converting the JSON AnyObjects and assign the data to a new BlobContent Object
                                    let addContent = BlobContent()
                                    addContent.blobContentID    = checkContent["blobContentID"] as! String
                                    addContent.blobID           = checkContent["blobID"] as! String
                                    addContent.userID           = checkContent["contentUserID"] as! String
                                    addContent.contentDatetime  = Date(timeIntervalSince1970: checkContent["contentTimestamp"] as! Double)
                                    addContent.contentType      = Constants().contentType(checkContent["contentType"] as! Int)
                                    addContent.response                 = checkContent["response"] as! Bool
                                    addContent.respondingToContentID    = checkContent["respondingToContentID"] as? String
                                    
                                    // The text and media data will not be included in the mapData download
                                    
                                    // Loop through the global blobContent list and add the BlobContent if it does not exist (modify the data if it does exist)
                                    var blobContentExists = false
                                    blobContentLoop: for blobContent in Constants.Data.blobContent
                                    {
                                        if blobContent.blobContentID == addContent.blobContentID
                                        {
                                            blobContentExists = true
                                            blobContent.blobContentID = addContent.blobContentID
                                            blobContent.blobID = addContent.blobID
                                            blobContent.userID = addContent.userID
                                            blobContent.contentDatetime = addContent.contentDatetime
                                            blobContent.contentType = addContent.contentType
                                            blobContent.response = addContent.response
                                            blobContent.respondingToContentID = addContent.respondingToContentID
                                            break blobContentLoop
                                        }
                                    }
                                    if !blobContentExists
                                    {
                                        // Append the new BlobContent Object to the global blobContent Array
                                        Constants.Data.blobContent.append(addContent)
                                    }
                                    print("AC-GMD - ADDED BLOB CONTENT: \(addContent.blobContentID)")
                                }
                            }
                            
                            // Notify the parent view that the AWS call completed successfully
                            if let parentVC = self.awsRequestDelegate
                            {
                                print("AC-GMD - CALLED PARENT")
                                parentVC.processAwsReturn(self, success: true)
                            }
                        }
                    }
                }
        })
    }
}

class AWSGetBlobData : AWSRequestObject
{
    var blobID: String!
    var notifyUser: Bool = false
    
    required init(blobID: String, notifyUser: Bool?)
    {
        self.blobID = blobID
        if let notify = notifyUser
        {
            self.notifyUser = notify
        }
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    override func makeRequest()
    {
        print("AC-GBMD: REQUESTING GBMD FOR BLOB: \(self.blobID)")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        let json: NSDictionary = ["blob_id" : self.blobID, "filter" : 1]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetBlobData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GBMD: GET BLOB MINIMUM DATA ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    // Convert the response to JSON with keys and AnyObject values
                    // Then convert the AnyObject values to Strings or Numbers depending on their key
                    if let checkBlob = response as? [String: AnyObject]
                    {
                        let addBlob = Blob()
                        addBlob.blobID = checkBlob["blobID"] as! String
                        addBlob.blobDatetime = Date(timeIntervalSince1970: checkBlob["blobTimestamp"] as! Double)
                        addBlob.blobLat = checkBlob["blobLat"] as! Double
                        addBlob.blobLong = checkBlob["blobLong"] as! Double
                        addBlob.blobRadius = checkBlob["blobRadius"] as! Double
                        addBlob.blobType = Constants().blobType(checkBlob["blobType"] as! Int)
                        if let blobAccount = checkBlob["blobAccount"]
                        {
                            addBlob.blobAccount = Constants().blobAccount(blobAccount as! Int)
                        }
                        if let blobFeature = checkBlob["blobFeature"]
                        {
                            addBlob.blobFeature = Constants().blobFeature(blobFeature as! Int)
                        }
                        if let blobAccess = checkBlob["blobAccess"]
                        {
                            addBlob.blobAccess = Constants().blobAccess(blobAccess as! Int)
                        }
                        
                        Constants.Data.allBlobs.append(addBlob)
                    }
                }
        })
    }
}

class AWSGetBlobContentData : AWSRequestObject
{
    var blobContentID: String!
    var minimalOnly: Bool!
    
    required init(blobContentID: String, minimalOnly: Bool)
    {
        self.blobContentID = blobContentID
        self.minimalOnly = minimalOnly
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra BlobContent data is needed
    override func makeRequest()
    {
        print("AWSM-GBD: REQUESTING GBD FOR BLOB CONTENT: \(self.blobContentID)")
        
        // Create a JSON object with the passed BlobContent ID
        let json: NSDictionary = ["blob_content_id" : self.blobContentID, "minimal_only" : Int(self.minimalOnly)]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetBlobContentData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AWSM-GBD: GET BLOB DATA ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    // Convert the response to JSON with keys and AnyObject values
                    // Then convert the AnyObject values to Strings or Numbers depending on their key
                    // Start with converting the BlobContent ID to a String
                    if let newBlobContent = response as? [String: AnyObject]
                    {
                        let addBlobContent = BlobContent()
                        addBlobContent.blobContentID = newBlobContent["blobContentID"] as! String
                        addBlobContent.blobID = newBlobContent["blobID"] as! String
                        addBlobContent.userID = newBlobContent["contentUserID"] as! String
                        addBlobContent.contentDatetime = Date(timeIntervalSince1970: newBlobContent["timestamp"] as! Double)
                        addBlobContent.contentType = Constants.ContentType(rawValue: newBlobContent["contentType"] as! Int)
                        addBlobContent.response = Bool(newBlobContent["response"] as! NSNumber)
                        
                        addBlobContent.respondingToContentID = newBlobContent["respondingToContentID"] as? String
                        addBlobContent.contentMediaID = newBlobContent["contentMediaID"] as? String
                        addBlobContent.contentThumbnailID = newBlobContent["contentThumbnailID"] as? String
                        addBlobContent.contentText = newBlobContent["contentText"] as? String
                        
                        // Find the Blob in the global Map Blobs array and add the extra data to the Blob
                        var blobContentExists = false
                        loopBlobContentCheck: for bContent in Constants.Data.blobContent
                        {
                            if bContent.blobContentID == addBlobContent.blobContentID
                            {
                                blobContentExists = true
                                
                                bContent.blobID = addBlobContent.blobID
                                bContent.userID = addBlobContent.userID
                                bContent.contentDatetime = addBlobContent.contentDatetime
                                bContent.contentType = addBlobContent.contentType
                                bContent.response = addBlobContent.response
                                
                                bContent.respondingToContentID = addBlobContent.respondingToContentID
                                bContent.contentMediaID = addBlobContent.contentMediaID
                                bContent.contentThumbnailID = addBlobContent.contentThumbnailID
                                bContent.contentText = addBlobContent.contentText
                                
                                break loopBlobContentCheck
                            }
                        }
                        // If the blobContent does not exist, append it to the global array
                        if !blobContentExists
                        {
                            Constants.Data.blobContent.append(addBlobContent)
                        }
                        
                        // ...and request the Thumbnail image data if the Thumbnail ID is not null
                        if let thumbnailID = addBlobContent.contentThumbnailID
                        {
                            // Ensure the thumbnail does not already exist
                            var thumbnailExists = false
                            loopThumbnailCheck: for tObject in Constants.Data.thumbnailObjects
                            {
                                // Check to see if the thumbnail Object ID matches
                                if tObject.thumbnailID == thumbnailID
                                {
                                    thumbnailExists = true
                                    
                                    break loopThumbnailCheck
                                }
                            }
                            // If the thumbnail does not exist, download it and append it to the global Thumbnail array
                            if !thumbnailExists
                            {
                                let awsGetThumbnail = AWSGetThumbnailImage(contentThumbnailID: thumbnailID)
                                awsGetThumbnail.awsRequestDelegate = self.awsRequestDelegate
                                awsGetThumbnail.makeRequest()
                            }
                        }
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                }
        })
    }
}

class AWSGetSingleUserData : AWSRequestObject
{
    var user: User!
    var userID: String!
    var forPreviewData: Bool!
    var targetBlob: Blob?
    
    required init(userID: String, forPreviewData: Bool)
    {
        self.userID = userID
        self.forPreviewData = forPreviewData
        
        self.user = User()
        self.user.userID = userID
    }
    
    // The initial request for User data
    override func makeRequest()
    {
        print("AC-AGSUD - REQUESTING GSUD FOR USER: \(userID), USERNAME: \(user.userName)")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : self.user.userID!, "requesting_user_id" : Constants.Data.currentUser.userID!]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetSingleUserData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-AGSUD - GET USER CONNECTIONS DATA ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    // Convert the response to an array of arrays
                    if let userJson = response as? [String: AnyObject]
                    {
                        let facebookID = userJson["facebook_id"] as! String
                        let userStatus = userJson["user_status"] as! Int
                        
                        // Add other properties to the User object
                        self.user.facebookID = facebookID
                        self.user.userStatus = Constants().userStatusType(userStatus)
                        
                        // NOTE: No need to update the Current User Object here - the FB ID and userID will not change, update in FBGetUserProfileData
                        // Check to ensure the user does not already exist in the global User array
                        var userObjectExists = false
                        loopUserObjectCheck: for userObject in Constants.Data.userObjects
                        {
                            if userObject.userID == self.user.userID
                            {
                                // Replace the global user with the updated local one
                                userObject.facebookID = self.user.facebookID
                                userObject.userStatus = self.user.userStatus
                                
                                userObjectExists = true
                                break loopUserObjectCheck
                            }
                        }
                        if !userObjectExists
                        {
                            Constants.Data.userObjects.append(self.user)
                        }
                        
                        // Request the Facebook Info (Name and Image)
                        // Always request the FB data to ensure the latest is used
                        AWSPrepRequest(requestToCall: FBGetUserProfileData(user: self.user, downloadImage: true), delegate: self.awsRequestDelegate!).prepRequest()
                        
                        // Don't save the user to Core Data here; wait until the FB data is downloaded to capture all data
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                }
        })
    }
}

class AWSGetUserConnections : AWSRequestObject
{
    // The initial request for Map Blob data - called when the View Controller is instantiated
    override func makeRequest() {
        print("AC-GUC - REQUESTING GUC")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser.userID!, "print_check" : "BAP"]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetUserConnections", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GUC DATA ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if (response != nil)
                {
                    print("AWS - USER CONNECTIONS: \(response)")
                    // Convert the response to an array of arrays
                    if let newUserConnectionArrays = response as? [[AnyObject]]
                    {
                        if let currentUserID = Constants.Data.currentUser.userID
                        {
                            // Loop through the arrays and add each user - the arrays should be in the proper order by user type
                            for (arrayIndex, userArray) in newUserConnectionArrays.enumerated()
                            {
                                // Loop through each AnyObject (User) in the array
                                for user in userArray
                                {
                                    // Convert the AnyObject to JSON with keys and AnyObject values
                                    // Then convert the AnyObject values to Strings or Numbers depending on their key
                                    if let checkUser = user as? [String: AnyObject]
                                    {
                                        let userID = checkUser["user_id"] as! String
                                        let facebookID = checkUser["facebook_id"] as! String
                                        let userStatus = Constants.UserStatusType(rawValue: arrayIndex)
                                        
                                        // Create a User Object and add it to the global User array
                                        let addUser = User()
                                        addUser.userID = userID
                                        addUser.facebookID = facebookID
                                        addUser.userStatus = userStatus!
                                        
                                        // Check to ensure the user does not already exist in the global User array
                                        // Add the minimal user data to the array
                                        var userObjectExists = false
                                        loopUserObjectCheck: for userObject in Constants.Data.userObjects
                                        {
                                            if userObject.userID == userID
                                            {
                                                userObject.userStatus = userStatus!
                                                
                                                // If the user is the currently logged in user, ensure that the user is connected to themselves
                                                if userObject.userID! == currentUserID
                                                {
                                                    userObject.userStatus = Constants.UserStatusType.following
                                                }
                                                else
                                                {
                                                    userObject.userStatus = userStatus!
                                                }
                                                
                                                userObjectExists = true
                                                break loopUserObjectCheck
                                            }
                                        }
                                        if !userObjectExists
                                        {
                                            Constants.Data.userObjects.append(addUser)
                                        }
                                        
                                        // Download the FB data, but not the image - the user data is likely used in the tables, and images should
                                        // only be downloaded when needed in the table
                                        // NOTE: No need to update the Current User Object here - the FB ID and userID will not change, update in FBGetUserProfileData
                                        AWSPrepRequest(requestToCall: FBGetUserProfileData(user: addUser, downloadImage: false), delegate: self.awsRequestDelegate!).prepRequest()
                                    }
                                }
                            }
                        }
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                }
        })
    }
}

/**
 Properties:
 - randomIdType- The string passed to AWS to indicate what type of random ID is being requested.  Should be either:
 -- "random_media_id" - an ID type for new media
 -- "random_user_image_id" - an ID type for user images
 */
class AWSGetRandomID : AWSRequestObject
{
    var randomID: String?
    var randomIdType: String!
    
    required init(randomIdType: String)
    {
        self.randomIdType = randomIdType
    }
    
    // Request a random MediaID
    override func makeRequest()
    {
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["request" : "random_media_id"]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-CreateRandomID", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("GET RANDOM ID ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if (response != nil)
                {
                    // Convert the response to a String
                    if let newRandomID = response as? String
                    {
                        self.randomID = newRandomID
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                }
        })
    }
}

class AWSUploadMediaToBucket : AWSRequestObject
{
    var bucket: String!
    var uploadMediaFilePath: String!
    var mediaID: String!
    var uploadKey: String!
    var currentTime: Double!
    var deleteWhenFinished: Bool!
    
    required init(bucket: String, uploadMediaFilePath: String, mediaID: String, uploadKey: String, currentTime: Double, deleteWhenFinished: Bool)
    {
        self.bucket = bucket
        self.uploadMediaFilePath = uploadMediaFilePath
        self.mediaID = mediaID
        self.uploadKey = uploadKey
        self.currentTime = currentTime
        self.deleteWhenFinished = deleteWhenFinished
    }
    
    // Upload a file to AWS S3
    override func makeRequest()
    {
        print("UPLOADING FILE: \(uploadKey) TO BUCKET: \(bucket)")
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.bucket = bucket
        uploadRequest?.key =  uploadKey
        uploadRequest?.body = URL(fileURLWithPath: uploadMediaFilePath)
        
        let transferManager = AWSS3TransferManager.default()
        transferManager?.upload(uploadRequest).continue(
            { (task) -> AnyObject! in
                
                if let error = task.error
                {
                    if error._domain == AWSS3TransferManagerErrorDomain as String
                        && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused
                    {
                        print("Upload paused.")
                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "MEDIA UPLOAD PAUSED")
                    }
                    else
                    {
                        print("Upload failed: [\(error)]")
                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                    }
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if let exception = task.exception
                {
                    print("Upload failed: [\(exception)]")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: exception.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else
                {
                    print("Upload succeeded")
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
                    }
                    
                    // If the file was flagged for deletion, delete it
                    if self.deleteWhenFinished!
                    {
                        do
                        {
                            try FileManager.default.removeItem(atPath: self.uploadMediaFilePath)
                        }
                        catch let error as NSError
                        {
                            print("ERROR DELETING FILE: \(error)")
                            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.debugDescription)
                        }
                    }
                }
                return nil
        })
    }
}

class AWSUploadBlobData : AWSRequestObject
{
    var blob: Blob!
    var blobContent: BlobContent!
    
    required init(blob: Blob, blobContent: BlobContent)
    {
        self.blob = blob
        self.blobContent = blobContent
    }
    
    // Upload data to Lambda for transfer to DynamoDB
    override func makeRequest()
    {
        print("SENDING DATA TO LAMBDA")
        
        // Create some JSON to send the Blob data
        var json = [String: Any]()
        json["blobID"]          = blob.blobID
        json["blobLat"]         = String(blob.blobLat)
        json["blobLong"]        = String(blob.blobLong)
        json["blobRadius"]      = String(blob.blobRadius)
        json["blobType"]        = String(blob.blobType.rawValue)
        json["blobAccount"]     = String(blob.blobAccount.rawValue)
        json["blobFeature"]     = String(blob.blobFeature.rawValue)
        json["blobAccess"]      = String(blob.blobAccess.rawValue)
        json["response"]            = blobContent.response
        json["contentID"]           = blobContent.blobContentID
        json["contentUserID"]       = blobContent.userID
        json["contentTimestamp"]    = String(blobContent.contentDatetime.timeIntervalSince1970)
        json["contentType"]         = String(blobContent.contentType.rawValue)
        json["contentText"]         = blobContent.contentText
        json["contentThumbnailID"]  = blobContent.contentThumbnailID
        json["contentMediaID"]      = blobContent.contentMediaID
        json["uploaderUserName"]    = Constants.Data.currentUser.userName
        
        print("LAMBDA JSON: \(json)")
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-CreateBlob", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("SENDING DATA TO LAMBDA ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    if let responsesArray = response as? [Any]
                    {
                        if let blobID = responsesArray[0] as? String
                        {
                            if blobID == self.blob.blobID
                            {
                                // The first String in the response indicated that the new BlobID was used,
                                // which means that a new Blob was created
                                // Add the new Blob to the Blob list using the Blob data
                                let addBlob = Blob()
                                addBlob.blobID = self.blob.blobID
                                addBlob.blobDatetime = self.blob.blobDatetime
                                addBlob.blobLat = self.blob.blobLat
                                addBlob.blobLong = self.blob.blobLong
                                addBlob.blobRadius = self.blob.blobRadius
                                addBlob.blobType = self.blob.blobType
                                addBlob.blobAccount = self.blob.blobAccount
                                addBlob.blobFeature = self.blob.blobFeature
                                addBlob.blobAccess = self.blob.blobAccess
                                
                                Constants.Data.allBlobs.append(addBlob)
                            }
                            else
                            {
                                // The response is a different BlobID, which means a new Blob was not created, but a similar one was used
                                // Look up this Blob in the global Blob list and add the new content, if it exists
                                // Otherwise just recall the Blob and add the new content
                                var blobExists = false
                                blobLoop: for blob in Constants.Data.allBlobs
                                {
                                    if blob.blobID == blobID
                                    {
                                        blobExists = true
                                        // DO NOT REPLACE THE EXISTING BLOB CONTENT - THE SYSTEM WILL USE THIS BLOB CONTENT, NOT NEW DATA
                                        break blobLoop
                                    }
                                }
                                
                                // The blob is not already downloaded, so request the Blob data and add to the map
                                if !blobExists
                                {
                                    AWSPrepRequest(requestToCall: AWSGetBlobData(blobID: blobID, notifyUser: false), delegate: self.awsRequestDelegate!).prepRequest()
                                }
                            }
                            
                            // Now that the Blob has been added, add the BlobContent to the global array
                            let addContent = BlobContent()
                            addContent.blobContentID    = self.blobContent.blobContentID
                            addContent.blobID           = self.blobContent.blobID
                            addContent.userID           = self.blobContent.userID
                            addContent.contentDatetime  = self.blobContent.contentDatetime
                            addContent.contentType      = self.blobContent.contentType
                            addContent.response                 = self.blobContent.response
                            addContent.respondingToContentID    = self.blobContent.respondingToContentID
                            
                            addContent.contentText          = self.blobContent.contentText
                            addContent.contentMediaID       = self.blobContent.contentMediaID
                            addContent.contentThumbnailID   = self.blobContent.contentThumbnailID
                            addContent.contentThumbnail     = self.blobContent.contentThumbnail
                            
                            Constants.Data.blobContent.append(addContent)
                        }
                    }
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}

class AWSHideBlob : AWSRequestObject
{
    var blobID: String!
    var userID: String!
    
    required init(blobID: String, userID: String)
    {
        self.blobID = blobID
        self.userID = userID
    }
    
    // Add a record that this Blob was viewed by the logged in user
    override func makeRequest()
    {
        print("ADDING BLOB VIEW: \(self.blobID), \(self.userID), \(Date().timeIntervalSince1970)")
        var json = [String: Any]()
        json["blob_id"]     = self.blobID
        json["user_id"]     = self.userID
        json["timestamp"]   = String(Date().timeIntervalSince1970)
        json["action_type"] = "hide"
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-AddBlobAction", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("ADD BLOB VIEW ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-ABV: response: \(response)")
                }
        })
    }
}

class AWSDeleteBlob : AWSRequestObject
{
    var blobID: String!
    var userID: String!
    
    required init(blobID: String, userID: String)
    {
        self.blobID = blobID
        self.userID = userID
    }
    
    // Add a record that this Blob was viewed by the logged in user
    override func makeRequest()
    {
        print("ADDING BLOB DELETE: \(self.blobID), \(self.userID), \(Date().timeIntervalSince1970)")
        var json = [String: Any]()
        json["blob_id"]     = self.blobID
        json["user_id"]     = self.userID
        json["timestamp"]   = String(Date().timeIntervalSince1970)
        json["action_type"] = "delete"
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-AddBlobAction", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("ADD BLOB DELETE ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-DB: response: \(response)")
                }
        })
    }
}

class AWSGetUserBlobContent : AWSRequestObject
{
    // The initial request for User's Blob data - called when the View Controller is instantiated
    override func makeRequest()
    {
        print("AC - GUBC - REQUESTING GUB")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser.userID!]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetUserBlobs", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC - GUBC - GET USER BLOBS DATA ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    // Convert the response to an array of AnyObjects
                    if let rawUserBlobContent = response as? [AnyObject]
                    {
                        print("AC - GUBC - BLOB CONTENT COUNT: \(rawUserBlobContent.count)")
                        
                        // Reset the IDs array
                        Constants.Data.userBlobContentIDs = [String]()
                        
                        // Loop through each AnyObject (Blob) in the array
                        // Save them to the global userBlob array
                        // Save them to Core Data
                        for rawBlobContentObject in rawUserBlobContent
                        {
                            // Convert the AnyObject to JSON with keys and AnyObject values
                            // Then convert the AnyObject values to Strings or Numbers depending on their key
                            if let newBlobContent = rawBlobContentObject as? [String: AnyObject]
                            {
                                let addBlobContent = BlobContent()
                                addBlobContent.blobContentID = newBlobContent["blobContentID"] as! String
                                addBlobContent.blobID = newBlobContent["blobID"] as! String
                                addBlobContent.userID = newBlobContent["contentUserID"] as! String
                                addBlobContent.contentDatetime = Date(timeIntervalSince1970: newBlobContent["timestamp"] as! Double)
                                addBlobContent.contentType = Constants.ContentType(rawValue: newBlobContent["contentType"] as! Int)
                                addBlobContent.response = Bool(newBlobContent["response"] as! NSNumber)
                                
                                addBlobContent.respondingToContentID = newBlobContent["respondingToContentID"] as? String
                                addBlobContent.contentMediaID = newBlobContent["contentMediaID"] as? String
                                addBlobContent.contentThumbnailID = newBlobContent["contentThumbnailID"] as? String
                                addBlobContent.contentText = newBlobContent["contentText"] as? String
                                
                                // Find the Blob in the global Map Blobs array and add the extra data to the Blob
                                var blobContentExists = false
                                loopBlobContentCheck: for bContent in Constants.Data.blobContent
                                {
                                    if bContent.blobContentID == addBlobContent.blobContentID
                                    {
                                        blobContentExists = true
                                        
                                        bContent.blobID = addBlobContent.blobID
                                        bContent.userID = addBlobContent.userID
                                        bContent.contentDatetime = addBlobContent.contentDatetime
                                        bContent.contentType = addBlobContent.contentType
                                        bContent.response = addBlobContent.response
                                        
                                        bContent.respondingToContentID = addBlobContent.respondingToContentID
                                        bContent.contentMediaID = addBlobContent.contentMediaID
                                        bContent.contentThumbnailID = addBlobContent.contentThumbnailID
                                        bContent.contentText = addBlobContent.contentText
                                        
                                        break loopBlobContentCheck
                                    }
                                }
                                // If the blobContent does not exist, append it to the global array
                                if !blobContentExists
                                {
                                    Constants.Data.blobContent.append(addBlobContent)
                                }
                                
                                // Check whether the Blob for this BlobContent already exists - if not, download it
                                var blobExists = false
                                blobLoop: for blob in Constants.Data.allBlobs
                                {
                                    if blob.blobID == addBlobContent.blobID
                                    {
                                        blobExists = true
                                        // DO NOT REPLACE THE EXISTING BLOB CONTENT - THE SYSTEM WILL USE THIS BLOB CONTENT, NOT NEW DATA
                                        break blobLoop
                                    }
                                }
                                
                                // The blob is not already downloaded, so request the Blob data and add to the map
                                if !blobExists
                                {
                                    AWSPrepRequest(requestToCall: AWSGetBlobData(blobID: addBlobContent.blobID, notifyUser: false), delegate: self.awsRequestDelegate!).prepRequest()
                                }
                                
                                // Save to Core Data
                                CoreDataFunctions().blobContentSave(blobContent: addBlobContent)
                            }
                        }
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                }
        })
    }
}

class AWSAddBlobView : AWSRequestObject
{
    var blobID: String!
    var userID: String!
    
    required init(blobID: String, userID: String)
    {
        self.blobID = blobID
        self.userID = userID
    }
    
    // Add a record that this Blob was viewed by the logged in user
    override func makeRequest()
    {
        // Save a Blob notification in Core Data (so that the user is not notified of the viewed Blob)
        // Because the Blob notification is not checked for already existing, multiple entries with the same blobID may exist
        CoreDataFunctions().blobNotificationSave(blobID: blobID)
        
        print("ADDING BLOB VIEW: \(blobID), \(userID), \(Date().timeIntervalSince1970)")
        var json = [String: Any]()
        json["blob_id"]     = self.blobID
        json["user_id"]     = self.userID
        json["timestamp"]   = String(Date().timeIntervalSince1970)
        json["action_type"] = "view"
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-AddBlobAction", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("ADD BLOB VIEW ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if (response != nil)
                {
                    print("AC-ABV: response: \(response)")
                }
        })
    }
}

class AWSGetThumbnailImage : AWSRequestObject
{
    var contentThumbnailID: String!
    
    required init(contentThumbnailID: String)
    {
        self.contentThumbnailID = contentThumbnailID
    }
    
    // Download Thumbnail Image
    override func makeRequest()
    {
        if let thumbnailID = contentThumbnailID
        {
            let downloadingFilePath = NSTemporaryDirectory() + thumbnailID // + Constants.Settings.frameImageFileType)
            let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
            let transferManager = AWSS3TransferManager.default()
            
            // Download the Frame
            let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
            downloadRequest.bucket = Constants.Strings.S3BucketThumbnails
            downloadRequest.key =  thumbnailID
            downloadRequest.downloadingFileURL = downloadingFileURL
            
            transferManager?.download(downloadRequest).continue(
                { (task) -> AnyObject! in
                    
                    if let error = task.error
                    {
                        if error._domain == AWSS3TransferManagerErrorDomain as String
                            && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused
                        {
                            print("GTFT: DOWNLOAD PAUSED")
                        }
                        else
                        {
                            print("GTFT: DOWNLOAD FAILED: [\(error)]")
                            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
                            
                            // Record the server request attempt
                            Constants.Data.serverTries += 1
                        }
                        
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                    else if let exception = task.exception
                    {
                        print("GTFT: DOWNLOAD FAILED: [\(exception)]")
                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: exception.debugDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                    else
                    {
                        DispatchQueue.main.async(execute:
                            { () -> Void in
                                // Assign the image to the Preview Image View
                                if FileManager().fileExists(atPath: downloadingFilePath)
                                {
                                    let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                                    
                                    // Ensure the Thumbnail Data is not null
                                    if let tData = thumbnailData
                                    {
                                        // Ensure the thumbnail does not already exist
                                        var thumbnailExists = false
                                        loopThumbnailCheck: for tObject in Constants.Data.thumbnailObjects
                                        {
                                            // Check to see if the thumbnail Object ID matches
                                            if tObject.thumbnailID == thumbnailID
                                            {
                                                thumbnailExists = true
                                                break loopThumbnailCheck
                                            }
                                        }
                                        // If the thumbnail does not exist, download it and append it to the global Thumbnail array
                                        if !thumbnailExists
                                        {
                                            // Create a Blob Thumbnail Object, assign the Thumbnail ID and newly downloaded Image
                                            let addThumbnailObject = ThumbnailObject()
                                            addThumbnailObject.thumbnailID = thumbnailID
                                            addThumbnailObject.thumbnail = UIImage(data: tData)
                                            
                                            // Add the thumbnail to the global Thumbnail array
                                            Constants.Data.thumbnailObjects.append(addThumbnailObject)
                                        }
                                        
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                }
                                else
                                {
                                    print("FRAME FILE NOT AVAILABLE")
                                    // Record the server request attempt
                                    Constants.Data.serverTries += 1
                                    
                                    // Notify the parent view that the AWS call completed with an error
                                    if let parentVC = self.awsRequestDelegate
                                    {
                                        parentVC.processAwsReturn(self, success: false)
                                    }
                                }
                        })
                    }
                    return nil
            })
        }
    }
}

class AWSGetMediaImage : AWSRequestObject
{
    var blobContent: BlobContent!
    var contentImage: UIImage?
    
    required init(blobContent: BlobContent)
    {
        self.blobContent = blobContent
    }
    
    // Download Blob Image
    override func makeRequest()
    {
        print("ATTEMPT TO DOWNLOAD IMAGE: \(self.blobContent.contentMediaID)")
        
        // Verify the type of Blob (image)
        if self.blobContent.contentType == Constants.ContentType.image
        {
            if let contentMediaID = self.blobContent.contentMediaID
            {
                let downloadingFilePath = NSTemporaryDirectory() + contentMediaID // + Constants.Settings.frameImageFileType)
                let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
                let transferManager = AWSS3TransferManager.default()
                
                // Download the Frame
                let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
                downloadRequest.bucket = Constants.Strings.S3BucketMedia
                downloadRequest.key =  contentMediaID
                downloadRequest.downloadingFileURL = downloadingFileURL
                
                transferManager?.download(downloadRequest).continue(
                    { (task) -> AnyObject! in
                        
                        if let error = task.error
                        {
                            if error._domain == AWSS3TransferManagerErrorDomain as String
                                && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused
                            {
                                print("3: Download paused.")
                                CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "IMAGE NOT DOWNLOADED")
                            }
                            else
                            {
                                print("3: Download failed: [\(error)]")
                                CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
                                
                                // Record the server request attempt
                                Constants.Data.serverTries += 1
                            }
                            
                            // Notify the parent view that the AWS call completed with an error
                            if let parentVC = self.awsRequestDelegate
                            {
                                parentVC.processAwsReturn(self, success: false)
                            }
                        }
                        else if let exception = task.exception
                        {
                            print("3: Download failed: [\(exception)]")
                            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: exception.debugDescription)
                            
                            // Record the server request attempt
                            Constants.Data.serverTries += 1
                            
                            // Notify the parent view that the AWS call completed with an error
                            if let parentVC = self.awsRequestDelegate
                            {
                                parentVC.processAwsReturn(self, success: false)
                            }
                        }
                        else
                        {
                            // Assign the image to the Preview Image View
                            if FileManager().fileExists(atPath: downloadingFilePath)
                            {
                                let imageData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                                
                                // Save the image to the local UIImage
                                self.contentImage = UIImage(data: imageData!)
                                
                                // Notify the parent view that the AWS call completed successfully
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: true)
                                }
                            }
                            else
                            {
                                print("FRAME FILE NOT AVAILABLE")
                                CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "IMAGE NOT DOWNLOADED")
                                
                                // Notify the parent view that the AWS call completed with an error
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: false)
                                }
                            }
                        }
                        return nil
                })
            }
        }
        else
        {
            print("VIDEOS ARE NOT CURRENTLY SUPPORTED")
        }
    }
}

class AWSAddUserConnectionAction : AWSRequestObject
{
    var userID: String!
    var connectionUserID: String!
    var actionType: String!
    
    required init(userID: String, connectionUserID: String, actionType: String)
    {
        self.userID = userID
        self.connectionUserID = connectionUserID
        self.actionType = actionType
    }
    
    // Add a record for an action between user connections
    override func makeRequest()
    {
        print("ADDING CONNECTION ACTION: \(self.userID), \(self.connectionUserID), \(self.actionType)")
        var json = [String: Any]()
        json["user_id"]             = self.userID
        json["connection_user_id"]  = self.connectionUserID
        json["action_type"]         = self.actionType
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-AddUserConnectionAction", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("ADD CONNECTION ACTION ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if (response != nil)
                {
                    print("AC-ACA: response: \(response)")
                }
        })
    }
}

class AWSRegisterForPushNotifications : AWSRequestObject
{
    var deviceToken: String!
    
    required init(deviceToken: String)
    {
        self.deviceToken = deviceToken
    }
    
    // Add a record for an action between user connections
    override func makeRequest()
    {
        print("AC-RPN - REGISTERING FOR PUSH NOTIFICATIONS FOR DEVICE: \(self.deviceToken)")
        
        // Ensure that the Current UserID is not nil
        if let currentUserID = Constants.Data.currentUser.userID
        {
            var json = [String: Any]()
            json["device_token"] = self.deviceToken
            json["user_id"] = currentUserID
            
            let lambdaInvokerInvocationRequest = AWSLambdaInvokerInvocationRequest()
            lambdaInvokerInvocationRequest!.functionName = "Blobjot-RegisterForPushNotifications"
            lambdaInvokerInvocationRequest!.payload = json
            
            let lambdaInvoker = AWSLambdaInvoker.default()
            lambdaInvoker.invoke(lambdaInvokerInvocationRequest!).continue(
                { (task) -> AnyObject! in
                    
                    if let error = task.error
                    {
                        print("AC-RPN - ERROR: \(error)")
                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                    else if let exception = task.exception
                    {
                        print("AC-RPN: exception: \(exception)")
                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: exception.debugDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                    else if task.result != nil
                    {
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                    
                    return nil
                })
        }
        else
        {
            // No need to recall Registration - will be recalled once a user is logged in
            print("***** AC-RPN: ERROR NO CURRENT USER *****")
        }
    }
}

class AWSAddCommentForBlob : AWSRequestObject
{
    var blobID: String!
    var comment: String!
    
    required init(blobID: String, comment: String)
    {
        self.blobID = blobID
        self.comment = comment
    }
    
    // Add a record for an action between user connections
    override func makeRequest()
    {
        print("AC-ACFB - ADDING COMMENT FOR BLOB: \(self.blobID)")
        var json = [String: Any]()
        json["blob_id"]   = self.blobID
        json["user_id"]   = Constants.Data.currentUser.userID!
        json["timestamp"] = String(Date().timeIntervalSince1970)
        json["comment"]   = self.comment
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-AddComment", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-ACFB - ADD COMMENT ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if (response != nil)
                {
                    print("AC-ACFB - response: \(response)")
                }
        })
    }
}

class AWSGetBlobContentForBlob : AWSRequestObject
{
    var blobID: String!
    var blobContentArray = [BlobContent]()
    
    required init(blobID: String)
    {
        self.blobID = blobID
    }
    
    // The initial request for User's Blob data - called when the View Controller is instantiated
    override func makeRequest()
    {
        print("AC-GBC - REQUESTING BLOB COMMENTS FOR BLOB: \(self.blobID)")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["blob_id" : self.blobID]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetBlobContent", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GBC - GET BLOB CONTENT ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC - GBC: CONTENT RESPONSE: \(response)")
                    // Convert the response to an array of AnyObjects
                    if let rawBlobContent = response as? [AnyObject]
                    {
                        for rawBlobContentObject in rawBlobContent
                        {
                            if let newBlobContent = rawBlobContentObject as? [String: AnyObject]
                            {
                                let addBlobContent = BlobContent()
                                addBlobContent.blobContentID = newBlobContent["blobContentID"] as! String
                                addBlobContent.blobID = newBlobContent["blobID"] as! String
                                addBlobContent.userID = newBlobContent["contentUserID"] as! String
                                addBlobContent.contentDatetime = Date(timeIntervalSince1970: newBlobContent["timestamp"] as! Double)
                                addBlobContent.contentType = Constants.ContentType(rawValue: newBlobContent["contentType"] as! Int)
                                addBlobContent.response = Bool(newBlobContent["response"] as! NSNumber)
                                
                                addBlobContent.respondingToContentID = newBlobContent["respondingToContentID"] as? String
                                addBlobContent.contentMediaID = newBlobContent["contentMediaID"] as? String
                                addBlobContent.contentThumbnailID = newBlobContent["contentThumbnailID"] as? String
                                addBlobContent.contentText = newBlobContent["contentText"] as? String
                                
                                // Find the Blob in the global Map Blobs array and add the extra data to the Blob
                                var blobContentExists = false
                                loopBlobContentCheck: for bContent in Constants.Data.blobContent
                                {
                                    if bContent.blobContentID == addBlobContent.blobContentID
                                    {
                                        blobContentExists = true
                                        
                                        bContent.blobID = addBlobContent.blobID
                                        bContent.userID = addBlobContent.userID
                                        bContent.contentDatetime = addBlobContent.contentDatetime
                                        bContent.contentType = addBlobContent.contentType
                                        bContent.response = addBlobContent.response
                                        
                                        bContent.respondingToContentID = addBlobContent.respondingToContentID
                                        bContent.contentMediaID = addBlobContent.contentMediaID
                                        bContent.contentThumbnailID = addBlobContent.contentThumbnailID
                                        bContent.contentText = addBlobContent.contentText
                                        
                                        break loopBlobContentCheck
                                    }
                                }
                                // If the blobContent does not exist, append it to the global array
                                if !blobContentExists
                                {
                                    Constants.Data.blobContent.append(addBlobContent)
                                }
                            }
                        }
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                }
        })
    }
}

class AWSCheckUsername : AWSRequestObject
{
    var userName: String!
    var usernameCheckTimestamp: TimeInterval!
    var response: String?
    
    required init(userName: String, usernameCheckTimestamp: TimeInterval)
    {
        self.userName = userName
        self.usernameCheckTimestamp = usernameCheckTimestamp
    }
    
    // The initial request for User's Blob data - called when the View Controller is instantiated
    override func makeRequest()
    {
        print("AC-CU - USERNAME: \(self.userName)")
        
        // Create some JSON to send the logged in userID
        var json = [String: Any]()
        json["user_name"] = self.userName
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-CheckUsername", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-CU - UNABLE TO CHECK USERNAME: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    self.response = response as? String
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}

class AWSAddPoints : AWSRequestObject
{
    var function: String!
    var points: Float!
    
    required init(function: String, points: Float)
    {
        self.function = function
        self.points = points
    }
    
    // Add a record that this Blob was viewed by the logged in user
    override func makeRequest()
    {
        print("AC-AP: ADDING USER POINTS: \(self.points)")
        var json = [String: Any]()
        json["user_id"]   = Constants.Data.currentUser
        json["function"]  = self.function
        json["points"]    = self.points
        json["timestamp"] = Date().timeIntervalSince1970
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-AddUserPoints", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("ADD USER POINTS ERROR: \(err)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-AP: response: \(response)")
                    
// *COMPLETE***** IF FAILED, SEND POINTS TO CORE DATA, UPLOAD WHEN ABLE
                }
        })
    }
}

class AWSLog : AWSRequestObject
{
    var logType: Constants.LogType!
    var logArray = [[String]]()
    
    required init(logType: Constants.LogType, logArray: [[String]])
    {
        self.logType = logType
        self.logArray = logArray
    }
    
    // The initial request for User's Blob data - called when the View Controller is instantiated
    override func makeRequest()
    {
        print("AC-LOGE - LOGGING: \(self.logType)")
        
        // Create some JSON to send the logged in userID
        var json = [String: Any]()
        json["log_type"]     = self.logType.rawValue
        json["log_array"]    = self.logArray
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-ADMIN-Logs", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-LOGE - UNABLE TO SUBMIT LOG: \(err)")
                }
                else if (response != nil)
                {
                    print("AC-LOGE - SUBMITTED LOG: \(response)")
                }
        })
    }
}

class FBGetUserProfileData : AWSRequestObject
{
    var user: User!
    var downloadImage: Bool = false
    
    required init(user: User, downloadImage: Bool)
    {
        self.user = user
        self.downloadImage = downloadImage
    }
    
    // FBSDK METHOD - Get user data from FB before attempting to log in via AWS
    override func makeRequest()
    {
        print("AC-FBSDK - TRYING TO MAKE GRAPH REQUEST WITH USER: \(self.user.userID), USERNAME: \(self.user.userName), FB ID: \(self.user.facebookID), USER STATUS: \(self.user.userStatus)")
        if let facebookID = self.user.facebookID
        {
            let fbRequest = FBSDKGraphRequest(graphPath: facebookID, parameters: ["fields": "id, email, name, picture"]) //parameters: ["fields": "id,email,name,picture"])
            fbRequest?.start
                {(connection: FBSDKGraphRequestConnection?, result: Any?, error: Error?) in
                    
                    if error != nil
                    {
                        print("AC-FBSDK - Error Getting Info \(error)")
                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error!.localizedDescription)
                        
                        // Notify the parent view that the AWS call failed
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                    }
                    else
                    {
                        if let resultDict = result as? [String:AnyObject]
                        {
                            print("AC-FBSDK - RESULT : \(result)")
                            if let facebookName = resultDict["name"] as! String!
                            {
                                print("AC-FBSDK - Name : \(facebookName)")
                                // Update the local username
                                self.user.userName = facebookName
                                
                                // Download the large user image from FB if indicated
                                if self.downloadImage
                                {
                                    let facebookImagUrlString = "https://graph.facebook.com/" + self.user.facebookID + "/picture?type=large"
                                    let imgURL = URL(string: facebookImagUrlString)
                                    
                                    let task = URLSession.shared.dataTask(with: imgURL!)
                                    { (responseData, responseUrl, error) -> Void in
                                        
                                        if let data = responseData
                                        {
                                            // execute in UI thread
                                            DispatchQueue.main.async(execute:
                                                {
                                                    print("AC-FBSDK - Response Data (IMAGE) : \(data)")
                                                    
                                                    // Update the local user image
                                                    self.user.userImage = UIImage(data: data)
                                                    
                                                    // Notify the parent view that the request completed successfully
                                                    if let parentVC = self.awsRequestDelegate
                                                    {
                                                        parentVC.processAwsReturn(self, success: true)
                                                    }
                                                    
                                                    // Update the global user and save to Core Data
                                                    self.updateUserGlobally(user: self.user)
                                            })
                                        }
                                        else
                                        {
                                            DispatchQueue.main.async(execute:
                                                {
                                                    print("AC-FBSDK - Response Error (IMAGE): \(error)")
                                                    
                                                    // Notify the parent view that the request failed partially
                                                    if let parentVC = self.awsRequestDelegate
                                                    {
                                                        parentVC.processAwsReturn(self, success: false)
                                                    }
                                                    
                                                    // Update the global user and save to Core Data
                                                    self.updateUserGlobally(user: self.user)
                                            })
                                        }
                                    }
                                    
                                    // Run task
                                    task.resume()
                                }
                                // Update the global user and save to Core Data
                                self.updateUserGlobally(user: self.user)
                            }
                        }
                        
                    }
            }
        }
        else
        {
            // Indicate a failure so that the default userName and userImage is displayed
            // Notify the parent view that the request never happened
            if let parentVC = self.awsRequestDelegate
            {
                parentVC.processAwsReturn(self, success: false)
            }
            
            if let userID = self.user.userID
            {
                // Go ahead and request the user data from AWS again since not all data was originally downloaded
                AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: userID, forPreviewData: false), delegate: self.awsRequestDelegate!).prepRequest()
            }
        }
    }
    
    // Update the user in the global userList with the new data
    func updateUserGlobally(user: User)
    {
        if let userID = user.userID, let currentUserID = Constants.Data.currentUser.userID
        {
            // Update the Current User object, if needed
            if userID == currentUserID
            {
                Constants.Data.currentUser.userName = user.userName
                Constants.Data.currentUser.userImage = user.userImage
                
                // Save to Core Data
                CoreDataFunctions().currentUserSave(user: Constants.Data.currentUser)
            }
            
            loopUserObjectCheck: for userObject in Constants.Data.userObjects
            {
                if userObject.userID == userID
                {
                    userObject.userName = user.userName
                    userObject.userImage = user.userImage
                    
                    // Save to Core Data
                    CoreDataFunctions().userSave(user: userObject)
                    
                    break loopUserObjectCheck
                }
            }
        }
    }
}

class FBGetUserLikes : AWSRequestObject
{
    // FBSDK METHOD - Get user data from FB before attempting to log in via AWS
    override func makeRequest()
    {
        print("AC-FBSDK - GUD - TRYING TO MAKE GRAPH REQUEST (LIKES)")
        let fbRequest = FBSDKGraphRequest(graphPath: "me/likes", parameters: ["fields": "likes"])
        fbRequest?.start
            {(connection: FBSDKGraphRequestConnection?, result: Any?, error: Error?) in
                
                if error != nil
                {
                    print("AC-FBSDK - GUD - Error Getting Info \(error)")
                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error!.localizedDescription)
                    
                    // Notify the parent view that the AWS call failed
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                }
                else
                {
                    // Reset the userLikes list
                    Constants.Data.currentUserInterests = [String]()
                    
                    print("AC-FBSDK - GUD - LIKES: \(result)")
                    
                    if let resultDict = result as? [String: Any]
                    {
                        if let likesData = resultDict["data"] as? [Any]
                        {
                            for likesDataObject in likesData
                            {
                                if let likeGroup = likesDataObject as? [String: Any]
                                {
                                    if let likeGroupList = likeGroup["likes"] as? [String: Any]
                                    {
                                        if let likes = likeGroupList["data"] as? [Any]
                                        {
                                            for likeObject in likes
                                            {
                                                if let likeObjectParsed = likeObject as? [String: Any]
                                                {
                                                    if let like = likeObjectParsed["name"] as? String
                                                    {
                                                        print("AC-FBSDK - GUD - like : \(like)")
                                                        Constants.Data.currentUserInterests.append(like)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Save all downloaded data to Core Data
                    CoreDataFunctions().interestsSave()
                }
        }
    }
}
