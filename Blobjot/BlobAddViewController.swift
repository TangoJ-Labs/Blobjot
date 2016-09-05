//
//  BlobAddViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/30/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AssetsLibrary
import AVFoundation
import AWSLambda
import AWSS3
import GoogleMaps
import MobileCoreServices
import Photos
import UIKit

// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol BlobAddViewControllerDelegate {
    
    // When called, the parent View Controller dismisses the top VC (should be this one)
    func popViewController()
    
    // Used to add the new Blob to the map
    func createBlobOnMap(blobCenter: CLLocationCoordinate2D, blobRadius: Double, blobType: Constants.BlobTypes, blobTitle: String)
}

class BlobAddViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GMSMapViewDelegate, BlobAddTypeViewControllerDelegate, BlobAddMediaViewControllerDelegate, BlobAddPeopleViewControllerDelegate {
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var blobAddViewDelegate: BlobAddViewControllerDelegate?
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Declar the view components
    var viewContainer: UIView!
    var pageViewContainer: UIView!
    var pageViewController: UIPageViewController!
    var pageControl: UIPageControl!
    var mapView: GMSMapView!
    
    var viewScreen: UIView!
    var viewScreenActivityIndicator: UIActivityIndicatorView!
    
    // Declare the view controllers that make up the page viewer
    var viewControllers: [UIViewController]!
    var vc1: BlobAddTypeViewController!
    var vc2: BlobAddTextViewController!
    var vc3: BlobAddMediaViewController!
    var vc4: BlobAddPeopleViewController!
    
    // These variables should be passed data from the Map View concerning the Blob created
    var addCircle: GMSCircle!
    var blobCoords: CLLocationCoordinate2D!
    var blobRadius: Double!
    var mapZoom: Float!
    
    // These variables will hold the Blob content created in the Page Views
    var blobType = Constants.BlobTypes.Temporary
//    var blobText: String?
    var blobThumbnail: UIImage?
    var blobImage: UIImage?
//    var blobUserTags = [String]()
    var blobMediaType = 1
    
    var randomMediaID: String?
    var uploadImageFilePath: String?
    
    var blobVideoUrl: NSURL?
    var uploadVideoFilePath: String?
    var uploadThumbnailFilePath: String!
    
    var sendAttempted: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and set the Nav Bar right button here, and not in the parent VC because this View Controller needs
        // to call this method so that it can pass local variables
        let rightButtonItem = UIBarButtonItem(title: "Send",
                                              style: UIBarButtonItemStyle.Plain,
                                              target: self,
                                              action: #selector(self.sendBlobAndPopViewController(_:)))
        rightButtonItem.tintColor = UIColor.whiteColor()
        self.navigationItem.setRightBarButtonItem(rightButtonItem, animated: true)
        
        // Instantiate and assign delegates for the Page Viewer View Controllers
        vc1 = BlobAddTypeViewController()
        vc1.blobAddTypeDelegate = self
        vc2 = BlobAddTextViewController()
        vc3 = BlobAddMediaViewController()
        vc3.blobAddMediaDelegate = self
        vc4 = BlobAddPeopleViewController()
        vc4.blobAddPeopleDelegate = self
        viewControllers = [vc1, vc2, vc3, vc4]

        // Status Bar Settings
        UIApplication.sharedApplication().statusBarHidden = false
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
//        navBarHeight = self.navigationController?.navigationBar.frame.height
        navBarHeight = 44
        print("**************** BAVC - NAV BAR HEIGHT: \(navBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** BAVC - VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.mainScreen().bounds
        print("**************** BAVC - SCREEN HEIGHT: \(screenSize.height)")
        print("**************** BAVC - VIEW HEIGHT: \(self.view.frame.height)")
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        // Add the Page View container and controller at the top of the view, but under the nav bar and search bar
        pageViewContainer = UIView(frame: CGRect(x: 0, y: 0 - viewFrameY, width: viewContainer.frame.width, height: viewContainer.frame.height - 10 - viewContainer.frame.width))
        viewContainer.addSubview(pageViewContainer)
        
        pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([viewControllers.first!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        pageViewContainer.addSubview(pageViewController.view)
        
        // Add a page controller (dots indicating the currently viewed page) under the page viewer
        pageControl = UIPageControl(frame: CGRect(x: 0, y: viewContainer.frame.height - 10 - viewContainer.frame.width, width: viewContainer.frame.width, height: 10))
        pageControl.numberOfPages = viewControllers.count
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.lightGrayColor()
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = Constants.Colors.colorPurple
        viewContainer.addSubview(pageControl)
        
        // Add the Map View under the page controller, and extend it to the bottom of the view
        // The Map View should be on the bottom of the view so that if the keyboard is opened, it covers the Map View
        // and not the Page Viewer (which is what needs to use the keyboard)
        let camera = GMSCameraPosition.cameraWithLatitude(blobCoords.latitude, longitude: blobCoords.longitude, zoom: mapZoom - 1)
        mapView = GMSMapView.mapWithFrame(CGRect(x: 0, y: viewContainer.frame.height - viewContainer.frame.width, width: viewContainer.frame.width, height: viewContainer.frame.width), camera: camera)
        mapView.delegate = self
        mapView.mapType = kGMSTypeNormal
        mapView.indoorEnabled = true
        mapView.myLocationEnabled = true
        viewContainer.addSubview(mapView)
        
        // Add the viewScreen and loading indicator for use when the Blob is being uploaded
        viewScreen = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewScreen.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        
        viewScreenActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewScreenActivityIndicator.color = UIColor.blackColor()
        
        // Set the angle at which the map should be viewed initially
        let desiredAngle = Double(60)
        mapView.animateToViewingAngle(desiredAngle)
        
        // Using the data passed from the parent VC (the Map View Controller), create a circle on the map where the user created the new Blob
        addCircle = GMSCircle(position: blobCoords, radius: blobRadius)
        addCircle.fillColor = Constants.Colors.blobRed
        addCircle.strokeColor = Constants.Colors.blobRed
        addCircle.strokeWidth = 1
        addCircle.map = mapView
        
        getRandomID()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: PAGE VIEW CONTROLLER - DATA SOURCE METHODS
    
    // The Before and After View Controller delegate methods control the order in which the pages are viewed
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        print("PAGE VIEW CONTROLLER - VC BEFORE VC: \(viewController)")
        
        let index = viewControllers.indexOf(viewController)
        if index == nil || index! == 0 {
            return nil
        } else {
            return viewControllers[index! - 1]
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        print("PAGE VIEW CONTROLLER - VC AFTER VC: \(viewController)")
        
        let index = viewControllers.indexOf(viewController)
        if index == nil || index! + 1 == viewControllers.count {
            return nil
        } else {
            return viewControllers[index! + 1]
        }
    }
    
    // Track which page view is about to be viewed and change the Page Control (dots) to highlight the correct dot
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        print("PAGE VIEW CONTROLLER - PENDING VCs: \(pendingViewControllers)")
        
        if let pendingVC = pendingViewControllers.first {
            let index = viewControllers.indexOf(pendingVC)
            print("PENDING INDEX: \(index)")
            pageControl.currentPage = index!
            
            if index! == 0 {
                print(vc2.blobTextView.text)
            }
        }
    }
    
    
    // MARK: PAGE VIEW CONTROLLER - DELEGATE METHODS
    // Return how many pages are needed in the Page Viewer
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return viewControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    
    // MARK: IMAGE PICKER DELEGATE METHODS
    // The Image Picker should be instantiated from this View Controller and not the BlobAddMedia VC to properly handle the media references passed from the picker
    
    // Instantiate the Media Picker
    // Be sure to include both Image and Video types as options
    func pickMediaPicker() {
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        mediaPicker.mediaTypes = [kUTTypeImage as String] //, kUTTypeMovie as String]
        self.presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    // Once the media has been selected, dismiss the Media Picker VC, capture the media location, and take a screenshot (for a movie type)
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("MEDIA SELECTED IS: \(info.description)")
        
        // Dismiss the Media Picker
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // Check the media type
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        // If an image, pass the image to the preview in the Media Page and make sure the Video indicator is not showing
        // If a movie, capture the file location, generate a screenshot at the first second of the movie, and pass the screenshot to
        // the preview on the Media Page and show the Video indicator on the Media Page
        // If an image, generate a temporary image and save locally.  Pass this temporary file location to the upload
        if mediaType == "public.image" {
            blobMediaType = 1
            
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                // Store the picked image to access when uploading
                blobImage = pickedImage
                
                print("BLOB IMAGE IS: \(blobImage)")
                
                // Save the thumbnail locally
                if let randomMediaID = self.randomMediaID {
                    
                    // Create and locally save the mediaImage
                    if let data = UIImagePNGRepresentation(pickedImage) {
                        print("CREATED THUMBNAIL")
                        uploadImageFilePath = NSTemporaryDirectory().stringByAppendingString(randomMediaID + ".png")
                        data.writeToFile(uploadImageFilePath!, atomically: true)
                    }
                }
                
                // Hide the video indicator since the media is an image
                vc3.videoPlayIndicator.text = ""
            }
        } else if mediaType == "public.movie" {
            blobMediaType = 2
            
            print("VIDEOS ARE NOT ALLOWED AT THIS TIME")
            
//            print("VIDEO MEDIA URL: \(info[UIImagePickerControllerMediaURL] as? NSURL)")
//            print("VIDEO REFERENCE URL: \(info[UIImagePickerControllerReferenceURL] as? NSURL)")
//            
//            let mediaURL = info[UIImagePickerControllerMediaURL] as? NSURL
//            let referenceURL = info[UIImagePickerControllerReferenceURL] as? NSURL
//            let targetURL: NSURL!
//            
//            // Save the file path for access when uploading the file - find which URL type is not nil
//            if mediaURL != nil {
//                
//                targetURL = mediaURL
//            } else {
//                
//                targetURL = referenceURL
//            }
//            
//            // Save the video to a local file for upload
////            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
////                PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(NSURL(fileURLWithPath: self.blobVideoUrl!.absoluteString))
////            }) { completed, error in
////                if completed {
////                    print("Video is saved!")
////                }
////            }
//            
////            let library: ALAssetsLibrary = ALAssetsLibrary()
////            let videoWriteCompletionBlock: ALAssetsLibraryWriteVideoCompletionBlock = {(newURL: NSURL!, error: NSError!) in
////                if (error != nil) {
////                    NSLog("Error writing image with metadata to Photo Library: %@", error)
////                }
////                else {
////                    NSLog("Wrote image with metadata to Photo Library %@", newURL)
////                    self.blobVideoUrl = newURL
////                }
////                
////            }
////            if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(targetURL) {
////                library.writeVideoAtPathToSavedPhotosAlbum(targetURL, completionBlock: videoWriteCompletionBlock)
////            }
//            
//            // Create an asset and generate a screenshot at one second into the video
//            let asset = AVURLAsset(URL: blobVideoUrl!)
//            let generator = AVAssetImageGenerator(asset: asset)
//            generator.appliesPreferredTrackTransform = true
//            
//            let timestamp = CMTime(seconds: 0, preferredTimescale: 60)
//            
//            do {
//                let imageRef = try generator.copyCGImageAtTime(timestamp, actualTime: nil)
//                
//                // Store the picked image to access when uploading
//                blobImage = UIImage(CGImage: imageRef)
//                
//                // Show the indicator that the media is a video
//                vc3.videoPlayIndicator.text = "\u{25B6}"
//            } catch let error as NSError {
//                print("Image generation failed with error \(error)")
//            }
        }
        
        // If the blobImage was successfully saved, create a low-quality thumbnail and save it locally
        if let blobImage = self.blobImage {
//            blobThumbnail = blobImage.resizeWithPercentage(0.2)
            blobThumbnail = blobImage.resizeWithWidth(Constants.Dim.blobsActiveTableViewContentSize)
            
            // Save the thumbnail locally
            if let randomMediaID = self.randomMediaID {
                
                // Create and locally save the thumbnail
                if let data = UIImagePNGRepresentation(blobThumbnail!) {
                    print("CREATED THUMBNAIL")
                    uploadThumbnailFilePath = NSTemporaryDirectory().stringByAppendingString(randomMediaID + "_THUMBNAIL_" + ".png")
                    data.writeToFile(uploadThumbnailFilePath, atomically: true)
                }
            }
            
            // Show the blobImage in the Media View in the Page View
            vc3.mediaPickerImage.image = blobImage
        }
    }
    
    // If the user cancels picking media, dismiss the Media Picker
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        print("CANCELLED MEDIA PICKER")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

    
    // MARK: CUSTOM FUNCTIONS
    
    // For the delegate methods called in this View Controller, use a centralized function to change 
    // the Circle color on the Map View and pass down the color indicator changes to the BlobAddType (vc1) View Controller
    func changeMapCircleType(type: Constants.BlobTypes) {
        print("BLOB ADD VIEW CHANGE MAP CIRCLE TYPE TO: \(type)")
        
        // Save the lastest type for access when uploading
        self.blobType = type
        
        // Set the settings to default before evaluating the type
        var color = Constants().blobColor(.Temporary)
        var resetSelectAllMessage = false
        
        // Evaluate the type and mark the correct selection with a check mark and change the circle color
        // Be sure to reset the Select All Message on the User Tag Page View if a specific color is selected
        switch type {
        case .Temporary:
            color = Constants().blobColor(.Temporary)
            
            vc1.typeContainer1CheckLabel.text = "\u{2713}"
            vc1.typeContainer2CheckLabel.text = ""
            vc1.typeContainer3CheckLabel.text = ""
            
            resetSelectAllMessage = true
            
        case .Permanent:
            color = Constants().blobColor(.Permanent)
            
            vc1.typeContainer1CheckLabel.text = ""
            vc1.typeContainer2CheckLabel.text = "\u{2713}"
            vc1.typeContainer3CheckLabel.text = ""
            
            resetSelectAllMessage = true
            
        case .Public:
            color = Constants().blobColor(.Public)
            
            vc1.typeContainer1CheckLabel.text = ""
            vc1.typeContainer2CheckLabel.text = ""
            vc1.typeContainer3CheckLabel.text = ""
            
        case .Invisible:
            color = Constants().blobColor(.Invisible)
            
            vc1.typeContainer1CheckLabel.text = ""
            vc1.typeContainer2CheckLabel.text = ""
            vc1.typeContainer3CheckLabel.text = "\u{2713}"
            
            resetSelectAllMessage = true
        
        // Default to a Temporary Blob in case of an error
        default:
            color = Constants().blobColor(.Temporary)
            
            vc1.typeContainer1CheckLabel.text = "\u{2713}"
            vc1.typeContainer2CheckLabel.text = ""
            vc1.typeContainer3CheckLabel.text = ""
            
            resetSelectAllMessage = true
        }
        
        // If the select all message is marked to be reset, uncheck the Select All box and hide the overlay message
        if resetSelectAllMessage && vc4.selectAllBox != nil {
            vc4.selectAll = false
            vc4.selectAllBox.text = ""
            vc4.selectAllMessage.removeFromSuperview()
            vc4.searchBarContainer.addSubview(vc4.searchBar)
        }
        
        // Finally, change the Circle to the selected type color
        addCircle.fillColor = color
        addCircle.strokeColor = color
    }
    
    
    // The function called by the "Send" button on the Nav Bar
    // Upload the new Blob data to the server and then dismiss the BlobAdd VC from the parent VC (the Map View)
    func sendBlobAndPopViewController(sender: UIBarButtonItem) {
        print("SEND FILES TO S3 AND DATA TO LAMBDA AND POP VC")
        print("RANDOM ID: \(self.randomMediaID)")
        
        // Ensure that this is the first time the Blob send has been attempted
        if !self.sendAttempted {
            self.sendAttempted = true
            
            // Show the view screen to indicate that the app is working
            viewContainer.addSubview(viewScreen)
            viewContainer.addSubview(viewScreenActivityIndicator)
            viewScreenActivityIndicator.startAnimating()
            
            // Prepare the media and urls for upload
            if let randomMediaID = self.randomMediaID {
                print("SENDING FILES")
                
                // Calculate the current time to use in dating the Blob
                let nowTime = NSDate().timeIntervalSince1970
                
                // Set the media key to an image by default - it will change to an .mp4 if it is a video
                let uploadMediaKey = randomMediaID + ".png"
                
                // If the media is an image, upload using temporary image and delete the temporary image
                if self.blobMediaType == 1 {
                    
                    // Upload the image to AWS, and upload the Blob data after the file is successfully uploaded
                    if let imageFilePath = self.uploadImageFilePath {
                        self.uploadMediaToBucket(Constants.Strings.S3BucketMedia, uploadMediaFilePath: imageFilePath, mediaID: randomMediaID, uploadKey: uploadMediaKey, currentTime: nowTime, deleteWhenFinished: true)
                    }
                    
                } else if self.blobMediaType == 2 {
                    print("VIDEOS ARE NOT ALLOWED AT THIS TIME")
                    
//                    // Else if the media is a video, change the file path to .mp4 and upload using the selected file path from the picker
//                    
//                    uploadMediaKey = randomMediaID + ".mp4"
//                    
//                    print("BLOB MEDIA URL: \(self.blobVideoUrl)")
//                    print("BLOB MEDIA URL ABS STRING: \(self.blobVideoUrl?.absoluteString)")
//                    print("BLOB MEDIA URL REL STRING: \(self.blobVideoUrl?.relativeString)")
//                    print("BLOB MEDIA URL PARA STRING: \(self.blobVideoUrl?.parameterString)")
//                    print("BLOB MEDIA URL PATH: \(self.blobVideoUrl?.path)")
//                    print("BLOB MEDIA URL REL PATH: \(self.blobVideoUrl?.relativePath)")
//                    
//                    // If the video url is not null, get the string filepath and send that to be uploaded to AWS
//                    if let videoUrl = self.blobVideoUrl {
//                        self.uploadVideoFilePath = videoUrl.absoluteString
//                        
//                        if let videoFilePath = self.uploadVideoFilePath {
//                            self.uploadMediaToBucket(Constants.Strings.S3BucketMedia, uploadMediaFilePath: videoFilePath, uploadKey: uploadMediaKey, deleteWhenFinished: false)
//                        }
//                    }
                }
                
                // Upload the Thumbnail to AWS
                if let thumbnailFilePath = self.uploadThumbnailFilePath {
                    self.uploadMediaToBucket(Constants.Strings.S3BucketThumbnails, uploadMediaFilePath: thumbnailFilePath, mediaID: randomMediaID, uploadKey: randomMediaID + ".png", currentTime: nowTime, deleteWhenFinished: true)
                }
            }
        }
    }
    
    // Create an alert screen with only an acknowledgment option (an "OK" button)
    func createAlertOkView(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: AWS FUNCIONS
    
    // Request a random MediaID
    func getRandomID() {
        print("REQUESTING RANDOM ID")
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["request" : "random_media_id"]
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-CreateRandomID", JSONObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("GET RANDOM ID ERROR: \(err)")
            } else if (response != nil) {
                
                // Convert the response to a String
                if let randomID = response as? String {
                    print("RANDOM ID IS: \(randomID)")
                    self.randomMediaID = randomID
                }
            }
            
        })
    }
    
    // Upload a file to AWS S3
    func uploadMediaToBucket(bucket: String, uploadMediaFilePath: String, mediaID: String, uploadKey: String, currentTime: Double, deleteWhenFinished: Bool) {
        print("UPLOADING FILE: \(uploadKey) TO BUCKET: \(bucket)")
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = bucket
        uploadRequest.key =  uploadKey
        uploadRequest.body = NSURL(fileURLWithPath: uploadMediaFilePath)
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        transferManager.upload(uploadRequest).continueWithBlock({ (task) -> AnyObject! in
            if let error = task.error {
                if error.domain == AWSS3TransferManagerErrorDomain as String
                    && AWSS3TransferManagerErrorType(rawValue: error.code) == AWSS3TransferManagerErrorType.Paused {
                    print("Upload paused.")
                } else {
                    print("Upload failed: [\(error)]")
                    self.createAlertOkView("On no!", message: "We had a problem uploading your Blob.  Please try again.")
                }
            } else if let exception = task.exception {
                print("Upload failed: [\(exception)]")
            } else {
                print("Upload succeeded")
                
                // Save the list of tagged users
                var taggedUsers = [String]()
                for selectUser in self.vc4.peopleListSelected {
                    taggedUsers.append(selectUser.userID)
                }
                
                // If the media file was successfully updated, save the Blob data to AWS
                if bucket == Constants.Strings.S3BucketMedia {
                    // Upload the Blob data to Lamda and then DynamoDB
                    self.uploadBlobData(mediaID, blobLat: self.blobCoords.latitude, blobLong: self.blobCoords.longitude, blobMediaID: uploadKey, blobMediaType: self.blobMediaType, blobRadius: self.blobRadius, blobText: self.vc2.blobTextView.text, blobThumbnailID: mediaID + ".png", blobTimestamp: currentTime, blobType: self.blobType.rawValue, blobTaggedUsers: taggedUsers, blobUserID: Constants.Data.currentUser)
                }
                
                // If the file was flagged for deletion, delete it
                if deleteWhenFinished {
                    do {
                        print("Deleting media: \(uploadKey)")
                        try NSFileManager.defaultManager().removeItemAtPath(uploadMediaFilePath)
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                }
                
                print("MAP BLOBS COUNT 1: \(Constants.Data.mapBlobs.count)")
                
                // Create a new Blob locally so that the Circle can immediately be added to the map
                let newBlob = Blob()
                newBlob.blobID = mediaID
                newBlob.blobDatetime = NSDate(timeIntervalSince1970: currentTime)
                newBlob.blobLat = self.blobCoords.latitude
                newBlob.blobLong = self.blobCoords.longitude
                newBlob.blobRadius = self.blobRadius
                newBlob.blobType = self.blobType
                newBlob.blobUserID = Constants.Data.currentUser
                Constants.Data.userBlobs.append(newBlob)
                
                // Check to see if the logged in user was tagged
                loopTaggedUsers: for person in taggedUsers {
                    print("CHECKING TAGGED USERS: \(person)")
                    // If the logged in user was tagged, add the Blob to the mapBlobs so that it shows on the Map View
                    if person == Constants.Data.currentUser {
                        print("ADDING TO MAP BLOBS")
                        Constants.Data.mapBlobs.append(newBlob)
                        
                        // Call the parent VC to add the new Blob to the map of the Map View
                        if let parentVC = self.blobAddViewDelegate {
                            parentVC.createBlobOnMap(CLLocationCoordinate2DMake(self.blobCoords.latitude, self.blobCoords.longitude), blobRadius: self.blobRadius, blobType: self.blobType, blobTitle: mediaID)
                        }
                        break loopTaggedUsers
                    }
                }
                
                print("MAP BLOBS COUNT 2: \(Constants.Data.mapBlobs.count)")
                print("USER BLOBS COUNT: \(Constants.Data.userBlobs.count)")
                
                // Call the parent VC to remove the current VC from the stack
                if let parentVC = self.blobAddViewDelegate {
                    parentVC.popViewController()
                }
            }
            return nil
        })
    }
    
    // Upload data to Lambda for transfer to DynamoDB
    func uploadBlobData(blobID: String, blobLat: Double, blobLong: Double, blobMediaID: String, blobMediaType: Int, blobRadius: Double, blobText: String, blobThumbnailID: String, blobTimestamp: Double, blobType: Int, blobTaggedUsers: [String], blobUserID: String) {
        print("SENDING DATA TO LAMBDA")
        
        // Create some JSON to send the Blob data
        let json: NSDictionary = [
            "blobID"            : blobID
            , "blobLat"         : String(blobLat)
            , "blobLong"        : String(blobLong)
            , "blobMediaID"     : blobMediaID
            , "blobMediaType"   : String(blobMediaType)
            , "blobRadius"      : String(blobRadius)
            , "blobText"        : blobText
            , "blobThumbnailID" : blobThumbnailID
            , "blobTimestamp"   : String(blobTimestamp)
            , "blobType"        : String(blobType)
            , "blobTaggedUsers" : blobTaggedUsers
            , "blobUserID"      : blobUserID
        ]
        print("LAMBDA JSON: \(json)")
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-CreateBlob", JSONObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("SENDING DATA TO LAMBDA ERROR: \(err)")
            } else if (response != nil) {
                print("SENDING DATA TO LAMDA RESPONSE: \(response)")
            }
            
        })
    }
    
}
