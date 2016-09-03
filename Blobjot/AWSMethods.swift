//
//  AWSMethods.swift
//  Blobjot
//
//  Created by Sean Hart on 8/30/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSLambda
import AWSS3
import UIKit


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol AWSMethodsDelegate {
    
    // When called, the parent View Controller (MapViewController) refreshes the collection view
    func refreshCollectionView()
    
    // Update the MapView's Child BlobActionView's TableView
    func updateBlobActionTable()
    
    // Update the MapView's Preview Blob Data
    func updatePreviewBoxData(user: User)
    func refreshPreviewUserData(user: User)
    
    // For the AppDelegate (background processes), show the notification for the downloaded Blob
    func displayNotification(blob: Blob)
}

class AWSMethods {
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var awsMethodsDelegate: AWSMethodsDelegate?
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    func getBlobData(blobID: String) {
        print("REQUESTING GBD FOR BLOB: \(blobID)")
        
        // Create a JSON object with the passed Blob ID
        let json: NSDictionary = ["blob_id" : blobID]
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-GetBlobData", JSONObject: json, completionHandler: { (response, err) -> Void in
            
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
                            
                            if let parentVC = self.awsMethodsDelegate {
                                parentVC.refreshCollectionView()
                            }
                            
                            if let parentVC = self.awsMethodsDelegate {
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
    func getThumbnailImageForThumbnail(thumbnailID: String) {
        print("GETTING THUMBNAIL FOR: \(thumbnailID)")
        
        let downloadingFilePath = NSTemporaryDirectory().stringByAppendingString(thumbnailID) // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketThumbnails
        downloadRequest.key =  thumbnailID
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        transferManager.download(downloadRequest).continueWithBlock({ (task) -> AnyObject! in
            if let error = task.error {
                if error.domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error.code) == AWSS3TransferManagerErrorType.Paused {
                    print("GTFT: DOWNLOAD PAUSED")
                } else {
                    print("GTFT: DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("GTFT: DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("GTFT: DOWNLOAD SUCCEEDED")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Assign the image to the Preview Image View
                    if NSFileManager().fileExistsAtPath(downloadingFilePath) {
                        print("THUMBNAIL FILE AVAILABLE")
                        let thumbnailData = NSData(contentsOfFile: downloadingFilePath)
                        
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
    func getSingleUserData(userID: String, forPreviewBox: Bool) {
        print("MVC: REQUESTING GSUD")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : userID]
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-GetSingleUserData", JSONObject: json, completionHandler: { (response, err) -> Void in
            
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
                    
                    if let parentVC = self.awsMethodsDelegate {
                        
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
    func getUserImage(userID: String, imageKey: String) {
        print("MVC: GETTING IMAGE FOR: \(imageKey)")
        
        let downloadingFilePath = NSTemporaryDirectory().stringByAppendingString(imageKey) // + Constants.Settings.frameImageFileType)
        let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketUserImages
        downloadRequest.key =  imageKey
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        transferManager.download(downloadRequest).continueWithBlock({ (task) -> AnyObject! in
            if let error = task.error {
                if error.domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error.code) == AWSS3TransferManagerErrorType.Paused {
                    print("MVC: DOWNLOAD PAUSED")
                } else {
                    print("MVC: DOWNLOAD FAILED: [\(error)]")
                }
            } else if let exception = task.exception {
                print("MVC: DOWNLOAD FAILED: [\(exception)]")
            } else {
                print("MVC: DOWNLOAD SUCCEEDED")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Assign the image to the Preview Image View
                    if NSFileManager().fileExistsAtPath(downloadingFilePath) {
                        print("IMAGE FILE AVAILABLE")
                        let thumbnailData = NSData(contentsOfFile: downloadingFilePath)
                        
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
                                    
                                    if let parentVC = self.awsMethodsDelegate {
                                        parentVC.refreshPreviewUserData(userObject)
                                    }
                                    
                                    break loopUserObjectCheck
                                }
                            }
                            
                            if let parentVC = self.awsMethodsDelegate {
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
    
}