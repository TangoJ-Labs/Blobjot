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
protocol BlobAddViewControllerDelegate
{
    // When called, the parent View Controller dismisses the top VC (should be this one)
    func popViewController()
    
    // Bring this VC back into view, if popped from the stack
    func bringAddBlobViewControllerTopOfStack(_ newVC: Bool)
    
    // The parent VC will hide any activity indicators showing background activity
    func hideBackgroundActivityView(_ refreshBlobs: Bool)
    
    // Used to add the new Blob to the map
    func createBlobOnMap(_ blob: Blob)
}

class BlobAddViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GMSMapViewDelegate, BlobAddTextViewControllerDelegate, BlobAddMediaViewControllerDelegate, AWSRequestDelegate, HoleViewDelegate
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var blobAddViewDelegate: BlobAddViewControllerDelegate?
    
    var rightButtonItem: UIBarButtonItem!
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Declare the view components
    var viewContainer: UIView!
    var pageViewContainer: UIView!
    var pageViewController: UIPageViewController!
    var pageControl: UIPageControl!
    var toggleInvisibleContainer: UIView!
    var toggleInvisibleSwitch: UISwitch!
    var toggleAccessContainer: UIView!
    var toggleAccessSwitch: UISwitch!
    var mapView: GMSMapView!
    
    var toggleMessageBoxAccess: UIView!
    var toggleMessageLabelAccess: UILabel!
    var toggleMessageBoxInvisible: UIView!
    var toggleMessageLabelInvisible: UILabel!
    
    // Set the MessageBox dimensions
    let messageBoxWidth: CGFloat = 120
    let toggleContainerHeight: CGFloat = 30
    
    var viewScreen: UIView!
    var viewScreenActivityIndicator: UIActivityIndicatorView!
    
    // Declare the view controllers that make up the page viewer
    var viewControllers: [UIViewController]!
    var vc1: BlobAddTextViewController!
    var vc2: BlobAddMediaViewController!
    
    // These variables should be passed data from the Map View concerning the Blob created
    var addCircle: GMSCircle!
    var blobCoords: CLLocationCoordinate2D!
    var blobRadius: Double!
    var mapZoom: Float!
    
    // These variables will hold the Blob content created in the Page Views
    var blobThumbnail: UIImage?
    var blobImage: UIImage?
    var blobMediaType = 0
    
    var randomMediaID: String?
    var usableMediaID: String = "na"
    var uploadImageFilePath: String?
    
    var blobVideoUrl: URL?
    var uploadVideoFilePath: String?
    var uploadThumbnailFilePath: String!
    
    // Local property variables
    var blobType = Constants.BlobType.origin
    var blobFeature = Constants.BlobFeature.standard
    var blobAccess = Constants.BlobAccess.standard
    var blobAccount = Constants.BlobAccount.standard
    var blobColor: UIColor!
    var sendAttempted: Bool = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Create and set the Nav Bar right button here, and not in the parent VC because this View Controller needs
        // to call this method so that it can pass local variables
        rightButtonItem = UIBarButtonItem(title: "Send",
                                              style: UIBarButtonItemStyle.plain,
                                              target: self,
                                              action: #selector(self.sendBlob(_:)))
        rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
        self.navigationItem.setRightBarButton(rightButtonItem, animated: true)
        
        // Instantiate and assign delegates for the Page Viewer View Controllers
        vc1 = BlobAddTextViewController()
        vc1.blobAddTextDelegate = self
        vc2 = BlobAddMediaViewController()
        vc2.blobAddMediaDelegate = self
        viewControllers = [vc1, vc2]

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
        
        // Prepare the view container to hold the invisible Blob toggle
        toggleAccessContainer = UIView(frame: CGRect(x: viewContainer.frame.width - 60, y: viewContainer.frame.height + 10 - viewContainer.frame.width, width: 50, height: toggleContainerHeight))
        toggleAccessSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: toggleAccessContainer.frame.width, height: toggleAccessContainer.frame.height))
        toggleAccessSwitch.onTintColor = Constants.Colors.colorBlue
        toggleAccessSwitch.tintColor = Constants.Colors.colorBlue
        toggleAccessContainer.addSubview(toggleAccessSwitch)
        
        // Add the listener for the toggleSwitch
        toggleAccessSwitch.addTarget(self, action: #selector(BlobAddViewController.switchAccessChanged), for: .valueChanged)
        
        // Add a message box for the access toggle
        toggleMessageBoxAccess = UIView(frame: CGRect(x: 0 - messageBoxWidth, y: viewContainer.frame.height + 10 - viewContainer.frame.width, width: messageBoxWidth, height: toggleContainerHeight))
        toggleMessageBoxAccess.layer.cornerRadius = 5
        toggleMessageBoxAccess.backgroundColor = UIColor.white
        toggleMessageBoxAccess.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        toggleMessageBoxAccess.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        toggleMessageBoxAccess.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        toggleMessageBoxAccess.isHidden = true
        
        toggleMessageLabelAccess = UILabel(frame: CGRect(x: 0, y: 0, width: toggleMessageBoxAccess.frame.width, height: toggleMessageBoxAccess.frame.height))
        toggleMessageLabelAccess.text = "Followers Only"
        toggleMessageLabelAccess.textColor = Constants.Colors.colorTextGray
        toggleMessageLabelAccess.textAlignment = .center
        toggleMessageLabelAccess.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        toggleMessageBoxAccess.addSubview(toggleMessageLabelAccess)
        
        // Prepare the view container to hold the invisible Blob toggle
        toggleInvisibleContainer = UIView(frame: CGRect(x: viewContainer.frame.width - 60, y: viewContainer.frame.height + 20 + toggleContainerHeight - viewContainer.frame.width, width: 50, height: toggleContainerHeight))
        toggleInvisibleSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: toggleInvisibleContainer.frame.width, height: toggleInvisibleContainer.frame.height))
        toggleInvisibleSwitch.onTintColor = Constants.Colors.blobGrayOpaque
        toggleInvisibleSwitch.tintColor = Constants.Colors.blobGrayOpaque
        toggleInvisibleContainer.addSubview(toggleInvisibleSwitch)
        
        // Add a message box for the access toggle
        toggleMessageBoxInvisible = UIView(frame: CGRect(x: 0 - messageBoxWidth, y: viewContainer.frame.height + 20 + toggleContainerHeight - viewContainer.frame.width, width: messageBoxWidth, height: toggleContainerHeight))
        toggleMessageBoxInvisible.layer.cornerRadius = 5
        toggleMessageBoxInvisible.backgroundColor = UIColor.white
        toggleMessageBoxInvisible.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        toggleMessageBoxInvisible.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        toggleMessageBoxInvisible.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        toggleMessageBoxInvisible.isHidden = true
        
        toggleMessageLabelInvisible = UILabel(frame: CGRect(x: 0, y: 0, width: toggleMessageBoxInvisible.frame.width, height: toggleMessageBoxInvisible.frame.height))
        toggleMessageLabelInvisible.text = "Invisible Blob"
        toggleMessageLabelInvisible.textColor = Constants.Colors.colorTextGray
        toggleMessageLabelInvisible.textAlignment = .center
        toggleMessageLabelInvisible.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        toggleMessageBoxInvisible.addSubview(toggleMessageLabelInvisible)
        
        // Add the listener for the toggleInvisibleSwitch
        toggleInvisibleSwitch.addTarget(self, action: #selector(BlobAddViewController.switchInvisibleChanged), for: .valueChanged)
        
        // Add the Map View under the page controller, and extend it to the bottom of the view
        // The Map View should be on the bottom of the view so that if the keyboard is opened, it covers the Map View
        // and not the Page Viewer (which is what needs to use the keyboard)
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
                CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "Unable to find style.json")
            }
        }
        catch
        {
            NSLog("The style definition could not be loaded: \(error)")
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
        }
        viewContainer.addSubview(mapView)
        viewContainer.addSubview(toggleAccessContainer)
        viewContainer.addSubview(toggleMessageBoxAccess)
        viewContainer.addSubview(toggleMessageBoxInvisible)
        
        // If the BlobType is a Location Blob, add the toggle for an invisible Blob
        if blobType == Constants.BlobType.location
        {
            viewContainer.addSubview(toggleInvisibleContainer)
        }
        
        // Add the viewScreen and loading indicator for use when the Blob is being uploaded
        viewScreen = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewScreen.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        
        viewScreenActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewScreenActivityIndicator.color = UIColor.black
        
        // Set the angle at which the map should be viewed initially
        let desiredAngle = Double(60)
        mapView.animate(toViewingAngle: desiredAngle)
        
        // Using the data passed from the parent VC (the Map View Controller), create a circle on the map where the user created the new Blob
        blobColor = Constants().blobColor(blobType, blobFeature: blobFeature, blobAccess: blobAccess, blobAccount: blobAccount, mainMap: false)
        addCircle = GMSCircle(position: blobCoords, radius: blobRadius)
        addCircle.fillColor = blobColor
        addCircle.strokeColor = blobColor
        addCircle.strokeWidth = 1
        addCircle.map = mapView
        
        // Run the checkContent function to turn the Send button gray
        _ = checkContent()
        
        AWSPrepRequest(requestToCall: AWSGetRandomID(randomIdType: "random_media_id"), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Recall the Tutorial Views data in Core Data.  If it is empty for the current ViewController's tutorial, it has not been seen by the curren user.
        let tutorialViews = CoreDataFunctions().tutorialViewRetrieve()
        print("BAVC: TUTORIAL VIEWS ACCOUNTVIEW: \(tutorialViews.tutorialBlobAddViewDatetime)")
        if tutorialViews.tutorialBlobAddViewDatetime == nil
//        if 2 == 2
        {
            let holeView = HoleView(holeViewPosition: 1, frame: viewContainer.bounds, circleOffsetX: viewContainer.bounds.width - 15, circleOffsetY: 90, circleRadius: 100, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 170, textWidth: 200, textFontSize: 24, text: "Create a new Blob.  Be sure to choose your Blob type.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: HOLE VIEW DELEGATE
    func holeViewRemoved(removingViewAtPosition: Int)
    {
        switch removingViewAtPosition
        {
        case 1:
            let holeView = HoleView(holeViewPosition: 2, frame: viewContainer.bounds, circleOffsetX: viewContainer.bounds.width - 60, circleOffsetY: 87, circleRadius: 40, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 170, textWidth: 200, textFontSize: 24, text: "Remember!  Only Permanent Blobs can be managed and deleted once created.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 2:
            let holeView = HoleView(holeViewPosition: 3, frame: viewContainer.bounds, circleOffsetX: viewContainer.bounds.width / 2, circleOffsetY: 30 - (viewContainer.bounds.width / 2), circleRadius: viewContainer.bounds.width, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 195, textWidth: 200, textFontSize: 24, text: "Swipe left in the content creator to add text, photos, and tag connections.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
            
        default:
            // Record the Tutorial View in Core Data
            let moc = DataController().managedObjectContext
            let tutorialView = NSEntityDescription.insertNewObject(forEntityName: "TutorialViews", into: moc) as! TutorialViews
            tutorialView.setValue(NSDate(), forKey: "tutorialBlobAddViewDatetime")
            CoreDataFunctions().tutorialViewSave(tutorialViews: tutorialView)
        }
    }
    
    // MARK: SWITCH LISTENER METHODS
    func switchAccessChanged()
    {
        print("BAVC - SWITCH ACCESS TOGGLE: \(toggleAccessSwitch.isOn)")
        
        if toggleAccessSwitch.isOn
        {
            // Change the followerOnly indicator
            blobAccess = Constants.BlobAccess.followers
            
            // Show the message
            showMessageBoxAccess()
        }
        else
        {
            // Change the followerOnly indicator
            blobAccess = Constants.BlobAccess.standard
            
            // Hide the message
            hideMessageBoxAccess()
        }
    }
    func switchInvisibleChanged()
    {
        print("BAVC - SWITCH INVISIBLE TOGGLE: \(toggleInvisibleSwitch.isOn)")
        
        if toggleInvisibleSwitch.isOn
        {
            // Change the mapView Blob color
            addCircle.fillColor = Constants.Colors.blobGray
            addCircle.strokeColor = Constants.Colors.blobGray
            
            // Change the BlobType
            blobFeature = Constants.BlobFeature.invisible
            
            // Show the message
            showMessageBoxInvisible()
        }
        else
        {
            // Change the mapView Blob color
            addCircle.fillColor = Constants.Colors.blobYellow
            addCircle.strokeColor = Constants.Colors.blobYellow
            
            // Change the BlobType
            blobFeature = Constants.BlobFeature.standard
            
            // Hide the message
            hideMessageBoxInvisible()
        }
    }
    
    
    // MARK: PAGE VIEW CONTROLLER - DATA SOURCE METHODS
    
    // The Before and After View Controller delegate methods control the order in which the pages are viewed
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
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
        if let pendingVC = pendingViewControllers.first
        {
            let index = viewControllers.index(of: pendingVC)
            pageControl.currentPage = index!
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
                // Store the picked image to access when uploading AND RESIZE IMAGE
//                blobImage = pickedImage
                self.blobImage = pickedImage.cropToBounds(Constants.Settings.imageSizeBlob, height: Constants.Settings.imageSizeBlob)
                
                // Save the thumbnail locally
                if let randomMediaID = self.randomMediaID
                {
                    // Save the randomMediaID in the usableMediaID to indicate that an image was added
                    self.usableMediaID = randomMediaID
                    
                    // Create and locally save the mediaImage
                    if let data = UIImagePNGRepresentation(self.blobImage!)
                    {
                        uploadImageFilePath = NSTemporaryDirectory() + (randomMediaID + ".png")
                        try? data.write(to: URL(fileURLWithPath: uploadImageFilePath!), options: [.atomic])
                    }
                }
                
                // Hide the video indicator since the media is an image
                vc2.videoPlayIndicator.text = ""
            }
        }
        
        // If the blobImage was successfully saved, create a low-quality thumbnail and save it locally
        if let blobImage = self.blobImage
        {
            blobThumbnail = blobImage.cropToBounds(Constants.Settings.imageSizeThumbnail, height: Constants.Settings.imageSizeThumbnail)
            
            // Save the thumbnail locally
            if let randomMediaID = self.randomMediaID
            {
                // Create and locally save the thumbnail
                if let data = UIImagePNGRepresentation(blobThumbnail!)
                {
                    uploadThumbnailFilePath = NSTemporaryDirectory() + (randomMediaID + "_THUMBNAIL_" + ".png")
                    try? data.write(to: URL(fileURLWithPath: uploadThumbnailFilePath), options: [.atomic])
                }
            }
            
            // Show the blobImage in the Media View in the Page View
            vc2.mediaPickerImage.image = blobImage
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // If the user cancels picking media, dismiss the Media Picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.dismiss(animated: true, completion: nil)
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    

    
    // MARK: CUSTOM FUNCTIONS
    
    // Show the messageBoxAccess
    func showMessageBoxAccess()
    {
        self.toggleMessageBoxAccess.isHidden = false
        
        // Add an animation to show and then hide the selectorMessageBox //0 - (self.selectorBoxHeight + 10)
        UIView.animate(withDuration: 0.5, animations:
            {
                self.toggleMessageBoxAccess.frame = CGRect(x: 10, y: self.viewContainer.frame.height + 10 - self.viewContainer.frame.width, width: self.messageBoxWidth, height: self.toggleContainerHeight)
        }, completion: nil)
        
    }
    // Hide the messageBoxAccess
    func hideMessageBoxAccess()
    {
        // Add an animation to show and then hide the selectorMessageBox //0 - (self.selectorBoxHeight + 10)
        UIView.animate(withDuration: 0.5, animations:
            {
                self.toggleMessageBoxAccess.frame = CGRect(x: 0 - self.messageBoxWidth, y: self.viewContainer.frame.height + 10 - self.viewContainer.frame.width, width: self.messageBoxWidth, height: self.toggleContainerHeight)
        }, completion:
            {
                (value: Bool) in
                self.toggleMessageBoxAccess.isHidden = true
        })
    }
    
    // Show the MessageBoxInvisible
    func showMessageBoxInvisible()
    {
        self.toggleMessageBoxInvisible.isHidden = false
        
        // Add an animation to show and then hide the selectorTypeMessageBox
        UIView.animate(withDuration: 0.5, animations:
            {
                self.toggleMessageBoxInvisible.frame = CGRect(x: 10, y: self.viewContainer.frame.height + 20 + self.toggleContainerHeight - self.viewContainer.frame.width, width: self.messageBoxWidth, height: self.toggleContainerHeight)
        }, completion: nil)
    }
    // Hide the MessageBoxInvisible
    func hideMessageBoxInvisible()
    {
        // Add an animation to show and then hide the selectorTypeMessageBox
        UIView.animate(withDuration: 0.5, animations:
            {
                self.toggleMessageBoxInvisible.frame = CGRect(x: 0 - self.messageBoxWidth, y: self.viewContainer.frame.height + 20 + self.toggleContainerHeight - self.viewContainer.frame.width, width: self.messageBoxWidth, height: self.toggleContainerHeight)
        }, completion:
            {
                (value: Bool) in
                self.toggleMessageBoxInvisible.isHidden = true
        })
    }
    
    // Indicate that content has been added (text or media)
    // change the color of the "Send" button to show that the Blob can be sent
    func checkContent() -> Bool
    {
        if (vc1.blobTextView.text != nil && vc1.blobTextView.text != "") || uploadThumbnailFilePath != nil
        {
            rightButtonItem.tintColor = UIColor.white
            return true
        }
        else
        {
            rightButtonItem.tintColor = UIColor.lightGray
            return false
        }
    }
    
    // The function called by the "Send" button on the Nav Bar
    // Upload the new Blob data to the server and then dismiss the BlobAdd VC from the parent VC (the Map View)
    func sendBlob(_ sender: UIBarButtonItem)
    {
        // Ensure that this is the first time the Blob send has been attempted
        // and that at least one person has been selected
        if !self.sendAttempted && checkContent()
        {
            self.sendAttempted = true
            
            // Show the view screen to indicate that the app is working
            viewContainer.addSubview(viewScreen)
            viewContainer.addSubview(viewScreenActivityIndicator)
            viewScreenActivityIndicator.startAnimating()
            
            // Prepare the media and urls for upload
            // Calculate the current time to use in dating the Blob
            let nowTime = Date().timeIntervalSince1970
            
            // Set the media key to an image by default - it will change to an .mp4 if it is a video
            let uploadMediaKey = self.usableMediaID + ".png"
            
            // Process the Blob based on its media type
            if self.blobMediaType == 0
            {
                // NO MEDIA WAS ATTACHED
                if let randomMediaID = self.randomMediaID
                {
                    self.processBlobData(randomMediaID, mediaID: self.usableMediaID, uploadKey: uploadMediaKey, currentTime: nowTime)
                }
            }
            else if self.blobMediaType == 1
            {
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
            
            // Set the global indicator to show that a Blob is currently being uploaded
            Constants.Data.stillSendingBlob = true
//            self.popVC()
        }
    }
    
    func processBlobData(_ blobID: String, mediaID: String, uploadKey: String, currentTime: Double)
    {
//        if let currentUserName = Constants.Data.currentUser.userName
//        {
//            // Upload the Blob data to Lamda and then DynamoDB
//            AWSPrepRequest(requestToCall: AWSUploadBlobData(blobID: blobID, blobLat: self.blobCoords.latitude, blobLong: self.blobCoords.longitude, blobMediaID: uploadKey, blobMediaType: self.blobMediaType, blobRadius: self.blobRadius, blobText: self.vc1.blobTextView.text, blobThumbnailID: mediaID + ".png", blobTimestamp: currentTime, blobType: self.blobType.rawValue, blobFeature: self.blobFeature.rawValue, blobAccess: self.blobAccess.rawValue, blobUserID: Constants.Data.currentUser.userID!, blobUserName: currentUserName), delegate: self as AWSRequestDelegate).prepRequest()
//            
//            // Create a new Blob locally so that the Circle can immediately be added to the map
//            let newBlob = Blob()
//            newBlob.blobID = mediaID
//            newBlob.blobDatetime = Date(timeIntervalSince1970: currentTime)
//            newBlob.blobLat = self.blobCoords.latitude
//            newBlob.blobLong = self.blobCoords.longitude
//            newBlob.blobRadius = self.blobRadius
//            newBlob.blobType = self.blobType
//            newBlob.blobUserID = Constants.Data.currentUser.userID!
//            newBlob.blobText = self.vc1.blobTextView.text
//            if let thumbnailFilePath = self.uploadThumbnailFilePath
//            {
//                newBlob.blobMediaType = 1
//                newBlob.blobThumbnail = UIImage(contentsOfFile: thumbnailFilePath)
//            }
//            else
//            {
//                newBlob.blobMediaType = 0
//            }
//            Constants.Data.userBlobs.append(newBlob)
//            
//            // Add the Blob to the global lists
//            Constants.Data.taggedBlobs.append(newBlob)
//            Constants.Data.mapBlobs.append(newBlob)
//            
//            // A new Blob was added, so sort the global mapBlobs array
//            UtilityFunctions().sortMapBlobs()
//            
//            // Call the parent VC to add the new Blob to the map of the Map View
//            if let parentVC = self.blobAddViewDelegate {
//                parentVC.createBlobOnMap(newBlob)
//            }
//            
//            // Sort the mapBlobs
//            UtilityFunctions().sortMapBlobs()
//        }
//        else
//        {
//            // Try to get the logged in user's FB data again (username is missing)
//            AWSPrepRequest(requestToCall: FBGetUserProfileData(user: Constants.Data.currentUser, downloadImage: true), delegate: self as AWSRequestDelegate).prepRequest()
//        }
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
                        if awsUploadMediaToBucket.bucket == Constants.Strings.S3BucketMedia
                        {
                            self.processBlobData(awsUploadMediaToBucket.mediaID, mediaID: awsUploadMediaToBucket.mediaID, uploadKey: awsUploadMediaToBucket.uploadKey, currentTime: awsUploadMediaToBucket.currentTime)
                        }
                    }
                    else
                    {
                        // Call the parent VC to add the current VC to the stack
                        if let parentVC = self.blobAddViewDelegate
                        {
                            parentVC.bringAddBlobViewControllerTopOfStack(false)
                        }
                        
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
                        
                        print("BAVC - UPLOAD COMPLETED - HIDE MAP AI")
                        Constants.Data.stillSendingBlob = false
                        
                        // Call the parent VC
                        if let parentVC = self.blobAddViewDelegate
                        {
                            // Have the parent VC hide any background activity indicator(s)
                            parentVC.hideBackgroundActivityView(true)
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
                default:
                    print("BAVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }
    
}
