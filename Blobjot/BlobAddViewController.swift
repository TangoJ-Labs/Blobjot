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
    func createBlobOnMap(_ blobCenter: CLLocationCoordinate2D, blobRadius: Double, blobType: Constants.BlobTypes, blobTitle: String)
}

class BlobAddViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GMSMapViewDelegate, BlobAddTypeViewControllerDelegate, BlobAddMediaViewControllerDelegate, BlobAddPeopleViewControllerDelegate, AWSRequestDelegate {
    
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var blobAddViewDelegate: BlobAddViewControllerDelegate?
    
    var rightButtonItem: UIBarButtonItem!
    
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
    var blobType = Constants.BlobTypes.temporary
//    var blobText: String?
    var blobThumbnail: UIImage?
    var blobImage: UIImage?
//    var blobUserTags = [String]()
    var blobMediaType = 0
    
    var randomMediaID: String?
    var usableMediaID: String = "na"
    var uploadImageFilePath: String?
    
    var blobVideoUrl: URL?
    var uploadVideoFilePath: String?
    var uploadThumbnailFilePath: String!
    
    var selectedOneOrMorePeople: Bool = false
    var sendAttempted: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and set the Nav Bar right button here, and not in the parent VC because this View Controller needs
        // to call this method so that it can pass local variables
        rightButtonItem = UIBarButtonItem(title: "Send",
                                              style: UIBarButtonItemStyle.plain,
                                              target: self,
                                              action: #selector(self.sendBlobAndPopViewController(_:)))
        rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
        self.navigationItem.setRightBarButton(rightButtonItem, animated: true)
        
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
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
//        navBarHeight = self.navigationController?.navigationBar.frame.height
        navBarHeight = 44
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: statusBarHeight + navBarHeight - viewFrameY, width: self.view.frame.width, height: self.view.frame.height - statusBarHeight - navBarHeight + viewFrameY))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        // Add the Page View container and controller at the top of the view, but under the nav bar and search bar
        pageViewContainer = UIView(frame: CGRect(x: 0, y: 0 - viewFrameY, width: viewContainer.frame.width, height: viewContainer.frame.height - 10 - viewContainer.frame.width))
        viewContainer.addSubview(pageViewContainer)
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([viewControllers.first!], direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion: nil)
        pageViewContainer.addSubview(pageViewController.view)
        
        // Add a page controller (dots indicating the currently viewed page) under the page viewer
        pageControl = UIPageControl(frame: CGRect(x: 0, y: viewContainer.frame.height - 10 - viewContainer.frame.width, width: viewContainer.frame.width, height: 10))
        pageControl.numberOfPages = viewControllers.count
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.lightGray
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = Constants.Colors.colorPurple
        viewContainer.addSubview(pageControl)
        
        // Add the Map View under the page controller, and extend it to the bottom of the view
        // The Map View should be on the bottom of the view so that if the keyboard is opened, it covers the Map View
        // and not the Page Viewer (which is what needs to use the keyboard)
        self.mapZoom = UtilityFunctions().mapZoomForBlobSize(Float(self.blobRadius))
        let camera = GMSCameraPosition.camera(withLatitude: blobCoords.latitude, longitude: blobCoords.longitude, zoom: self.mapZoom)
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: viewContainer.frame.height - viewContainer.frame.width, width: viewContainer.frame.width, height: viewContainer.frame.width), camera: camera)
        mapView.delegate = self
        mapView.mapType = kGMSTypeNormal
        mapView.isIndoorEnabled = true
        mapView.isMyLocationEnabled = true
        do
        {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json")
            {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }
            else
            {
                NSLog("Unable to find style.json")
            }
        }
        catch
        {
            NSLog("The style definition could not be loaded: \(error)")
        }
        viewContainer.addSubview(mapView)
        
        // Add the viewScreen and loading indicator for use when the Blob is being uploaded
        viewScreen = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewScreen.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        
        viewScreenActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewScreenActivityIndicator.color = UIColor.black
        
        // Set the angle at which the map should be viewed initially
        let desiredAngle = Double(60)
        mapView.animate(toViewingAngle: desiredAngle)
        
        // Using the data passed from the parent VC (the Map View Controller), create a circle on the map where the user created the new Blob
        addCircle = GMSCircle(position: blobCoords, radius: blobRadius)
        addCircle.fillColor = Constants.Colors.blobRed
        addCircle.strokeColor = Constants.Colors.blobRed
        addCircle.strokeWidth = 1
        addCircle.map = mapView
        
        AWSPrepRequest(requestToCall: AWSGetRandomID(randomIdType: "random_media_id"), delegate: self as AWSRequestDelegate).prepRequest()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: PAGE VIEW CONTROLLER - DATA SOURCE METHODS
    
    // The Before and After View Controller delegate methods control the order in which the pages are viewed
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        print("PAGE VIEW CONTROLLER - VC BEFORE VC: \(viewController)")
        
        let index = viewControllers.index(of: viewController)
        if index == nil || index! == 0
        {
            return nil
        }
        else
        {
            return viewControllers[index! - 1]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        print("PAGE VIEW CONTROLLER - VC AFTER VC: \(viewController)")
        
        let index = viewControllers.index(of: viewController)
        if index == nil || index! + 1 == viewControllers.count
        {
            return nil
        }
        else
        {
            return viewControllers[index! + 1]
        }
    }
    
    // Track which page view is about to be viewed and change the Page Control (dots) to highlight the correct dot
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        print("PAGE VIEW CONTROLLER - PENDING VCs: \(pendingViewControllers)")
        
        if let pendingVC = pendingViewControllers.first
        {
            let index = viewControllers.index(of: pendingVC)
            print("PENDING INDEX: \(index)")
            pageControl.currentPage = index!
            
            if index! == 0
            {
                print(vc2.blobTextView.text)
            }
        }
    }
    
    
    // MARK: PAGE VIEW CONTROLLER - DELEGATE METHODS
    // Return how many pages are needed in the Page Viewer
    func presentationCount(for pageViewController: UIPageViewController) -> Int
    {
        return viewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int
    {
        return 0
    }
    
    
    // MARK: IMAGE PICKER DELEGATE METHODS
    // The Image Picker should be instantiated from this View Controller and not the BlobAddMedia VC to properly handle the media references passed from the picker
    
    // Instantiate the Media Picker
    // Be sure to include both Image and Video types as options
    func pickMediaPicker()
    {
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        mediaPicker.mediaTypes = [kUTTypeImage as String] //, kUTTypeMovie as String]
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    // Once the media has been selected, dismiss the Media Picker VC, capture the media location, and take a screenshot (for a movie type)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        print("MEDIA SELECTED IS: \(info.description)")
        
        // Dismiss the Media Picker
        self.dismiss(animated: true, completion: nil)
        
        // Check the media type
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        // If an image, pass the image to the preview in the Media Page and make sure the Video indicator is not showing
        // If a movie, capture the file location, generate a screenshot at the first second of the movie, and pass the screenshot to
        // the preview on the Media Page and show the Video indicator on the Media Page
        // If an image, generate a temporary image and save locally.  Pass this temporary file location to the upload
        if mediaType == "public.image"
        {
            blobMediaType = 1
            
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            {
                // Store the picked image to access when uploading
                blobImage = pickedImage
                
                print("BLOB IMAGE IS: \(blobImage)")
                
                // Save the thumbnail locally
                if let randomMediaID = self.randomMediaID
                {
                    // Save the randomMediaID in the usableMediaID to indicate that an image was added
                    self.usableMediaID = randomMediaID
                    
                    // Create and locally save the mediaImage
                    if let data = UIImagePNGRepresentation(pickedImage)
                    {
                        print("CREATED THUMBNAIL")
                        uploadImageFilePath = NSTemporaryDirectory() + (randomMediaID + ".png")
                        try? data.write(to: URL(fileURLWithPath: uploadImageFilePath!), options: [.atomic])
                    }
                }
                
                // Hide the video indicator since the media is an image
                vc3.videoPlayIndicator.text = ""
            }
        }
        
        // If the blobImage was successfully saved, create a low-quality thumbnail and save it locally
        if let blobImage = self.blobImage
        {
            blobThumbnail = blobImage.resizeWithWidth(Constants.Dim.blobsActiveTableViewContentSize)
            
            // Save the thumbnail locally
            if let randomMediaID = self.randomMediaID
            {
                // Create and locally save the thumbnail
                if let data = UIImagePNGRepresentation(blobThumbnail!)
                {
                    print("CREATED THUMBNAIL")
                    uploadThumbnailFilePath = NSTemporaryDirectory() + (randomMediaID + "_THUMBNAIL_" + ".png")
                    try? data.write(to: URL(fileURLWithPath: uploadThumbnailFilePath), options: [.atomic])
                }
            }
            
            // Show the blobImage in the Media View in the Page View
            vc3.mediaPickerImage.image = blobImage
        }
    }
    
    // If the user cancels picking media, dismiss the Media Picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        print("CANCELLED MEDIA PICKER")
        self.dismiss(animated: true, completion: nil)
    }
    

    
    // MARK: CUSTOM FUNCTIONS
    
    // For the delegate methods called in this View Controller, use a centralized function to change 
    // the Circle color on the Map View and pass down the color indicator changes to the BlobAddType (vc1) View Controller
    func changeMapCircleType(_ type: Constants.BlobTypes)
    {
        print("BLOB ADD VIEW CHANGE MAP CIRCLE TYPE TO: \(type)")
        
        // Save the lastest type for access when uploading
        self.blobType = type
        
        // Set the settings to default before evaluating the type
        var color = Constants().blobColor(.temporary)
        var resetSelectAllMessage = false
        
        // Evaluate the type and mark the correct selection with a check mark and change the circle color
        // Be sure to reset the Select All Message on the User Tag Page View if a specific color is selected
        switch type {
        case .temporary:
            color = Constants().blobColor(.temporary)
            
            vc1.typeContainer1CheckLabel.text = "\u{2713}"
            vc1.typeContainer2CheckLabel.text = ""
            vc1.typeContainer3CheckLabel.text = ""
            
            resetSelectAllMessage = true
            
        case .permanent:
            color = Constants().blobColor(.permanent)
            
            vc1.typeContainer1CheckLabel.text = ""
            vc1.typeContainer2CheckLabel.text = "\u{2713}"
            vc1.typeContainer3CheckLabel.text = ""
            
            resetSelectAllMessage = true
            
        case .public:
            color = Constants().blobColor(.public)
            
            vc1.typeContainer1CheckLabel.text = ""
            vc1.typeContainer2CheckLabel.text = ""
            vc1.typeContainer3CheckLabel.text = ""
            
        case .invisible:
            color = Constants().blobColor(.invisible)
            
            vc1.typeContainer1CheckLabel.text = ""
            vc1.typeContainer2CheckLabel.text = ""
            vc1.typeContainer3CheckLabel.text = "\u{2713}"
            
            resetSelectAllMessage = true
        
        // Default to a Temporary Blob in case of an error
        default:
            color = Constants().blobColor(.temporary)
            
            vc1.typeContainer1CheckLabel.text = "\u{2713}"
            vc1.typeContainer2CheckLabel.text = ""
            vc1.typeContainer3CheckLabel.text = ""
            
            resetSelectAllMessage = true
        }
        
        // If the select all message is marked to be reset, uncheck the Select All box and hide the overlay message
        if resetSelectAllMessage && vc4.selectAllBox != nil
        {
            vc4.selectAll = false
            vc4.selectAllBox.text = ""
            vc4.selectAllMessage.removeFromSuperview()
            vc4.searchBarContainer.addSubview(vc4.searchBar)
        }
        
        // Finally, change the Circle to the selected type color
        addCircle.fillColor = color
        addCircle.strokeColor = color
    }
    
    // Functions from the BlobAddPeopleVC indicating the number of people selected
    // Store the person selected indicator (to allow a user to send or not) and
    // change the color of the "Send" button to show that the Blob can be sent
    func selectedPerson()
    {
        print("SELECTED PERSON - SET SEND BUTTON COLOR")
        self.selectedOneOrMorePeople = true
        rightButtonItem.tintColor = UIColor.white
    }
    func deselectedAllPeople()
    {
        print("DESELECTED ALL PEOPLE - SET SEND BUTTON COLOR")
        self.selectedOneOrMorePeople = false
        rightButtonItem.tintColor = UIColor.lightGray
    }
    
    // The function called by the "Send" button on the Nav Bar
    // Upload the new Blob data to the server and then dismiss the BlobAdd VC from the parent VC (the Map View)
    func sendBlobAndPopViewController(_ sender: UIBarButtonItem)
    {
        print("SEND FILES TO S3 AND DATA TO LAMBDA AND POP VC")
        print("RANDOM ID: \(self.usableMediaID)")
        print("SEND ALREADY ATTEMPTED?: \(self.sendAttempted)")
        print("PEOPLE SELECTED?: \(self.selectedOneOrMorePeople)")
        
        // Ensure that this is the first time the Blob send has been attempted
        // and that at least one person has been selected
        if !self.sendAttempted && self.selectedOneOrMorePeople
        {
            self.sendAttempted = true
            
            // Show the view screen to indicate that the app is working
            viewContainer.addSubview(viewScreen)
            viewContainer.addSubview(viewScreenActivityIndicator)
            viewScreenActivityIndicator.startAnimating()
            
            // Prepare the media and urls for upload
            print("SENDING FILES")
            print("BLOB MEDIA TYPE: \(self.blobMediaType)")
            
            // Calculate the current time to use in dating the Blob
            let nowTime = Date().timeIntervalSince1970
            
            // Set the media key to an image by default - it will change to an .mp4 if it is a video
            let uploadMediaKey = self.usableMediaID + ".png"
            
            // Process the Blob based on its media type
            if self.blobMediaType == 0
            {
                print("PROCESSING NON-MEDIA BLOB")
                
                // NO MEDIA WAS ATTACHED
                if let randomMediaID = self.randomMediaID
                {
                    self.processBlobData(randomMediaID, mediaID: self.usableMediaID, uploadKey: uploadMediaKey, currentTime: nowTime)
                }
            }
            else if self.blobMediaType == 1
            {
                print("PROCESSING PHOTO BLOB")
                // THE MEDIA IS A PHOTO
                
                // If the media is an image, upload using temporary image and delete the temporary image
                // Upload the image to AWS, and upload the Blob data after the file is successfully uploaded
                if let imageFilePath = self.uploadImageFilePath {
                    AWSPrepRequest(requestToCall: AWSUploadMediaToBucket(bucket: Constants.Strings.S3BucketMedia, uploadMediaFilePath: imageFilePath, mediaID: self.usableMediaID, uploadKey: uploadMediaKey, currentTime: nowTime, deleteWhenFinished: true), delegate: self as AWSRequestDelegate).prepRequest()
                }
            }
            
            // Upload the Thumbnail to AWS
            if let thumbnailFilePath = self.uploadThumbnailFilePath
            {
                AWSPrepRequest(requestToCall: AWSUploadMediaToBucket(bucket: Constants.Strings.S3BucketThumbnails, uploadMediaFilePath: thumbnailFilePath, mediaID: self.usableMediaID, uploadKey: uploadMediaKey, currentTime: nowTime, deleteWhenFinished: true), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
    }
    
    func processBlobData(_ blobID: String, mediaID: String, uploadKey: String, currentTime: Double)
    {
        print("PROCESSING BLOB DATA")
        
        // Save the list of tagged users
        var taggedUsers = [String]()
        for selectUser in self.vc4.peopleListSelected
        {
            taggedUsers.append(selectUser.userID)
        }
        
        // Upload the Blob data to Lamda and then DynamoDB
        AWSPrepRequest(requestToCall: AWSUploadBlobData(blobID: blobID, blobLat: self.blobCoords.latitude, blobLong: self.blobCoords.longitude, blobMediaID: uploadKey, blobMediaType: self.blobMediaType, blobRadius: self.blobRadius, blobText: self.vc2.blobTextView.text, blobThumbnailID: mediaID + ".png", blobTimestamp: currentTime, blobType: self.blobType.rawValue, blobTaggedUsers: taggedUsers, blobUserID: Constants.Data.currentUser), delegate: self as AWSRequestDelegate).prepRequest()
        
        print("MAP BLOBS COUNT 1: \(Constants.Data.mapBlobs.count)")
        
        // Create a new Blob locally so that the Circle can immediately be added to the map
        let newBlob = Blob()
        newBlob.blobID = mediaID
        newBlob.blobDatetime = Date(timeIntervalSince1970: currentTime)
        newBlob.blobLat = self.blobCoords.latitude
        newBlob.blobLong = self.blobCoords.longitude
        newBlob.blobRadius = self.blobRadius
        newBlob.blobType = self.blobType
        newBlob.blobUserID = Constants.Data.currentUser
        Constants.Data.userBlobs.append(newBlob)
        
        // Check to see if the logged in user was tagged
        loopTaggedUsers: for person in taggedUsers
        {
            print("CHECKING TAGGED USERS: \(person)")
            // If the logged in user was tagged, add the Blob to the mapBlobs so that it shows on the Map View
            if person == Constants.Data.currentUser
            {
                print("ADDING TO MAP BLOBS")
                Constants.Data.mapBlobs.append(newBlob)
                
                // Call the parent VC to add the new Blob to the map of the Map View
                if let parentVC = self.blobAddViewDelegate {
                    parentVC.createBlobOnMap(CLLocationCoordinate2DMake(self.blobCoords.latitude, self.blobCoords.longitude), blobRadius: self.blobRadius, blobType: self.blobType, blobTitle: mediaID)
                }
                break loopTaggedUsers
            }
        }
        
        // Sort the mapBlobs
        UtilityFunctions().sortMapBlobs()
        
        print("MAP BLOBS COUNT 2: \(Constants.Data.mapBlobs.count)")
        print("USER BLOBS COUNT: \(Constants.Data.userBlobs.count)")
    }
    
    func popVC()
    {
        // Call the parent VC to remove the current VC from the stack
        if let parentVC = self.blobAddViewDelegate
        {
            parentVC.popViewController()
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("BAVC - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case let awsGetRandomID as AWSGetRandomID:
                    if success
                    {
                        // Refresh the user image if it exists
                        if let randomID = awsGetRandomID.randomID
                        {
                            self.randomMediaID = randomID
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsUploadMediaToBucket as AWSUploadMediaToBucket:
                    if success
                    {
                        // If the media file was successfully updated, save the Blob data to AWS
                        // and then add the Blob locally (into User Blobs and Map Blobs, if the current user was tagged)
                        // Do this inside this if statement otherwise the Blob will be added twice (the upload Media method
                        // is used for the thumbnail too
                        if awsUploadMediaToBucket.bucket == Constants.Strings.S3BucketMedia {
                            self.processBlobData(awsUploadMediaToBucket.mediaID, mediaID: awsUploadMediaToBucket.mediaID, uploadKey: awsUploadMediaToBucket.uploadKey, currentTime: awsUploadMediaToBucket.currentTime)
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("On no!", message: "We had a problem uploading your Blob.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                        
                        // Reset the upload view settings to allow another upload attempt
                        self.viewScreen.removeFromSuperview()
                        self.viewScreenActivityIndicator.removeFromSuperview()
                        self.viewScreenActivityIndicator.stopAnimating()
                        self.sendAttempted = false
                    }
                case _ as AWSUploadBlobData:
                    if success
                    {
                        // Remove the current View Controller from the stack
                        self.popVC()
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("On no!", message: "We had a problem uploading your Blob.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                        
                        // Reset the upload view settings to allow another upload attempt
                        self.viewScreen.removeFromSuperview()
                        self.viewScreenActivityIndicator.removeFromSuperview()
                        self.viewScreenActivityIndicator.stopAnimating()
                        self.sendAttempted = false
                    }
                default:
                    print("BAVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }
    
}
