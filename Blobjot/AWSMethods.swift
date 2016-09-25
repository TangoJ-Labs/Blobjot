//
//  AWSMethods.swift
//  Blobjot
//
//  Created by Sean Hart on 8/30/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSLambda
import AWSS3
import FBSDKLoginKit
import GoogleMaps
import UIKit


/*

protocol AWSMethodsCognitoDelegate {
    
//    // A general handler to indicate that an AWS Method finished
//    func processAwsReturn(_ methodType: Constants.AWSMethodTypes, success: Bool)
}

class AWSMethods {
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var awsMethodsMapVcDelegate: AWSMethodsMapVcDelegate?
    var awsMethodsCognitoDelegate: AWSMethodsCognitoDelegate?
    
    // Use this method to call all other AWS methods to ensure that the user's credentials are still valid
//    func prepAWSRequest(methodToCall: Constants.AWSMethodTypes) {
    func prepAWSRequest(methodToCall: AWSRequestObject) {
        
        // Check to see if the facebook user id is already in the FBSDK
        if let facebookToken = FBSDKAccessToken.current() {
            
            // Ensure that the Cognito ID is still valid
            if Constants.credentialsProvider.identityId != nil {
                
                // Assign the Facebook Token to the AWSRequestObject
                methodToCall.facebookToken = facebookToken
                
                // If the Identity ID is still valid, go ahead and fire the needed method
                self.gotCognitoID(methodToCall)
                
            } else {
                
                // If the Cognito credentials have expired, request the credentials again (Cognito Identity ID) and use the current Facebook info
                self.getCognitoIdentityID(facebookToken)
            }
            
        } else {
            print("***** USER NEEDS TO LOG IN AGAIN *****")
            
            if let parentVC = self.awsMethodsMapVcDelegate {
                print("PARENT VC IS: \(parentVC)")
                
                // Check to see if the parent viewcontroller is already the MapViewController.  If so, call the MVC showLoginScreen function
                // Otherwise, launch a new MapViewController and show the login screen
                if parentVC is MapViewController {
                    
                    print("PARENT VC IS EQUAL TO MVC")
                    parentVC.showLoginScreen()
                } else {
                    
                    print("PARENT VC IS NOT EQUAL TO MVC")
                    let newMapViewController = MapViewController()
                    if let rootNavController = UIApplication.shared.windows[0].rootViewController?.navigationController {
                        rootNavController.pushViewController(newMapViewController, animated: true)
                    }
                }
            }
            
//            // Create the Login View Controller and present over the current context
//            let loginViewController = LoginViewController()
//            loginViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
//            if var topController = UIApplication.shared.keyWindow?.rootViewController {
//                while let presentedViewController = topController.presentedViewController {
//                    topController = presentedViewController
//                }
//                print("TOP VIEW CONTROLLER: \(topController)")
//                // topController should now be your topmost view controller
//                topController.present(loginViewController, animated: true, completion: nil)
//            }
////            self.present(loginViewController, animated: true, completion: nil)
//            print("MVC - SHOULD BE PRESENTING LVC")
        }
    }
    
    // Once the Facebook token is gained, request a Cognito Identity ID
    func getCognitoIdentityID(_ token: FBSDKAccessToken) {
        
        // Authenticate the user in AWS Cognito
        Constants.credentialsProvider.logins = [AWSIdentityProviderFacebook: token.tokenString]
        
//        let customProviderManager = CustomIdentityProvider(tokens: [AWSIdentityProviderFacebook: token.tokenString])
//        let identityProviderManager = AWSIdentityProviderManager()
//        identityProviderManager.logins = [AWSIdentityProviderFacebook: token.tokenString]
//        Constants.credentialsProvider = AWSCognitoCredentialsProvider(
//            regionType: Constants.Strings.aws_region
//            , identityPoolId: Constants.Strings.aws_cognitoIdentityPoolId
//            , identityProviderManager: customProviderManager
//        )
        
        // Retrieve your Amazon Cognito ID
        Constants.credentialsProvider.getIdentityId().continue( {(task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                print("AWS COGNITO GET IDENTITY ID - ERROR: " + task.error!.localizedDescription)
            } else {
                // the task result will contain the identity id
                let cognitoId = task.result
                print("AWS COGNITO GET IDENTITY ID - AWS COGNITO ID: \(cognitoId)")
                print("AWS COGNITO GET IDENTITY ID - CHECK IDENTITY ID: \(Constants.credentialsProvider.identityId)")
                
                // Request extra facebook data for the user ON THE MAIN THREAD
                DispatchQueue.main.async(execute: {
                    
                    let methodToCall = AWSLoginUser()
                    methodToCall.facebookToken = token
                    self.gotCognitoID(methodToCall)
                    
//                    self.fbGraphRequest(token.userID)
//                    print("FBSDK - REQUESTED ADDITIONAL USER INFO")
                });
            }
            return nil
        })
    }
    
    func gotCognitoID(_ awsMethod: AWSRequestObject)
    {
        
        // Fire the needed AWSMethod based on the passed type
        switch awsMethod
        {
        case let awsLoginUser as AWSLoginUser: // 0
            if awsLoginUser.facebookToken != nil
            {
                // Request the user data now that we have the Cognito ID
                self.fbGraphRequest(awsLoginUser.facebookToken!.userID)
                print("FBSDK - REQUESTED ADDITIONAL USER INFO")
            }
        case .logoutUser: // 1
            
        case .getMapData: // 2
            self.getMapData()
        case .getBlobData: // 3
            
        case .getThumbnailImageForThumbnail: // 4
            
        case .getSingleUserData: // 5
            
        case .getUserImage: // 6
            
        case .editUserName: // 7
            
        default:
            print("***** ERROR: THAT IS NOT A RECOGNIZED AWS METHOD *****")
        }
    }
    
    //
    //
    //
    //
    
    // The initial request for Map Blob data - called when the View Controller is instantiated
    func getMapData() {
        print("REQUESTING GMD")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetMapData", jsonObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("GET MAP DATA ERROR: \(err)")
                print("GET MAP DATA ERROR CODE: \(err!._code)")
                
                // Process the error codes and alert the user if needed
                if err!._code == 1 && Constants.Data.currentUser != "" {
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsMethodsMapVcDelegate {
                        parentVC.processAwsReturn(AWSTypes.AWSMethodTypes.getMapData, success: false)
                    }
                }
                
            } else if (response != nil) {
                
                // Convert the response to an array of AnyObjects
                if let newMapBlobs = response as? [AnyObject] {
                    print("MVC-GMD: jsonData: \(newMapBlobs)")
                    print("BLOB COUNT: \(newMapBlobs.count)")
                    
                    // Always clear the mapCircles before clearing the mapBlobs data otherwise the circles will be unresponsive
                    // Each circle must individually have their map nullified, otherwise the mapView will still display the circle
                    for circle in Constants.Data.mapCircles {
                        circle.map = nil
                    }
                    Constants.Data.mapCircles = [GMSCircle]()
                    
                    // Clear global mapBlobs
                    Constants.Data.mapBlobs = [Blob]()
                    
                    // Loop through each AnyObject (Blob) in the array
                    for newBlob in newMapBlobs {
                        print("NEW BLOB: \(newBlob)")
                        
                        // Convert the AnyObject to JSON with keys and AnyObject values
                        // Then convert the AnyObject values to Strings or Numbers depending on their key
                        if let checkBlob = newBlob as? [String: AnyObject] {
                            let blobTimestamp = checkBlob["blobTimestamp"] as! Double
                            let blobDatetime = Date(timeIntervalSince1970: blobTimestamp)
                            let blobTypeInt = checkBlob["blobType"] as! Int
                            
                            // Evaluate the blobType Integer received and convert it to the appropriate BlobType Class
                            var blobType: Constants.BlobTypes!
                            switch blobTypeInt {
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
                    if let parentVC = self.awsMethodsMapVcDelegate {
                        parentVC.processAwsReturn(AWSTypes.AWSMethodTypes.getMapData, success: true)
                    }
                }
            }
            
        })
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    func getBlobData(_ blobID: String) {
        print("REQUESTING GBD FOR BLOB: \(blobID)")
        
        // Create a JSON object with the passed Blob ID
        let json: NSDictionary = ["blob_id" : blobID]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetBlobData", jsonObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("GET BLOB DATA ERROR: \(err)")
            } else if (response != nil) {
                print("AWSM-GBD: response: \(response)")
                
                // Convert the response to JSON with keys and AnyObject values
                // Then convert the AnyObject values to Strings or Numbers depending on their key
                // Start with converting the Blob ID to a String
                if let checkBlob = response as? [String: AnyObject] {
                    let extraBlobID = checkBlob["blobID"] as! String
                    
                    // Find the Blob in the global Map Blobs array and add the extra data to the Blob
                    loopMapBlobCheck: for mBlob in Constants.Data.mapBlobs {
                        if mBlob.blobID == extraBlobID {
                            
                            print("ASSIGNING EXTRA MAP BLOB DATA")
                            mBlob.blobMediaType = checkBlob["blobMediaType"] as? Int
                            mBlob.blobMediaID = checkBlob["blobMediaID"] as? String
                            mBlob.blobThumbnailID = checkBlob["blobThumbnailID"] as? String
                            mBlob.blobText = checkBlob["blobText"] as? String
                            print("ASSIGNED EXTRA MAP BLOB DATA")
                            
                            // ...and request the Thumbnail image data if the Thumbnail ID is not null
                            if let thumbnailID = mBlob.blobThumbnailID {
                                print("ABOUT TO CALL GET THUMBNAIL FOR: \(thumbnailID)")
                                
                                // Ensure the thumbnail does not already exist
                                var thumbnailExists = false
                                loopThumbnailCheck: for tObject in Constants.Data.blobThumbnailObjects {
                                    print("GET THUMBNAIL - CHECK 2")
                                    
                                    // Check to see if the thumbnail Object ID matches
                                    if tObject.blobThumbnailID == thumbnailID {
                                        print("GET THUMBNAIL - CHECK 3")
                                        thumbnailExists = true
                                        
                                        break loopThumbnailCheck
                                    }
                                }
                                // If the thumbnail does not exist, download it and append it to the global Thumbnail array
                                if !thumbnailExists {
                                    self.getThumbnailImageForThumbnail(thumbnailID)
                                }
                            }
                            
                            // Check the global Location Blobs array for the Blob and assign the extra data if the Blob exists
                            var blobExistsInLocationBlobs = false
                            loopLocationBlobCheck: for lBlob in Constants.Data.locationBlobs {
                                if lBlob.blobID == extraBlobID {
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
                            if !blobExistsInLocationBlobs {
                                Constants.Data.locationBlobs.append(mBlob)
                                print("APPENDED BLOB AFTER DOWNLOAD: \(mBlob.blobText)")
                            }
                            
//                            // Notify the parent view that the AWS call completed successfully
//                            if let parentVC = self.AWSMethodsMapVcDelegate {
//                                parentVC.processAwsReturn(Constants.AWSMethodTypes.getBlobData, success: true)
//                            }
                            
                            if let parentVC = self.awsMethodsMapVcDelegate {
                                parentVC.refreshCollectionView()
                            }
                            
                            if let parentVC = self.awsMethodsMapVcDelegate {
                                parentVC.displayNotification(mBlob)
                            }
                            
                            break loopMapBlobCheck
                        }
                    }
                }
            }
        })
    }
    
    // Download Thumbnail Image
    func getThumbnailImageForThumbnail(_ thumbnailID: String) {
        print("GETTING THUMBNAIL FOR: \(thumbnailID)")
        
        let downloadingFilePath = NSTemporaryDirectory() + thumbnailID // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.default()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketThumbnails
        downloadRequest.key =  thumbnailID
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        transferManager?.download(downloadRequest).continue({ (task) -> AnyObject! in
            if let error = task.error {
                if error._domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused {
                    print("GTFT: DOWNLOAD PAUSED")
                } else {
                    print("GTFT: DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("GTFT: DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("GTFT: DOWNLOAD SUCCEEDED")
                DispatchQueue.main.async(execute: { () -> Void in
                    // Assign the image to the Preview Image View
                    if FileManager().fileExists(atPath: downloadingFilePath) {
                        print("THUMBNAIL FILE AVAILABLE")
                        let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData {
                            print("GET THUMBNAIL - CHECK 1")
                            
                            // Create a Blob Thumbnail Object, assign the Thumbnail ID and newly downloaded Image
                            let addThumbnailObject = BlobThumbnailObject()
                            addThumbnailObject.blobThumbnailID = thumbnailID
                            addThumbnailObject.blobThumbnail = UIImage(data: tData)
                            Constants.Data.blobThumbnailObjects.append(addThumbnailObject)
                            
                            print("ADDED THUMBNAIL FOR IMAGE: \(thumbnailID))")
                        }
                        
                    } else {
                        print("FRAME FILE NOT AVAILABLE")
                    }
                })
            }
            return nil
        })
    }
    
    
    // The initial request for Map Blob data - called when the View Controller is instantiated
    func getSingleUserData(_ userID: String, forPreviewBox: Bool) {
        print("MVC: REQUESTING GSUD")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : userID]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-GetSingleUserData", jsonObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("MVC: GET USER CONNECTIONS DATA ERROR: \(err)")
            } else if (response != nil) {
                
                // Convert the response to an array of arrays
                if let userJson = response as? [String: AnyObject] {
                    
                    let userID = userJson["user_id"] as! String
                    let userName = userJson["user_name"] as! String
                    let userImageKey = userJson["user_image_key"] as! String
                    print("MVC: USER ID: \(userID)")
                    print("MVC: USER NAME: \(userName)")
                    print("MVC: USER IMAGE KEY: \(userImageKey)")
                    
                    // Create a User Object and add it to the global User array
                    let addUser = User()
                    addUser.userID = userID
                    addUser.userName = userName
                    addUser.userImageKey = userImageKey
                    
                    // Check to ensure the user does not already exist in the global User array
                    var userObjectExists = false
                    loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                        if userObject.userID == userID {
                            // Update the user data with the latest data
                            userObject.userName = userName
                            userObject.userImageKey = userImageKey
                            
                            // If the userImage has not been downloaded, request a new download
                            if userObject.userImage == nil {
                                self.getUserImage(userObject.userID, imageKey: userObject.userImageKey)
                            }
                            
                            userObjectExists = true
                            break loopUserObjectCheck
                        }
                    }
                    if userObjectExists == false {
                        print("USER: \(userName) DOES NOT EXIST - ADDING")
                        Constants.Data.userObjects.append(addUser)
                        
                        // Download the user image and assign to the preview user image
                        self.getUserImage(addUser.userID, imageKey: addUser.userImageKey)
                    }
                    
                    if let parentVC = self.awsMethodsMapVcDelegate {
                        
                        parentVC.refreshCollectionView()
                        
                        // If the Blob Active View Controller is not null, send a refresh command so that the Parent VC's Child's VC's Table View's rows look for the new data
                        parentVC.updateBlobActionTable()
                        
                        // If the MapView called this method to update the Preview Box, send the needed data to the PreviewBox
                        if forPreviewBox {
                            parentVC.updatePreviewBoxData(addUser)
                        }
                    }
                    
                }
            }
        })
    }
    
    // Download User Image
    func getUserImage(_ userID: String, imageKey: String) {
        print("MVC: GETTING IMAGE FOR: \(imageKey)")
        
        let downloadingFilePath = NSTemporaryDirectory() + imageKey // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.default()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketUserImages
        downloadRequest.key =  imageKey
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        transferManager?.download(downloadRequest).continue({ (task) -> AnyObject! in
            if let error = task.error {
                if error._domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused {
                    print("MVC: DOWNLOAD PAUSED")
                } else {
                    print("MVC: DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("MVC: DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("MVC: DOWNLOAD SUCCEEDED")
                DispatchQueue.main.async(execute: { () -> Void in
                    // Assign the image to the Preview Image View
                    if FileManager().fileExists(atPath: downloadingFilePath) {
                        print("IMAGE FILE AVAILABLE")
                        let thumbnailData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                        
                        // Ensure the Thumbnail Data is not null
                        if let tData = thumbnailData {
                            print("GET IMAGE - CHECK 1")
                            
//                            // Assign the image to the Preview User Image
//                            self.previewUserImageView.image = UIImage(data: tData)
//                            self.previewUserImageActivityIndicator.stopAnimating()
                            
                            // Find the correct User Object in the global list and assign the newly downloaded Image
                            loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                                if userObject.userID == userID {
                                    userObject.userImage = UIImage(data: tData)
                                    
                                    if let parentVC = self.awsMethodsMapVcDelegate {
                                        parentVC.refreshPreviewUserData(userObject)
                                    }
                                    
                                    break loopUserObjectCheck
                                }
                            }
                            
                            if let parentVC = self.awsMethodsMapVcDelegate {
                                parentVC.refreshCollectionView()
                                
                                // If the Blob Active View Controller is not null, send a refresh command so that the Parent VC's Child's VC's Table View's rows look for the new data
                                parentVC.updateBlobActionTable()
                            }
                            
                        }
                        
                    } else {
                        print("FRAME FILE NOT AVAILABLE")
                    }
                })
            }
            return nil
        })
    }
    
    // Edit the logged in user's userName
    func editUserName(_ userID: String, userName: String)
    {
        let json: NSDictionary = ["user_id" : userID, "user_name": userName]
        print("EDITING USER NAME TO: \(json)")
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Blobjot-EditUserName", jsonObject: json, completionHandler:
        {(responseData, err) -> Void in
            
            if (err != nil)
            {
                print("Error: \(err)")
            }
            else if (responseData != nil)
            {
                print("EDIT USER NAME RESPONSE: \(responseData)")
            }
        })
    }
    
    
    
    // FBSDK METHODS
    
    func fbGraphRequest(_ facebookID: String)
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
                        
                        self.loginUser(facebookID, facebookName: (facebookName as! String), facebookThumbnailUrl: facebookImageUrl)
                    }
                }
                
            }
        }
    }
    
}
*/
