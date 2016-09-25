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

//struct AWSTypes
//{
//    /**
//     The possible methods used in an AWS request
//     
//     - loginUser: Send the facebook user info to AWS and request (or create) the Blobjot userID
//    */
//    enum AWSMethodTypes: Int
//    {
//        case loginUser = 0
//        , logoutUser
//        , getMapData
//        , getBlobData
//        , getThumbnailImageForThumbnail
//        , getSingleUserData
//        , getUserImage
//        , editUserName
//    }
//}

// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol AWSRequestDelegate
{
    // A general handler to indicate that an AWS Method finished
    func processAwsReturn(_ requestCalled: AWSRequestObject, success: Bool)
    
//    // When called, the parent View Controller (MapViewController) refreshes the collection view
//    func refreshCollectionView()
//    
//    // Update the MapView's Child BlobActionView's TableView
//    func updateBlobActionTable()
//    
//    // Update the MapView's Preview Blob Data
//    func updatePreviewBoxData(_ user: User)
//    func refreshPreviewUserData(_ user: User)
//    
//    // For the AppDelegate (background processes), show the notification for the downloaded Blob
//    func displayNotification(_ blob: Blob)
    
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
        print("AWSC - IN PREP REQUEST: \(requestToCall)")
        print("AWSC - FBSDK TOKEN: \(FBSDKAccessToken.current())")
        // Check to see if the facebook user id is already in the FBSDK
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Assign the Facebook Token to the AWSRequestObject
            self.requestToCall.facebookToken = facebookToken
            
            print("AWSC - COGNITO ID: \(Constants.credentialsProvider.identityId)")
            // Ensure that the Cognito ID is still valid
            if Constants.credentialsProvider.identityId != nil
            {
                print("AWSC - FIRING REQUEST")
                // If the Identity ID is still valid, go ahead and fire the needed method
//                self.gotCognitoId()
                self.requestToCall.makeRequest()
            }
            else
            {
                print("AWSC - CALLING COGNITO ID")
                // If the Cognito credentials have expired, request the credentials again (Cognito Identity ID) and use the current Facebook info
                self.getCognitoID()
            }
        }
        else
        {
            print("***** USER NEEDS TO LOG IN AGAIN *****")
            
            if let parentVC = self.awsRequestDelegate
            {
                print("PARENT VC IS: \(parentVC)")
                
                // Check to see if the parent viewcontroller is already the MapViewController.  If so, call the MVC showLoginScreen function
                // Otherwise, launch a new MapViewController and show the login screen
                if parentVC is MapViewController
                {
                    print("PARENT VC IS EQUAL TO MVC")
                    parentVC.showLoginScreen()
                }
                else
                {
                    print("PARENT VC IS NOT EQUAL TO MVC")
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
        print("AWSC - IN GET COGNITO ID: \(requestToCall.facebookToken)")
        if let token = requestToCall.facebookToken
        {
            print("AWSC - GETTING COGNITO ID")
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
                        print("AWS COGNITO GET IDENTITY ID - ERROR: " + task.error!.localizedDescription)
                    }
                    else
                    {
                        // the task result will contain the identity id
                        let cognitoId = task.result
                        print("AWS COGNITO GET IDENTITY ID - AWS COGNITO ID: \(cognitoId)")
                        print("AWS COGNITO GET IDENTITY ID - CHECK IDENTITY ID: \(Constants.credentialsProvider.identityId)")
                        
                        // Request extra facebook data for the user ON THE MAIN THREAD
                        DispatchQueue.main.async(execute:
                            {
//                                self.gotCognitoId()
                                self.requestToCall.facebookToken = token
                                self.requestToCall.makeRequest()
                        });
                    }
                    return nil
            })
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
    
//    init(facebookToken: FBSDKAccessToken) {
//        self.facebookToken = facebookToken
//    }
    
    func makeRequest() {}
}


/**
 Properties:
 - facebookID Input- The received facebookID from the FBSDK request
 */
class AWSLoginUser : AWSRequestObject
{
    // FBSDK METHOD - Get user data from FB before attempting to log in via AWS
    override func makeRequest()
    {
        print("FBSDK - MAKING GRAPH REQUEST")
        let fbRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, picture"]) //parameters: ["fields": "id,email,name,picture"])
        print("FBSDK - MAKING GRAPH CALL")
        fbRequest?.start
            {(connection: FBSDKGraphRequestConnection?, result: Any?, error: Error?) in
                
                print("FBSDK - CONNECTION: \(connection)")
                
                if error != nil
                {
                    print("FBSDK - Error Getting Info \(error)")
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
    
    // Log in the user or create a new user
    func loginUser(_ facebookName: String, facebookThumbnailUrl: String)
    {
        let json: NSDictionary = ["facebook_id" : self.facebookToken!.userID, "facebook_name": facebookName, "facebook_thumbnail_url": facebookThumbnailUrl]
        print("USER LOGIN DATA: \(json)")
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-LoginUser", jsonObject: json, completionHandler:
            { (responseData, err) -> Void in
                
                if (err != nil)
                {
                    print("LOGIN - ERROR: \(err)")
                    
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
                    print("LOGIN - USER RESPONSE: \(responseData)")
                    
                    // The response will be the userID associated with the facebookID used, save the userID globally
                    Constants.Data.currentUser = responseData as! String
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
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
//                    parentVC.processAwsReturn(AWSGetBlobData(blob: self.blob), success: false)
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
//                                    self.getThumbnailImageForThumbnail(thumbnailID)
                                    let awsGetThumbnail = AWSGetThumbnailImage(thumbnailID: thumbnailID)
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
    var thumbnailID: String!
    
    required init(thumbnailID: String)
    {
        self.thumbnailID = thumbnailID
    }
    
    // Download Thumbnail Image
    override func makeRequest()
    {
        print("GETTING THUMBNAIL FOR: \(self.thumbnailID)")
        
        let downloadingFilePath = NSTemporaryDirectory() + self.thumbnailID // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.default()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketThumbnails
        downloadRequest.key =  self.thumbnailID
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
                            addThumbnailObject.blobThumbnailID = self.thumbnailID
                            addThumbnailObject.blobThumbnail = UIImage(data: tData)
                            Constants.Data.blobThumbnailObjects.append(addThumbnailObject)
                            
                            print("ADDED THUMBNAIL FOR IMAGE: \(self.thumbnailID))")
                            
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
//                                self.getUserImage(userObject.userID, imageKey: userObject.userImageKey)
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
//                        self.getUserImage(addUser.userID, imageKey: addUser.userImageKey)
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
        let transferManager = AWSS3TransferManager.default()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketUserImages
        downloadRequest.key =  self.user.userImageKey
        downloadRequest.downloadingFileURL = downloadingFileURL
        
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
                DispatchQueue.main.async(execute:
                    { () -> Void in
                        
                    // Assign the image to the Preview Image View
                    if FileManager().fileExists(atPath: downloadingFilePath)
                    {
                        print("IMAGE FILE AVAILABLE")
                        let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData
                        {
                            print("GET IMAGE - CHECK 1")
                            
//                            // Assign the image to the Preview User Image
//                            self.previewUserImageView.image = UIImage(data: tData)
//                            self.previewUserImageActivityIndicator.stopAnimating()
                            
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
                })
            }
            return nil
        })
    }
}

class AWSEditUserName : AWSRequestObject
{
    var userID: String!
    var newUserName: String!
    
    required init(userID: String, newUserName: String)
    {
        self.userID = userID
        self.newUserName = newUserName
    }
    
    // Edit the logged in user's userName
    func editUserName(_ user: User)
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
