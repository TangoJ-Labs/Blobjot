//
//  AWSClasses.swift
//  Blobjot
//
//  Created by Sean Hart on 9/20/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

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
        print("AC - IN PREP REQUEST: \(requestToCall)")
        print("AC - FBSDK TOKEN: \(FBSDKAccessToken.current())")
        
        // Check to see if the facebook user id is already in the FBSDK
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Assign the Facebook Token to the AWSRequestObject
            self.requestToCall.facebookToken = facebookToken
            
            print("AC - COGNITO ID: \(Constants.credentialsProvider.identityId)")
            // Ensure that the Cognito ID is still valid and is not older than an hour (AWS will invalidate if older)
            if Constants.credentialsProvider.identityId != nil && Constants.Data.lastCredentials - NSDate().timeIntervalSinceNow < 3600
            {
                print("AC - ALREADY HAVE COGNITO ID - GETTING NEW AWS ID")
                // The Cognito ID is valid, so check for a Blobjot ID and then make the request
                self.getBlobjotID(facebookToken: facebookToken)
            }
            else
            {
                print("AC - CALLING COGNITO ID")
                // If the Cognito credentials have expired, request the credentials again (Cognito Identity ID) and use the current Facebook info
                self.getCognitoID()
            }
        }
        else
        {
            print("***** USER NEEDS TO LOG IN AGAIN *****")
            
            if let parentVC = self.awsRequestDelegate
            {
                print("AC - PARENT VC IS: \(parentVC)")
                
                // Check to see if the parent viewcontroller is already the MapViewController.  If so, call the MVC showLoginScreen function
                // Otherwise, launch a new MapViewController and show the login screen
                if parentVC is MapViewController
                {
                    print("AC - PARENT VC IS EQUAL TO MVC")
                    parentVC.showLoginScreen()
                }
                else
                {
                    print("AC - PARENT VC IS NOT EQUAL TO MVC")
                    let newMapViewController = MapViewController()
                    if let rootNavController = UIApplication.shared.windows[0].rootViewController?.navigationController
                    {
                        rootNavController.pushViewController(newMapViewController, animated: true)
                    }
                }
            }
        }
    }
    
    // Once the Facebook token is gained, request a Cognito Identity ID
    func getCognitoID()
    {
        print("AC - IN GET COGNITO ID: \(requestToCall.facebookToken)")
        if let token = requestToCall.facebookToken
        {
            print("AC - GETTING COGNITO ID")
            print("AC - GETTING COGNITO ID: \(Constants.credentialsProvider.identityId)")
            // Authenticate the user in AWS Cognito
            Constants.credentialsProvider.logins = [AWSIdentityProviderFacebook: token.tokenString]
            
//            let customProviderManager = CustomIdentityProvider(tokens: [AWSIdentityProviderFacebook as NSString: token.tokenString as NSString])
////            let identityProviderManager = AWSIdentityProviderManager()
////            identityProviderManager.logins = [AWSIdentityProviderFacebook: token.tokenString]
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
                        
                        // Record the login attempt
                        Constants.Data.loginTries += 1
                        
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
        if Constants.Data.currentUser != ""
        {
            print("AC - FIRING REQUEST")
            // All login info is current; go ahead and fire the needed method
            self.requestToCall.facebookToken = facebookToken
            self.requestToCall.makeRequest()
        }
        else
        {
            // The current ID is nil, so request it from AWS, but store the previous request and call it when the
            // login is complete
            print("AC - NO CURRENT USER - SECONDARY REQUEST: \(self.requestToCall) WITH FB TOKEN: \(facebookToken)")
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
        if Constants.Data.loginTries <= Constants.Settings.maxLoginTries
        {
            print("FBSDK - MAKING GRAPH REQUEST")
            print("AC - FBSDK - COGNITO ID: \(Constants.credentialsProvider.identityId)")
            let fbRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, picture"]) //parameters: ["fields": "id,email,name,picture"])
            print("FBSDK - MAKING GRAPH CALL")
            fbRequest?.start
                {(connection: FBSDKGraphRequestConnection?, result: Any?, error: Error?) in
                    
                    print("FBSDK - CONNECTION: \(connection)")
                    
                    if error != nil
                    {
                        print("FBSDK - Error Getting Info \(error)")
                        
                        // Record the attempt
                        Constants.Data.loginTries += 1
                        
                        // Try again
                        self.makeRequest()
                    }
                    else
                    {
                        print("FBSDK - RESULT: \(result)")
                        
                        if let resultDict = result as? [String:AnyObject]
                        {
                            print("FBSDK - User Info : \(resultDict)")
                            print("FBSDK - USER NAME : \(resultDict["name"])")
                            
                            if let resultPicture = resultDict["picture"] as? [String:AnyObject]
                            {
                                if let resultPictureData = resultPicture["data"] as? [String:AnyObject]
                                {
                                    print("FBSDK - IMAGE URL : \(resultPictureData["url"])")
                                }
                            }
                            
                            if let facebookName = resultDict["name"]
                            {
                                print("FBSDK - FACEBOOK NAME: \(facebookName)")
                                
                                var facebookImageUrl = "none"
                                if let resultPicture = resultDict["picture"] as? [String:AnyObject]
                                {
                                    if let resultPictureData = resultPicture["data"] as? [String:AnyObject]
                                    {
                                        print("FBSDK - IMAGE URL : \(resultPictureData["url"])")
                                        facebookImageUrl = resultPictureData["url"]! as! String
                                    }
                                }
                                print("FBSDK - FACEBOOK URL: \(facebookImageUrl)")
                                
                                self.loginUser((facebookName as! String), facebookThumbnailUrl: facebookImageUrl)
                            }
                        }
                        
                    }
            }
        }
        else
        {
            // Notify the parent view that the AWS call completed with an error
            if let parentVC = self.awsRequestDelegate
            {
                parentVC.processAwsReturn(self, success: false)
            }
        }
    }
    
    // Log in the user or create a new user
    func loginUser(_ facebookName: String, facebookThumbnailUrl: String)
    {
        print("AC - LU - FACEBOOK TOKEN: \(self.facebookToken)")
        print("AC - LU - COGNITO ID: \(Constants.credentialsProvider.identityId)")
        let json: NSDictionary = ["facebook_id" : self.facebookToken!.userID, "facebook_name": facebookName, "facebook_thumbnail_url": facebookThumbnailUrl]
        print("AC - USER LOGIN DATA: \(json)")
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-LoginUser", jsonObject: json, completionHandler:
            { (responseData, err) -> Void in
                
                if (err != nil)
                {
                    print("AC - FBSDK LOGIN - ERROR: \(err)")
                    
                    // Record the login attempt
                    Constants.Data.loginTries += 1
                    
                    DispatchQueue.main.async(execute:
                        {
                            // Notify the parent view that the AWS call completed with an error
                            if let parentVC = self.awsRequestDelegate
                            {
                                parentVC.processAwsReturn(self, success: false)
                                
                                // Try again
                                AWSPrepRequest(requestToCall: self, delegate: parentVC).prepRequest()
                            }
                    })
                    
                }
                else if (responseData != nil)
                {
                    print("AC - FBSDK - LOGIN - USER RESPONSE: \(responseData)")
                    
                    // The response will be the userID associated with the facebookID used, save the userID globally
                    Constants.Data.currentUser = responseData as! String
                    
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
        print("REQUESTING GMD")
        print("AC - GMD - COGNITO ID: \(Constants.credentialsProvider.identityId)")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetMapData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("GET MAP DATA ERROR: \(err)")
                    print("GET MAP DATA ERROR CODE: \(err!._code)")
                    
                    // Process the error codes and alert the user if needed
                    if err!._code == 1 && Constants.Data.currentUser != ""
                    {
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
                    if let newMapBlobs = response as? [AnyObject]
                    {
                        print("MVC-GMD: jsonData: \(newMapBlobs)")
                        print("BLOB COUNT: \(newMapBlobs.count)")
                        
                        // Always clear the mapCircles before clearing the mapBlobs data otherwise the circles will be unresponsive
                        // Each circle must individually have their map nullified, otherwise the mapView will still display the circle
                        for circle in Constants.Data.mapCircles
                        {
                            circle.map = nil
                        }
                        Constants.Data.mapCircles = [GMSCircle]()
                        
                        // Clear global mapBlobs
                        Constants.Data.mapBlobs = [Blob]()
                        
                        // Loop through each AnyObject (Blob) in the array
                        for newBlob in newMapBlobs
                        {
                            print("NEW BLOB: \(newBlob)")
                            
                            // Convert the AnyObject to JSON with keys and AnyObject values
                            // Then convert the AnyObject values to Strings or Numbers depending on their key
                            if let checkBlob = newBlob as? [String: AnyObject]
                            {
                                let blobTimestamp = checkBlob["blobTimestamp"] as! Double
                                let blobDatetime = Date(timeIntervalSince1970: blobTimestamp)
                                let blobTypeInt = checkBlob["blobType"] as! Int
                                
                                // Evaluate the blobType Integer received and convert it to the appropriate BlobType Class
                                var blobType: Constants.BlobTypes!
                                switch blobTypeInt
                                {
                                case 1:
                                    blobType = Constants.BlobTypes.temporary
                                case 2:
                                    blobType = Constants.BlobTypes.permanent
                                case 3:
                                    blobType = Constants.BlobTypes.public
                                case 4:
                                    blobType = Constants.BlobTypes.invisible
                                case 5:
                                    blobType = Constants.BlobTypes.sponsoredTemporary
                                case 6:
                                    blobType = Constants.BlobTypes.sponsoredPermanent
                                default:
                                    blobType = Constants.BlobTypes.temporary
                                }
                                
                                // Finish converting the JSON AnyObjects and assign the data to a new Blob Object
                                print("ASSIGNING DATA")
                                let addBlob = Blob()
                                addBlob.blobID = checkBlob["blobID"] as! String
                                addBlob.blobDatetime = blobDatetime
                                addBlob.blobLat = checkBlob["blobLat"] as! Double
                                addBlob.blobLong = checkBlob["blobLong"] as! Double
                                addBlob.blobRadius = checkBlob["blobRadius"] as! Double
                                addBlob.blobType = blobType
                                addBlob.blobUserID = checkBlob["blobUserID"] as! String
                                
                                // Append the new Blob Object to the global Map Blobs Array
                                Constants.Data.mapBlobs.append(addBlob)
                                print("APPENDED BLOB: \(addBlob.blobID)")
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

class AWSGetBlobData : AWSRequestObject
{
    var blob: Blob!
    
    required init(blob: Blob)
    {
        self.blob = blob
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    override func makeRequest()
    {
        print("REQUESTING GBD FOR BLOB: \(self.blob.blobID)")
        
        // Create a JSON object with the passed Blob ID
        let json: NSDictionary = ["blob_id" : self.blob.blobID]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetBlobData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("GET BLOB DATA ERROR: \(err)")
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AWSM-GBD: response: \(response)")
                    
                    // Convert the response to JSON with keys and AnyObject values
                    // Then convert the AnyObject values to Strings or Numbers depending on their key
                    // Start with converting the Blob ID to a String
                    if let checkBlob = response as? [String: AnyObject]
                    {
                        let extraBlobID = checkBlob["blobID"] as! String
                        
                        // Find the Blob in the global Map Blobs array and add the extra data to the Blob
                        loopMapBlobCheck: for mBlob in Constants.Data.mapBlobs
                        {
                            if mBlob.blobID == extraBlobID
                            {
                                print("ASSIGNING EXTRA MAP BLOB DATA")
                                mBlob.blobMediaType = checkBlob["blobMediaType"] as? Int
                                mBlob.blobMediaID = checkBlob["blobMediaID"] as? String
                                mBlob.blobThumbnailID = checkBlob["blobThumbnailID"] as? String
                                mBlob.blobText = checkBlob["blobText"] as? String
                                print("ASSIGNED EXTRA MAP BLOB DATA")
                                
                                // ...and request the Thumbnail image data if the Thumbnail ID is not null
                                if let thumbnailID = mBlob.blobThumbnailID
                                {
                                    print("ABOUT TO CALL GET THUMBNAIL FOR: \(thumbnailID)")
                                    
                                    // Ensure the thumbnail does not already exist
                                    var thumbnailExists = false
                                    loopThumbnailCheck: for tObject in Constants.Data.blobThumbnailObjects
                                    {
                                        print("GET THUMBNAIL - CHECK 2")
                                        
                                        // Check to see if the thumbnail Object ID matches
                                        if tObject.blobThumbnailID == thumbnailID
                                        {
                                            print("GET THUMBNAIL - CHECK 3")
                                            thumbnailExists = true
                                            
                                            break loopThumbnailCheck
                                        }
                                    }
                                    // If the thumbnail does not exist, download it and append it to the global Thumbnail array
                                    if !thumbnailExists
                                    {
                                        let awsGetThumbnail = AWSGetThumbnailImage(blob: mBlob)
                                        awsGetThumbnail.awsRequestDelegate = self.awsRequestDelegate
                                        awsGetThumbnail.makeRequest()
                                    }
                                }
                                
                                // Check the global Location Blobs array for the Blob and assign the extra data if the Blob exists
                                var blobExistsInLocationBlobs = false
                                loopLocationBlobCheck: for lBlob in Constants.Data.locationBlobs
                                {
                                    if lBlob.blobID == extraBlobID
                                    {
                                        blobExistsInLocationBlobs = true
                                        
                                        print("ASSIGNING EXTRA LOC BLOB DATA")
                                        lBlob.blobMediaType = checkBlob["blobMediaType"] as? Int
                                        lBlob.blobMediaID = checkBlob["blobMediaID"] as? String
                                        lBlob.blobThumbnailID = checkBlob["blobThumbnailID"] as? String
                                        lBlob.blobText = checkBlob["blobText"] as? String
                                        print("ASSIGNED EXTRA LOC BLOB DATA")
                                        
                                        break loopLocationBlobCheck
                                    }
                                }
                                
                                // If the Blob does not exist, append it to the Location Blobs array
                                if !blobExistsInLocationBlobs
                                {
                                    Constants.Data.locationBlobs.append(mBlob)
                                    print("APPENDED BLOB AFTER DOWNLOAD: \(mBlob.blobText)")
                                }
                                
//                            // Notify the parent view that the AWS call completed successfully
//                            if let parentVC = self.AWSMethodsMapVcDelegate {
//                                parentVC.processAwsReturn(Constants.AWSMethodTypes.getBlobData, success: true)
//                            }
                                
                                // Notify the parent view that the AWS call completed successfully
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: true)
                                }
                                
                                break loopMapBlobCheck
                            }
                        }
                    }
                }
        })
    }
}

class AWSGetThumbnailImage : AWSRequestObject
{
    var blob: Blob!
    
    required init(blob: Blob)
    {
        self.blob = blob
    }
    
    // Download Thumbnail Image
    override func makeRequest()
    {
        if let thumbnailID = blob.blobThumbnailID
        {
            print("GETTING THUMBNAIL FOR: \(thumbnailID)")
            
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
                        
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                    else
                    {
                        print("GTFT: DOWNLOAD SUCCEEDED")
                        DispatchQueue.main.async(execute:
                            { () -> Void in
                                // Assign the image to the Preview Image View
                                if FileManager().fileExists(atPath: downloadingFilePath)
                                {
                                    print("THUMBNAIL FILE AVAILABLE")
                                    let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                                    
                                    // Ensure the Thumbnail Data is not null
                                    if let tData = thumbnailData
                                    {
                                        print("GET THUMBNAIL - CHECK 1")
                                        
                                        // Create a Blob Thumbnail Object, assign the Thumbnail ID and newly downloaded Image
                                        let addThumbnailObject = BlobThumbnailObject()
                                        addThumbnailObject.blobThumbnailID = thumbnailID
                                        addThumbnailObject.blobThumbnail = UIImage(data: tData)
                                        Constants.Data.blobThumbnailObjects.append(addThumbnailObject)
                                        
                                        // Add the image to the blob for access by the return function
                                        self.blob.blobThumbnail = UIImage(data: tData)
                                        
                                        print("ADDED THUMBNAIL FOR IMAGE: \(thumbnailID))")
                                        
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

class AWSGetSingleUserData : AWSRequestObject
{
    var user: User!
    var userID: String!
    var forPreviewBox: Bool!
    
    required init(userID: String, forPreviewBox: Bool)
    {
        self.userID = userID
        self.forPreviewBox = forPreviewBox
        
        self.user = User()
        self.user.userID = userID
    }
    
    // The initial request for User data
    override func makeRequest()
    {
        print("MVC: REQUESTING GSUD")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : self.user.userID]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetSingleUserData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("MVC: GET USER CONNECTIONS DATA ERROR: \(err)")
                    
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
                        let userID = userJson["user_id"] as! String
                        let userName = userJson["user_name"] as! String
                        let userImageKey = userJson["user_image_key"] as! String
                        print("MVC: USER ID: \(userID)")
                        print("MVC: USER NAME: \(userName)")
                        print("MVC: USER IMAGE KEY: \(userImageKey)")
                        
                        // Create a User Object and add it to the global User array
                        self.user.userName = userName
                        self.user.userImageKey = userImageKey
                        
                        // Check to ensure the user does not already exist in the global User array
                        var userObjectExists = false
                        loopUserObjectCheck: for userObject in Constants.Data.userObjects
                        {
                            if userObject.userID == self.user.userID
                            {
                                // Update the user data with the latest data
                                userObject.userName = userName
                                userObject.userImageKey = userImageKey
                                
                                // If the userImage has not been downloaded, request a new download
                                if userObject.userImage == nil
                                {
                                    let awsGetUserImage = AWSGetUserImage(user: userObject)
                                    awsGetUserImage.awsRequestDelegate = self.awsRequestDelegate
                                    awsGetUserImage.makeRequest()
                                }
                                
                                userObjectExists = true
                                break loopUserObjectCheck
                            }
                        }
                        if userObjectExists == false
                        {
                            print("USER: \(userName) DOES NOT EXIST - ADDING")
                            Constants.Data.userObjects.append(self.user)
                            
                            // Download the user image and assign to the preview user image
                            let awsGetUserImage = AWSGetUserImage(user: self.user)
                            awsGetUserImage.awsRequestDelegate = self.awsRequestDelegate
                            awsGetUserImage.makeRequest()
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

class AWSGetUserImage : AWSRequestObject
{
    var user: User!
    
    required init(user: User)
    {
        self.user = user
    }
    
    // Download User Image
    override func makeRequest()
    {
        print("MVC: GETTING IMAGE FOR: \(self.user.userImageKey)")
        
        let downloadingFilePath = NSTemporaryDirectory() + self.user.userImageKey // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketUserImages
        downloadRequest.key =  self.user.userImageKey
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        let transferManager = AWSS3TransferManager.default()
        transferManager?.download(downloadRequest).continue(
            { (task) -> AnyObject! in
                
                if let error = task.error
                {
                    if error._domain == AWSS3TransferManagerErrorDomain as String
                        && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused
                    {
                        print("MVC: DOWNLOAD PAUSED")
                    }
                    else
                    {
                        print("MVC: DOWNLOAD FAILED: [\(error)]")
                    }
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if let exception = task.exception
                {
                    print("MVC: DOWNLOAD FAILED: [\(exception)]")
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else
                {
                    print("MVC: DOWNLOAD SUCCEEDED")
                    // Assign the image to the Preview Image View
                    if FileManager().fileExists(atPath: downloadingFilePath)
                    {
                        print("IMAGE FILE AVAILABLE")
                        let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData
                        {
                            print("GET IMAGE - CHECK 1")
                            
                            // Assign the image to the Object User Image
                            self.user.userImage = UIImage(data: tData)
                            
                            // Find the correct User Object in the global list and assign the newly downloaded Image
                            loopUserObjectCheck: for userObject in Constants.Data.userObjects
                            {
                                if userObject.userID == self.user.userID
                                {
                                    // Update the saved user object image for access elsewhere
                                    userObject.userImage = UIImage(data: tData)
                                    
                                    // Update the local user object image to send to the response method
                                    self.user.userImage = UIImage(data: tData)
                                    
                                    // Notify the parent view that the AWS call completed successfully
                                    if let parentVC = self.awsRequestDelegate
                                    {
                                        parentVC.processAwsReturn(self, success: true)
                                    }
                                    
                                    break loopUserObjectCheck
                                }
                            }
                        }
                    }
                    else
                    {
                        print("FRAME FILE NOT AVAILABLE")
                    }
                }
                return nil
        })
    }
}

class AWSEditUserName : AWSRequestObject
{
    var userID: String!
    var newUserName: String!
    
    required init(newUserName: String)
    {
        self.userID = Constants.Data.currentUser
        self.newUserName = newUserName
    }
    
    // Edit the logged in user's userName
    override func makeRequest()
    {
        let json: NSDictionary = ["user_id" : self.userID, "user_name": self.newUserName]
        print("EDITING USER NAME TO: \(json)")
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-EditUserName", jsonObject: json, completionHandler:
            {(responseData, err) -> Void in
                
                if (err != nil)
                {
                    print("Error: \(err)")
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (responseData != nil)
                {
                    print("EDIT USER NAME RESPONSE: \(responseData)")
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}

class AWSEditUserImage : AWSRequestObject
{
    var userID: String!
    var newUserImage: UIImage!
    
    required init(newUserImage: UIImage)
    {
        self.userID = Constants.Data.currentUser
        self.newUserImage = newUserImage
    }
    
    // Edit the userImage for the currently logged in user
    override func makeRequest()
    {
        // Get the User Data for the userID
        let json: NSDictionary = ["request" : "random_user_image_id"]
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-CreateRandomID", jsonObject: json, completionHandler:
            { (responseData, err) -> Void in
                
                if (err != nil)
                {
                    print("UUI: Error: \(err)")
                }
                else if (responseData != nil)
                {
                    let imageID = responseData! as! String
                    print("UUI: imageID: \(imageID)")
                    
                    let resizedImage = UtilityFunctions().resizeImage(self.newUserImage, targetSize: CGSize(width: 200, height: 200))
                    
                    if let data = UIImagePNGRepresentation(resizedImage)
                    {
                        print("UUI: INSIDE DATA")
                        
                        let filePath = NSTemporaryDirectory() + ("userImage" + imageID + ".png")
                        print("UUI: FILE PATH: \("file:///" + filePath)")
                        try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
                        
                        var uploadMetadata = [String : String]()
                        uploadMetadata["user_id"] = Constants.Data.currentUser
                        print("UUI: METADATA: \(uploadMetadata)")
                        
                        let uploadRequest = AWSS3TransferManagerUploadRequest()
                        uploadRequest?.bucket = Constants.Strings.S3BucketUserImages
                        uploadRequest?.metadata = uploadMetadata
                        uploadRequest?.key =  imageID
                        uploadRequest?.body = URL(string: "file:///" + filePath)
                        print("UUI: UPLOAD REQUEST: \(uploadRequest)")
                        
                        let transferManager = AWSS3TransferManager.default()
                        transferManager?.upload(uploadRequest).continue(
                            { (task) -> AnyObject! in
                                
                                if let error = task.error
                                {
                                    if error._domain == AWSS3TransferManagerErrorDomain as String
                                        && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused {
                                        print("Upload paused.")
                                    }
                                    else
                                    {
                                        print("Upload failed: [\(error)]")
                                        // Delete the user image from temporary memory
                                        do
                                        {
                                            print("Deleting image: \(imageID)")
                                            try FileManager.default.removeItem(atPath: filePath)
                                        }
                                        catch let error as NSError
                                        {
                                            print("Ooops! Something went wrong: \(error)")
                                        }
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
                                    // Delete the user image from temporary memory
                                    do
                                    {
                                        print("Deleting image: \(imageID)")
                                        try FileManager.default.removeItem(atPath: filePath)
                                    }
                                    catch let error as NSError
                                    {
                                        print("Ooops! Something went wrong: \(error)")
                                    }
                                    
                                    // Notify the parent view that the AWS call completed with an error
                                    if let parentVC = self.awsRequestDelegate
                                    {
                                        parentVC.processAwsReturn(self, success: false)
                                    }
                                    
                                }
                                else
                                {
                                    print("Upload succeeded")
                                    // Delete the user image from temporary memory
                                    do
                                    {
                                        print("Deleting image: \(imageID)")
                                        try FileManager.default.removeItem(atPath: filePath)
                                    }
                                    catch let error as NSError
                                    {
                                        print("Ooops! Something went wrong: \(error)")
                                    }
                                    
                                    // Notify the parent view that the AWS call completed successfully
                                    if let parentVC = self.awsRequestDelegate
                                    {
                                        parentVC.processAwsReturn(self, success: true)
                                    }
                                }
                                return nil
                        })
                    }
                }
        })
    }
}

class AWSGetUserConnections : AWSRequestObject
{
    var userConnectionArrays = [[AnyObject]]()
    
    // The initial request for Map Blob data - called when the View Controller is instantiated
    override func makeRequest() {
        print("AC - REQUESTING GUC")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser, "print_check" : "BAP"]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetUserConnections", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC - GET USER CONNECTIONS DATA ERROR: \(err)")
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if (response != nil)
                {
                    // Convert the response to an array of arrays
                    if let newUserConnectionArrays = response as? [[AnyObject]]
                    {
                        self.userConnectionArrays = newUserConnectionArrays
                        
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
        print("REQUESTING RANDOM ID")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["request" : "random_media_id"]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-CreateRandomID", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("GET RANDOM ID ERROR: \(err)")
                    
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
                        print("RANDOM ID IS: \(newRandomID)")
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
                    }
                    else
                    {
                        print("Upload failed: [\(error)]")
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
                            print("Deleting media: \(self.uploadKey)")
                            try FileManager.default.removeItem(atPath: self.uploadMediaFilePath)
                        }
                        catch let error as NSError
                        {
                            print("ERROR DELETING FILE: \(error)")
                        }
                    }
                }
                return nil
        })
    }
}

class AWSUploadBlobData : AWSRequestObject
{
    var blobID: String!
    var blobLat: Double!
    var blobLong: Double!
    var blobMediaID: String!
    var blobMediaType: Int!
    var blobRadius: Double!
    var blobText: String!
    var blobThumbnailID: String!
    var blobTimestamp: Double!
    var blobType: Int!
    var blobTaggedUsers: [String]!
    var blobUserID: String!
    
    required init(blobID: String, blobLat: Double, blobLong: Double, blobMediaID: String, blobMediaType: Int, blobRadius: Double, blobText: String, blobThumbnailID: String, blobTimestamp: Double, blobType: Int, blobTaggedUsers: [String], blobUserID: String)
    {
        self.blobID = blobID
        self.blobLat = blobLat
        self.blobLong = blobLong
        self.blobMediaID = blobMediaID
        self.blobMediaType = blobMediaType
        self.blobRadius = blobRadius
        self.blobText = blobText
        self.blobThumbnailID = blobThumbnailID
        self.blobTimestamp = blobTimestamp
        self.blobType = blobType
        self.blobTaggedUsers = blobTaggedUsers
        self.blobUserID = blobUserID
    }
    
    // Upload data to Lambda for transfer to DynamoDB
    override func makeRequest()
    {
        print("SENDING DATA TO LAMBDA")
        
        // Create some JSON to send the Blob data
        var json = [String: Any]()
        json["blobID"]          = self.blobID
        json["blobLat"]         = String(self.blobLat)
        json["blobLong"]        = String(self.blobLong)
        json["blobMediaID"]     = self.blobMediaID
        json["blobMediaType"]   = String(self.blobMediaType)
        json["blobRadius"]      = String(self.blobRadius)
        json["blobText"]        = self.blobText
        json["blobThumbnailID"] = self.blobThumbnailID
        json["blobTimestamp"]   = String(self.blobTimestamp)
        json["blobType"]        = String(self.blobType)
        json["blobTaggedUsers"] = self.blobTaggedUsers
        json["blobUserID"]      = self.blobUserID
        
//            , "blobLat"         : String(self.blobLat)
//            , "blobLong"        : String(self.blobLong)
//            , "blobMediaID"     : self.blobMediaID
//            , "blobMediaType"   : String(self.blobMediaType)
//            , "blobRadius"      : String(self.blobRadius)
//            , "blobText"        : self.blobText
//            , "blobThumbnailID" : self.blobThumbnailID
//            , "blobTimestamp"   : String(self.blobTimestamp)
//            , "blobType"        : String(self.blobType)
//            , "blobTaggedUsers" : self.blobTaggedUsers
//            , "blobUserID"      : self.blobUserID
//        ]
        print("LAMBDA JSON: \(json)")
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-CreateBlob", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("SENDING DATA TO LAMBDA ERROR: \(err)")
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("SENDING DATA TO LAMDA RESPONSE: \(response)")
                    
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
//        let json: NSDictionary = [
//            "blob_id"       : self.blobID
//            , "user_id"     : self.userID
//            , "timestamp"   : String(Date().timeIntervalSince1970)
//            , "action_type" : "hide"
//        ]
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
//        let json: NSDictionary = [
//            "blob_id"       : self.blobID
//            , "user_id"     : self.userID
//            , "timestamp"   : String(Date().timeIntervalSince1970)
//            , "action_type" : "delete"
//        ]
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

class AWSGetUserBlobs : AWSRequestObject
{
    var newUserBlobs: [AnyObject]?
    
    // The initial request for User's Blob data - called when the View Controller is instantiated
    override func makeRequest()
    {
        print("REQUESTING GUB")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetUserBlobs", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("GET USER BLOBS DATA ERROR: \(err)")
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    // Convert the response to an array of AnyObjects
                    if let rawUserBlobs = response as? [AnyObject] {
                        print("BUTV-GUB: jsonData: \(rawUserBlobs)")
                        print("BLOB COUNT: \(rawUserBlobs.count)")
                        
                        self.newUserBlobs = rawUserBlobs
                        
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
        
        print("ADDING BLOB VIEW: \(blobID), \(userID), \(Date().timeIntervalSince1970)")
//        let json: NSDictionary = [
//            "blob_id"       : blobID
//            , "user_id"     : userID
//            , "timestamp"   : String(Date().timeIntervalSince1970)
//            , "action_type" : "view"
//        ]
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

class AWSGetBlobImage : AWSRequestObject
{
    var blob: Blob!
    var blobImage: UIImage?
    
    required init(blob: Blob)
    {
        self.blob = blob
    }
    
    // Download Blob Image
    override func makeRequest()
    {
        print("ATTEMPT TO DOWNLOAD IMAGE: \(self.blob.blobMediaID)")
        print("BLOB MEDIA TYPE: \(self.blob.blobMediaType)")
        
        // Verify the type of Blob (image or video)
        if self.blob.blobMediaType == 1
        {
            if let blobMediaID = self.blob.blobMediaID
            {
                print("DOWNLOADING IMAGE: \(self.blob.blobMediaID)")
                
                let downloadingFilePath = NSTemporaryDirectory() + blobMediaID // + Constants.Settings.frameImageFileType)
                let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
                let transferManager = AWSS3TransferManager.default()
                
                // Download the Frame
                let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
                downloadRequest.bucket = Constants.Strings.S3BucketMedia
                downloadRequest.key =  blobMediaID
                downloadRequest.downloadingFileURL = downloadingFileURL
                
                transferManager?.download(downloadRequest).continue(
                    { (task) -> AnyObject! in
                        
                        if let error = task.error
                        {
                            if error._domain == AWSS3TransferManagerErrorDomain as String
                                && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused
                            {
                                print("3: Download paused.")
                            }
                            else
                            {
                                print("3: Download failed: [\(error)]")
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
                                print("THUMBNAIL FILE AVAILABLE")
                                let imageData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                                
                                // Save the image to the local UIImage
                                self.blobImage = UIImage(data: imageData!)
                                
                                // Notify the parent view that the AWS call completed successfully
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: true)
                                }
                                
                                print("ADDED THUMBNAIL FOR IMAGE: \(blobMediaID))")
                            }
                            else
                            {
                                print("FRAME FILE NOT AVAILABLE")
                                
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
//        let json: NSDictionary = [
//            "user_id"               : self.userID
//            , "connection_user_id"  : self.connectionUserID
//            , "action_type"         : self.actionType
//        ]
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