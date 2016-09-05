//
//  MapViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/21/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSLambda
import AWSS3
import FBSDKLoginKit
import GoogleMaps
import MobileCoreServices
import GooglePlacePicker
import UIKit


class MapViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, GMSMapViewDelegate, BlobAddViewControllerDelegate, GMSAutocompleteResultsViewControllerDelegate, AWSMethodsDelegate, FBSDKLoginButtonDelegate, AccountViewControllerDelegate {
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // The views to hold major components of the view controller
    var viewContainer: UIView!
    var statusBarView: UIView!
    var mapView: GMSMapView!
    
    // The view components for adding a view Blob
    var selectorCircle: UIView!
    var selectorSlider: UISlider!
    
    // The search bar will be used to search Blobs on the map
    var searchBarContainer: UIView!
    var searchBar: UISearchBar!
    var searchBarExitView: UIView!
    var searchBarExitLabel: UILabel!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    
    // The preview container will display a preview message for the Blob content
    var previewContainer: UIView!
    var previewTimeLabel: UILabel!
    var previewUserNameLabel: UILabel!
    var previewUserNameActivityIndicator: UIActivityIndicatorView!
    var previewUserImageView: UIImageView!
    var previewUserImageActivityIndicator: UIActivityIndicatorView!
    var previewBlobTypeIndicator: UIView!
    var previewTextBox: UILabel!
    var previewThumbnailView: UIImageView!
    var previewThumbnailActivityIndicator: UIActivityIndicatorView!
    
    // The location blob collection view will show which Blobs are currently in range
    var locationBlobsCollectionViewContainer: UIView!
    var locationBlobsCollectionView: UICollectionView!
    var locationBlobsCVLayout: UICollectionViewFlowLayout!
    
    // The navigation buttons to show other view controllers
    var buttonAdd: UIView!
    var buttonAddImage: UILabel!
    var buttonCancelAdd: UIView!
    var buttonCancelAddImage: UILabel!
    var buttonSearchView: UIView!
    var buttonSearchViewImage: UILabel!
    var buttonListView: UIView!
    var buttonListViewImage: UILabel!
    var buttonAccountView: UIView!
    var buttonAccountViewImage: UILabel!
    var buttonTrackUser: UIView!
    var buttonTrackUserImage: UILabel!
    var buttonRefreshMap: UIView!
    var buttonRefreshMapImage: UILabel!
    
    var accuracyLabel: UILabel!
    var loginScreen: UIView!
    var loginBox: UIView!
    var fbLoginButton: FBSDKLoginButton!
    var loginActivityIndicator: UIActivityIndicatorView!
    var loginProcessLabel: UILabel!
    
    // The tap gestures for buttons and other interactive components
    var searchExitTapGesture: UITapGestureRecognizer!
    var accountTapGesture: UITapGestureRecognizer!
    var buttonAddTapGesture: UITapGestureRecognizer!
    var buttonCancelAddTapGesture: UITapGestureRecognizer!
    var buttonSearchTapGesture: UITapGestureRecognizer!
    var buttonListTapGesture: UITapGestureRecognizer!
    var buttonProfileTapGesture: UITapGestureRecognizer!
    var buttonTrackUserTapGesture: UITapGestureRecognizer!
    var buttonRefreshMapTapGesture: UITapGestureRecognizer!
    
    var previewUserTapGesture: UITapGestureRecognizer!
    var previewContentTapGesture: UITapGestureRecognizer!
    var guideSwipeGestureRight: UISwipeGestureRecognizer!
    var guideSwipeGestureLeft: UISwipeGestureRecognizer!
    
    // Use the same size as the collection view items for the Preview User Image
    let previewUserImageSize = Constants.Dim.mapViewLocationBlobsCVItemSize
    
    // Set the Preview Time Label Width for use with multiple views
    let previewTimeLabelWidth: CGFloat = 100
    
    // View controller variables for temporary user settings and view controls
    
    // The Google Maps Coordinate Object for the current center of the map
    var mapCenter: CLLocationCoordinate2D!
    
    // The local user setting whether or not the user has the map camera tracking and following the user's location
    var userTrackingCamera: Bool = false
    
    // The indicator whether or not the status bar should be hidden
    var statusBarHidden: Bool = false
    
    // The indicator whether or not the search bar is visible
    var searchBarVisible: Bool = false
    
    // The indicator whether the user is adding a Blob (typical buttons are hidden and New Blob slider / circle are showing)
    // This determines how the camera reacts to changes in zoom and which buttons / views are visible
    var addingBlob: Bool = false
    
    // This indicator is true of the user's location accuracy is too high
    // This allows the app to know that the user's location has already been indicated as too high without going back into accuracy range
    var locationInaccurate: Bool = false
    
//    var addCircle = GMSCircle()
    
    // Stores the markers that have been added to the map
    var blobMarkers = [GMSMarker]()
    
    // The Blob shown in the preview box will be assigned for local access
    var previewBlob: Blob?
    
    // The User (Creator) of the Blob shown in the preview box will be assigned for local access
    var previewBlobUser: User?
    
    // Use only once - check when the user's location is first available, and move the map center to that location
    var userLocationInitialSet: Bool = false
    
    // A default Blob User to use with the default Blob
    var defaultBlobUser: User!
    
    // Store the local class variables so that information can be passed from background processes if needed
    var activeBlobsVC: BlobsActiveTableViewController!
    var myBlobsVC: BlobsUserTableViewController!
    var addBlobVC: BlobAddViewController!
    
    // If the user is manually logging in, set the indicator for certain settings
    var newLogin: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("VIEW DID LOAD")
        
        self.edgesForExtendedLayout = UIRectEdge.All
        
        // Create a fake user for the default blob
        defaultBlobUser = User()
        defaultBlobUser.userID = "default"
        defaultBlobUser.userName = "default"
        defaultBlobUser.userImageKey = "default"
        defaultBlobUser.userImage = UIImage(named: "logo.png")
        defaultBlobUser.userStatus = Constants.UserStatusTypes.Connected
        
        // Record the status bar settings to adjust the view if needed
        UIApplication.sharedApplication().statusBarHidden = false
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        print("**************** STATUS BAR HEIGHT: \(statusBarHeight)")
        viewFrameY = self.view.frame.minY
        print("**************** VIEW FRAME Y: \(viewFrameY)")
        screenSize = UIScreen.mainScreen().bounds
        
        let vcHeight = screenSize.height - statusBarHeight
        var vcY = statusBarHeight
        if statusBarHeight > 20 {
            vcY = 20
        } else {
//            vcHeight = screenSize.height - statusBarHeight
        }
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcY, width: screenSize.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        print("**************** VIEW CONTAINER FRAME Y: \(viewContainer.frame.minY)")
        
        // Create the login screen, login box, and facebook login button
        // Create the login screen and facebook login button
        loginScreen = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        loginScreen.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        
        loginBox = UIView(frame: CGRect(x: (loginScreen.frame.width / 2) - 140, y: (loginScreen.frame.height / 2) - 40, width: 280, height: 120))
        loginBox.layer.cornerRadius = 5
        loginBox.backgroundColor = Constants.Colors.standardBackground
        
        fbLoginButton = FBSDKLoginButton()
        fbLoginButton.center = CGPointMake(loginBox.frame.width / 2, loginBox.frame.height / 2)
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.delegate = self
        loginBox.addSubview(fbLoginButton)
        
        // Add a loading indicator for the pause showing the "Log out" button after the FBSDK is logged in and before the Account VC loads
        loginActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: loginBox.frame.height / 2 + 15, width: loginBox.frame.width, height: 30))
        loginActivityIndicator.color = UIColor.blackColor()
        loginBox.addSubview(loginActivityIndicator)
        
        loginProcessLabel = UILabel(frame: CGRect(x: 0, y: loginBox.frame.height - 15, width: loginBox.frame.width, height: 14))
        loginProcessLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        loginProcessLabel.text = "Logging you in..."
        loginProcessLabel.textColor = UIColor.blackColor()
        loginProcessLabel.textAlignment = .Center
        
        
        // Create a camera with the default location (if location services are used, this should not be shown for long)
        let camera = GMSCameraPosition.cameraWithLatitude(29.758624, longitude: -95.366795, zoom: 10)
        mapView = GMSMapView.mapWithFrame(viewContainer.bounds, camera: camera)
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 5 + Constants.Dim.mapViewButtonTrackUserSize, right: 0)
        mapView.delegate = self
        mapView.mapType = kGMSTypeNormal
        mapView.indoorEnabled = true
        mapView.myLocationEnabled = true
        viewContainer.addSubview(mapView)
        
        // The temporary location accuracy label
        accuracyLabel = UILabel(frame: CGRect(x: 5, y: mapView.frame.height - 50 - Constants.Dim.mapViewButtonTrackUserSize, width: 100, height: 20))
        accuracyLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        accuracyLabel.text = "NA m"
        accuracyLabel.textColor = UIColor.blackColor()
        accuracyLabel.textAlignment = .Left
        viewContainer.addSubview(accuracyLabel)
        
        // For Adding Blobs, create a default gray circle at the center of the screen with a slider for the user to change the circle radius
        // These components are not initially shown (until the user taps the Add Blob button)
        let circleInitialSize: CGFloat = 100
        selectorCircle = UIView(frame: CGRect(x: (mapView.frame.width / 2) - (circleInitialSize / 2), y: (mapView.frame.height / 2) - (circleInitialSize / 2), width: circleInitialSize, height: circleInitialSize))
        selectorCircle.layer.cornerRadius = circleInitialSize / 2
        selectorCircle.backgroundColor = Constants.Colors.blobGray
        selectorCircle.userInteractionEnabled = false
        
        let sliderHeight: CGFloat = 4
        let sliderCircleSize: Float = 20
        selectorSlider = UISlider(frame: CGRect(x: mapView.frame.width / 2, y: mapView.frame.height / 2 - (sliderHeight / 2), width: mapView.frame.width / 2, height: sliderHeight))
        selectorSlider.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        selectorSlider.minimumValue = sliderCircleSize / 2
        selectorSlider.maximumValue = Float(mapView.frame.width) / 2 - (sliderCircleSize / 2)
        selectorSlider.setValue(Float(circleInitialSize) / 2 - (sliderCircleSize / 2), animated: false)
        selectorSlider.tintColor = Constants.Colors.blobGrayOpaque
        selectorSlider.thumbTintColor = Constants.Colors.blobGrayOpaque
//        let sliderImage = getImageWithColor(Constants.Colors.blobGrayOpaque.colorWithAlphaComponent(0.5), size: CGSize(width: 60, height: 60))
//        selectorSlider.setThumbImage(sliderImage, forState: UIControlState.Normal)
        selectorSlider.addTarget(self, action: #selector(MapViewController.sliderValueDidChange(_:)), forControlEvents: .ValueChanged)
        
        // Add the Add Button in the bottom right corner
        buttonAdd = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAddSize, y: viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonAddSize, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonAdd.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonAdd.backgroundColor = Constants.Colors.colorPurple
        buttonAdd.layer.shadowOffset = CGSizeMake(0, 0.2)
        buttonAdd.layer.shadowOpacity = 0.2
        buttonAdd.layer.shadowRadius = 1.0
        viewContainer.addSubview(buttonAdd)
        
        buttonAddImage = UILabel(frame: CGRect(x: 0, y: 0, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonAddImage.font = UIFont(name: Constants.Strings.fontRegular, size: 30)
        buttonAddImage.text = "\u{002B}"
        buttonAddImage.textColor = UIColor.whiteColor()
        buttonAddImage.textAlignment = .Center
        buttonAdd.addSubview(buttonAddImage)
        
        // Add the Cancel Add Button to show in the bottom right corner to the left of the Add Button
        // Do not show the Cancel Add Button until the user selects Add Button
        buttonCancelAdd = UIView(frame: CGRect(x: viewContainer.frame.width - 10 - Constants.Dim.mapViewButtonAddSize * 2, y: viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonAddSize, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonCancelAdd.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonCancelAdd.backgroundColor = Constants.Colors.colorPurple
        buttonCancelAdd.layer.shadowOffset = CGSizeMake(0, 0.2)
        buttonCancelAdd.layer.shadowOpacity = 0.2
        buttonCancelAdd.layer.shadowRadius = 1.0
        
        buttonCancelAddImage = UILabel(frame: CGRect(x: 0, y: 0, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonCancelAddImage.font = UIFont(name: Constants.Strings.fontRegular, size: 30)
        buttonCancelAddImage.text = "\u{2717}"
        buttonCancelAddImage.textColor = UIColor.whiteColor()
        buttonCancelAddImage.textAlignment = .Center
        buttonCancelAdd.addSubview(buttonCancelAddImage)
        
        // Add the Profile / Account Button in the bottom right corner just above the Add Button
        buttonAccountView = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAccountSize, y: viewContainer.frame.height - 10 - Constants.Dim.mapViewButtonAddSize - Constants.Dim.mapViewButtonAccountSize, width: Constants.Dim.mapViewButtonAccountSize, height: Constants.Dim.mapViewButtonAccountSize))
        buttonAccountView.layer.cornerRadius = Constants.Dim.mapViewButtonAccountSize / 2
        buttonAccountView.backgroundColor = Constants.Colors.colorPurple
        buttonAccountView.layer.shadowOffset = CGSizeMake(0, 0.2)
        buttonAccountView.layer.shadowOpacity = 0.2
        buttonAccountView.layer.shadowRadius = 1.0
        viewContainer.addSubview(buttonAccountView)
        
        buttonAccountViewImage = UILabel(frame: CGRect(x: 1, y: 1, width: Constants.Dim.mapViewButtonAccountSize - 1, height: Constants.Dim.mapViewButtonAccountSize - 1))
        buttonAccountViewImage.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        buttonAccountViewImage.text = "\u{1F464}"
        buttonAccountViewImage.textColor = UIColor.whiteColor()
        buttonAccountViewImage.textAlignment = .Center
        buttonAccountView.addSubview(buttonAccountViewImage)
        
        // Add the "My Location" Tracker Button in the bottom right corner, to the left of the Add Button
        buttonTrackUser = UIView(frame: CGRect(x: 15 + Constants.Dim.mapViewButtonTrackUserSize, y: viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonTrackUserSize, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize))
        buttonTrackUser.layer.cornerRadius = Constants.Dim.mapViewButtonTrackUserSize / 2
        buttonTrackUser.backgroundColor = Constants.Colors.colorPurple
        buttonTrackUser.layer.shadowOffset = CGSizeMake(0, 0.2)
        buttonTrackUser.layer.shadowOpacity = 0.2
        buttonTrackUser.layer.shadowRadius = 1.0
        viewContainer.addSubview(buttonTrackUser)
        
        buttonTrackUserImage = UILabel(frame: CGRect(x: 1, y: 1, width: Constants.Dim.mapViewButtonTrackUserSize - 1, height: Constants.Dim.mapViewButtonTrackUserSize - 1))
        buttonTrackUserImage.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        buttonTrackUserImage.text = "\u{25CE}"
        buttonTrackUserImage.textColor = UIColor.whiteColor()
        buttonTrackUserImage.textAlignment = .Center
        buttonTrackUser.addSubview(buttonTrackUserImage)
        
        // Add the Map Refresh button in the bottom left corner
        buttonRefreshMap = UIView(frame: CGRect(x: 10, y: viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonTrackUserSize, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize))
        buttonRefreshMap.layer.cornerRadius = Constants.Dim.mapViewButtonSearchSize / 2
        buttonRefreshMap.backgroundColor = Constants.Colors.colorPurple
        buttonRefreshMap.layer.shadowOffset = CGSizeMake(0, 0.2)
        buttonRefreshMap.layer.shadowOpacity = 0.2
        buttonRefreshMap.layer.shadowRadius = 1.0
        viewContainer.addSubview(buttonRefreshMap)
        
        buttonRefreshMapImage = UILabel(frame: CGRect(x: 1, y: 1, width: Constants.Dim.mapViewButtonTrackUserSize - 1, height: Constants.Dim.mapViewButtonTrackUserSize - 1))
        buttonRefreshMapImage.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        buttonRefreshMapImage.text = "\u{21BB}"
        buttonRefreshMapImage.textColor = UIColor.whiteColor()
        buttonRefreshMapImage.textAlignment = .Center
        buttonRefreshMap.addSubview(buttonRefreshMapImage)
        
        // The Search Button
        buttonSearchView = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonSearchSize, y: 5, width: Constants.Dim.mapViewButtonSearchSize, height: Constants.Dim.mapViewButtonSearchSize))
        buttonSearchView.layer.cornerRadius = Constants.Dim.mapViewButtonSearchSize / 2
        buttonSearchView.backgroundColor = Constants.Colors.colorPurple
        buttonSearchView.layer.shadowOffset = CGSizeMake(0, 0.2)
        buttonSearchView.layer.shadowOpacity = 0.2
        buttonSearchView.layer.shadowRadius = 1.0
        viewContainer.addSubview(buttonSearchView)
        
        buttonSearchViewImage = UILabel(frame: CGRect(x: 1, y: 1, width: Constants.Dim.mapViewButtonSearchSize - 1, height: Constants.Dim.mapViewButtonSearchSize - 1))
        buttonSearchViewImage.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        buttonSearchViewImage.text = "\u{1F50E}"
        buttonSearchViewImage.textColor = UIColor.whiteColor()
        buttonSearchViewImage.textAlignment = .Center
        buttonSearchView.addSubview(buttonSearchViewImage)
        
        // Add the List Button in the top right corner, just below the search button
        buttonListView = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonListSize, y: 10 + Constants.Dim.mapViewButtonSearchSize, width: Constants.Dim.mapViewButtonListSize, height: Constants.Dim.mapViewButtonListSize))
        buttonListView.layer.cornerRadius = Constants.Dim.mapViewButtonListSize / 2
        buttonListView.backgroundColor = Constants.Colors.colorPurple
        buttonListView.layer.shadowOffset = CGSizeMake(0, 0.2)
        buttonListView.layer.shadowOpacity = 0.2
        buttonListView.layer.shadowRadius = 1.0
        viewContainer.addSubview(buttonListView)
        
        buttonListViewImage = UILabel(frame: CGRect(x: 1, y: 1, width: Constants.Dim.mapViewButtonListSize - 1, height: Constants.Dim.mapViewButtonListSize - 1))
        buttonListViewImage.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        buttonListViewImage.text = "\u{2630}"
        buttonListViewImage.textColor = UIColor.whiteColor()
        buttonListViewImage.textAlignment = .Center
        buttonListView.addSubview(buttonListViewImage)
        
        // Add the Current Location Collection View Container in the top left corner, under the status bar
        // Give it a clear background, and initialize with a height of 0 - the height will be adjusted to the number of cells
        // so that the mapView will not be blocked by the Collection View
        locationBlobsCollectionViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Dim.mapViewLocationBlobsCVCellSize + Constants.Dim.mapViewLocationBlobsCVHighlightAdjustSize, height: 0))
        locationBlobsCollectionViewContainer.backgroundColor = UIColor.clearColor()
        viewContainer.addSubview(locationBlobsCollectionViewContainer)
        
        // Add the Collection View Controller and Subview to the Collection View Container
        locationBlobsCVLayout = UICollectionViewFlowLayout()
        locationBlobsCVLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        locationBlobsCVLayout.headerReferenceSize = CGSize(width: locationBlobsCollectionViewContainer.frame.width, height: 0)
        locationBlobsCVLayout.footerReferenceSize = CGSize(width: locationBlobsCollectionViewContainer.frame.width, height: 0)
        locationBlobsCVLayout.minimumLineSpacing = 0
        locationBlobsCVLayout.itemSize = CGSize(width: Constants.Dim.mapViewLocationBlobsCVCellSize, height: Constants.Dim.mapViewLocationBlobsCVCellSize)
        
        locationBlobsCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: locationBlobsCollectionViewContainer.frame.width, height: locationBlobsCollectionViewContainer.frame.height), collectionViewLayout: locationBlobsCVLayout)
        locationBlobsCollectionView.dataSource = self
        locationBlobsCollectionView.delegate = self
        locationBlobsCollectionView.registerClass(LocationBlobsCollectionViewCell.self, forCellWithReuseIdentifier: Constants.Strings.locationBlobsCellReuseIdentifier)
        locationBlobsCollectionView.backgroundColor = UIColor.clearColor()
        locationBlobsCollectionView.alwaysBounceVertical = true
        locationBlobsCollectionView.showsVerticalScrollIndicator = false
        locationBlobsCollectionViewContainer.addSubview(locationBlobsCollectionView)
        
        // Add the Search Box with the width of the screen and a height so that only the top buttons will by covered when deployed
        // Initialize with the Search Bar Y location as negative so that the Search Bar is not visible
        searchBarContainer = UIView(frame: CGRect(x: 0, y: 0 - Constants.Dim.mapViewSearchBarContainerHeight, width: viewContainer.frame.width, height: Constants.Dim.mapViewSearchBarContainerHeight))
        searchBarContainer.backgroundColor = Constants.Colors.colorStatusBar
        searchBarContainer.layer.shadowOffset = CGSizeMake(0, 0.2)
        searchBarContainer.layer.shadowOpacity = 0.2
        searchBarContainer.layer.shadowRadius = 1.0
        
//        // The actual Search Bar should fill the width of the search bar container minus the width of the search bar exit label (and a margin)
//        searchBar = UISearchBar(frame: CGRect(x: 5, y: (Constants.Dim.mapViewSearchBarContainerHeight / 2) - (Constants.Dim.mapViewSearchBarHeight / 2), width: viewContainer.frame.width - 50, height: Constants.Dim.mapViewSearchBarHeight))
//        searchBar.searchBarStyle = UISearchBarStyle.Minimal
//        searchBarContainer.addSubview(searchBar)
        
        // The search bar exit view and label should be on the right side of the search bar container
        searchBarExitView = UIView(frame: CGRect(x: viewContainer.frame.width - 50, y: 0, width: 50, height: 50))
        searchBarContainer.addSubview(searchBarExitView)
        
        // MARK: SEARCH BAR COMPONENTS
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Add the search bar to the right of the nav bar,
        // use a popover to display the results.
        // Set an explicit size as we don't want to use the entire nav bar.
        searchController?.searchBar.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width - 50, height: searchBarContainer.frame.height)
        searchController?.searchBar.searchBarStyle = UISearchBarStyle.Minimal
        searchController?.searchBar.clipsToBounds = true
        searchBarContainer.addSubview((searchController?.searchBar)!)
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Keep the navigation bar visible.
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.modalPresentationStyle = UIModalPresentationStyle.Popover
        
        
        searchBarExitLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
        searchBarExitLabel.text = "\u{2573}"
        searchBarExitLabel.textColor = UIColor.whiteColor()
        searchBarExitLabel.textAlignment = .Center
        searchBarExitLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 24)
        searchBarExitView.addSubview(searchBarExitLabel)
        
        // Add the Preview Box to be the same size as the Search Box
        // Initialize with the Y location as negative (hide the box) just like the Search Box
        previewContainer = UIView(frame: CGRect(x: 0, y: 0 - Constants.Dim.mapViewPreviewContainerHeight, width: viewContainer.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewContainer.backgroundColor = Constants.Colors.standardBackground
        previewContainer.layer.shadowOffset = CGSizeMake(0, 0.2)
        previewContainer.layer.shadowOpacity = 0.2
        previewContainer.layer.shadowRadius = 1.0
        previewContainer.userInteractionEnabled = true
        viewContainer.addSubview(previewContainer)
        
        // The Preview Box User Image should fill the height of the Preview Box, be circular in shape, and on the left side of the Preview Box
        previewUserImageView = UIImageView(frame: CGRect(x: 5, y: 3, width: previewUserImageSize, height: previewUserImageSize))
        previewUserImageView.layer.cornerRadius = Constants.Dim.mapViewLocationBlobsCVItemSize / 2
        previewUserImageView.contentMode = UIViewContentMode.ScaleAspectFill
        previewUserImageView.clipsToBounds = true
        previewUserImageView.userInteractionEnabled = true
        previewContainer.addSubview(previewUserImageView)
        
        // Add a loading indicator in case the User Image is still downloading when the Preview Box is shown
        // Give it the same size and location as the previewUserImageView
        previewUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 5, y: 5, width: previewUserImageSize, height: previewUserImageSize))
        previewUserImageActivityIndicator.color = UIColor.blackColor()
        previewContainer.addSubview(previewUserImageActivityIndicator)
        
        // The Preview Box User Name Label should start just to the right (5dp margin) of the Preview Box User Image and extend to the Time Label
        previewUserNameLabel = UILabel(frame: CGRect(x: 10 + previewUserImageSize, y: 5, width: previewContainer.frame.width - 60 - Constants.Dim.mapViewPreviewContainerHeight - previewTimeLabelWidth, height: 15))
        previewUserNameLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewUserNameLabel.textColor = Constants.Colors.colorTextGrayLight
        previewUserNameLabel.textAlignment = .Left
        previewUserNameLabel.userInteractionEnabled = false
        previewContainer.addSubview(previewUserNameLabel)
        
        // Add a loading indicator in case the User Name is still downloading when the Preview Box is shown
        // Give it the same size and location as the previewUserNameLabel
        previewUserNameActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 10 + previewUserImageSize, y: 5, width: 25, height: 15))
        previewUserNameActivityIndicator.color = UIColor.blackColor()
        previewContainer.addSubview(previewUserNameActivityIndicator)
        
        // The Preview Box Time Label should start just to the right of the Preview Box User Name and extend to the Thumbnail Image
        // Because the Thumbnail Image is square, you can use the Preview Container Height as a substitute for calculating the Thumbnail Image width
        previewTimeLabel = UILabel(frame: CGRect(x: 10 + previewUserImageSize + previewUserNameLabel.frame.width, y: 5, width: previewTimeLabelWidth, height: 15))
        previewTimeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewTimeLabel.textColor = Constants.Colors.colorTextGrayLight
        previewTimeLabel.textAlignment = .Right
        previewTimeLabel.userInteractionEnabled = false
        previewContainer.addSubview(previewTimeLabel)
        
//        // The Preview Box Type Indicator 
//        previewBlobTypeIndicator = UIView(frame: CGRect(x: 2, y: 2, width: Constants.Dim.mapViewLocationBlobsCVIndicatorSize, height: Constants.Dim.mapViewLocationBlobsCVIndicatorSize))
//        previewBlobTypeIndicator.layer.cornerRadius = Constants.Dim.mapViewLocationBlobsCVIndicatorSize / 2
//        previewContainer.addSubview(previewBlobTypeIndicator)
        
        // The Preview Box Text Box should be a single line of text (UILabel is sufficient), have the same X location and width as the 
        // Preview Box User Name Label, and be placed just below the User Name Label
        previewTextBox = UILabel(frame: CGRect(x: 50, y: 10 + previewUserNameLabel.frame.height, width: previewContainer.frame.width - 60 - Constants.Dim.mapViewPreviewContainerHeight, height: 15))
        previewTextBox.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewTextBox.userInteractionEnabled = false
        previewContainer.addSubview(previewTextBox)
        
        // The Preview Box Thumbnail View should be square and on the right side of the Preview Box
        previewThumbnailView = UIImageView(frame: CGRect(x: previewContainer.frame.width - Constants.Dim.mapViewPreviewContainerHeight, y: 0, width: Constants.Dim.mapViewPreviewContainerHeight, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewThumbnailView.contentMode = UIViewContentMode.ScaleAspectFill
        previewThumbnailView.clipsToBounds = true
        previewThumbnailView.userInteractionEnabled = false
        previewContainer.addSubview(previewThumbnailView)
        
        // Add a loading indicator in case the Thumbnail is still loading when the Preview Box is shown
        // Give it the same size and location as the previewThumbnailView
        previewThumbnailActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: previewContainer.frame.width - Constants.Dim.mapViewPreviewContainerHeight, y: 0, width: Constants.Dim.mapViewPreviewContainerHeight, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewThumbnailActivityIndicator.color = UIColor.blackColor()
        previewContainer.addSubview(previewThumbnailActivityIndicator)
        
        // Add the Status Bar, Top Bar and Search Bar last so that they are placed above (z-index) all other views
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: Constants.Dim.statusBarStandardHeight))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Add the Tap Gesture Recognizers for all Buttons
        accountTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapButtonAccount(_:)))
        accountTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonAccountView.addGestureRecognizer(accountTapGesture)
        
        buttonSearchTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapButtonSearch(_:)))
        buttonSearchTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonSearchView.addGestureRecognizer(buttonSearchTapGesture)
        
        searchExitTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapSearchExit(_:)))
        searchExitTapGesture.numberOfTapsRequired = 1  // add single tap
        searchBarExitView.addGestureRecognizer(searchExitTapGesture)
        
        buttonListTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapListView(_:)))
        buttonListTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonListView.addGestureRecognizer(buttonListTapGesture)
        
        buttonTrackUserTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.toggleTrackUser(_:)))
        buttonTrackUserTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonTrackUser.addGestureRecognizer(buttonTrackUserTapGesture)
        
        buttonRefreshMapTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.refreshMap(_:)))
        buttonRefreshMapTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonRefreshMap.addGestureRecognizer(buttonRefreshMapTapGesture)
        
        buttonAddTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapAddView(_:)))
        buttonAddTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonAdd.addGestureRecognizer(buttonAddTapGesture)
        
        buttonCancelAddTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapCancelAddView(_:)))
        buttonCancelAddTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonCancelAdd.addGestureRecognizer(buttonCancelAddTapGesture)
        
        // Add the Tap Gesture Recognizers for the Preview Box tap gestures
        previewUserTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.previewUserTap(_:)))
        previewUserTapGesture.numberOfTapsRequired = 1  // add single tap
        previewUserImageView.addGestureRecognizer(previewUserTapGesture)
        
        previewContentTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.previewContentTap(_:)))
        previewContentTapGesture.numberOfTapsRequired = 1  // add single tap
        previewContainer.addGestureRecognizer(previewContentTapGesture)
//        previewUserNameLabel.addGestureRecognizer(previewContentTapGesture)
//        previewTimeLabel.addGestureRecognizer(previewContentTapGesture)
//        previewTextBox.addGestureRecognizer(previewContentTapGesture)
//        previewThumbnailView.addGestureRecognizer(previewContentTapGesture)
        
        // Add the Key Path Observers for changes in the user's location and for when the map is moved (the map camera)
        mapView.addObserver(self, forKeyPath: "myLocation", options:NSKeyValueObservingOptions(), context: nil)
        mapView.addObserver(self, forKeyPath: "camera", options:NSKeyValueObservingOptions(), context: nil)
        
        self.checkForUser()
//        refreshMap()
    }
    
    override func viewWillAppear(animated: Bool) {
        print("VIEW WILL APPEAR")
        
//        self.checkForUser()
        refreshMap()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return self.statusBarHidden
    }
    
    // Check if a user is logged in
    func checkForUser() {
        print("FBSDK - CHECK FOR USER")
        print("LOGGED IN USER: \(Constants.Data.currentUser)")
        
        // Show the login screen if no user is logged in
        if Constants.Data.currentUser == "" {
            
            // Check to see if the facebook user id is already in the FBSDK
            if let facebookToken = FBSDKAccessToken.currentAccessToken() {
                
                print("FBSDK USER ID: \(facebookToken.userID)")
                fbGraphRequest(facebookToken.userID)
                
//                // Recall the extra facebook user info and log in the user
//                var facebookID: NSNumber!
//                if let number = Int(facebookToken.userID) {
//                    print("FBSDK FACEBOOK ID INT: \(number)")
//                    facebookID = NSNumber(integer:number)
//                }
//                
//                if facebookID != nil {
//                    print("FBSDK FACEBOOK ID NSNUMBER: \(facebookID)")
//                    
//                }
            } else {
                viewContainer.addSubview(loginScreen)
                loginScreen.addSubview(loginBox)
            }
        }
    }
    
    
    // MARK: SEARCH BAR METHODS
    
    // Capture the Google Places Search Result
    func resultsController(resultsController: GMSAutocompleteResultsViewController, didAutocompleteWithPlace place: GMSPlace) {
        searchController?.active = false
        
        // Show the status bar now that the search view is gone
        UIApplication.sharedApplication().statusBarHidden = false
        self.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Do something with the selected place.
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress)
        print("Place attributions: ", place.attributions)
        print("Place location: ", place.coordinate)
        
        // Use the place coordinate to center the map
        mapCenter = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        mapView.camera = GMSCameraPosition(target: mapCenter, zoom: mapView.camera.zoom, bearing: CLLocationDirection(0), viewingAngle: mapView.camera.viewingAngle)
    }
    
    func resultsController(resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: NSError){
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictionsForResultsController(resultsController: GMSAutocompleteResultsViewController) {
        print("SEARCH CONTROLLER - DID REQUEST")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Hide the status bar while the user searches for the place
        UIApplication.sharedApplication().statusBarHidden = true
        self.statusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func didUpdateAutocompletePredictionsForResultsController(resultsController: GMSAutocompleteResultsViewController) {
        print("SEARCH CONTROLLER - DID UPDATE")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    
    // MARK: TAP GESTURE METHODS
    
    // When the Search Button is tapped, check to see if the search bar is visible
    // If it is not visible, and add it to the view and animate in down into view
    func tapButtonSearch(gesture: UITapGestureRecognizer) {
        if !searchBarVisible {
            searchBarVisible = true
            viewContainer.addSubview(searchBarContainer)
            
            // Add an animation to lower the search button container into view
            UIView.animateWithDuration(0.2, animations: {
                self.searchBarContainer.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewSearchBarContainerHeight)
                }, completion: nil)
        }
    }
    
    // If the Search Box Exit Button is tapped, call the custom function to hide the box
    func tapSearchExit(gesture: UITapGestureRecognizer) {
        print("searchExit Tap Gesture")
        closeSearchBox()
    }
    
    // If the List View Button is tapped, prepare a Navigation Controller and a Tab View Controller
    // Attach the needed Table Views to the Tab View Controller and load the Navigation Controller
    func tapListView(gesture: UITapGestureRecognizer) {
        print("listView Tap Gesture")
        // Ensure that the Preview Screen is hidden
        closePreview()
        
        // Set all map Circles back to default (no highlighting)
        for mBlob in Constants.Data.mapBlobs {
            unhighlightMapCircleForBlob(mBlob)
        }
        
        // Prepare both of the Table View Controller and add Tab Bar Items to them
        activeBlobsVC = BlobsActiveTableViewController()
        let activeBlobsTabBarItem = UITabBarItem(title: "Active Blobs", image: nil, tag: 1)
//        activeBlobsTabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState:.Normal)
        activeBlobsVC.tabBarItem = activeBlobsTabBarItem
        
        myBlobsVC = BlobsUserTableViewController()
        let myBlobsTabBarItem = UITabBarItem(title: "My Blobs", image: nil, tag: 2)
        myBlobsVC.tabBarItem = myBlobsTabBarItem
        
        // Create the Tab Bar Controller to hold the Table View Controllers
        let tabBarController = UITabBarController()
        tabBarController.tabBar.barTintColor = Constants.Colors.colorStatusBar
        tabBarController.tabBar.tintColor = UIColor.whiteColor()
        tabBarController.viewControllers = [activeBlobsVC, myBlobsVC]
        tabBarController.modalTransitionStyle = .FlipHorizontal
        
        // Create the Back Button Item and Title View for the Tab View
        // These settings will be passed up to the assigned Navigation Controller for the Tab View Controller
        let backButtonItem = UIBarButtonItem(title: "< Map",
                                             style: UIBarButtonItemStyle.Plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = UIColor.whiteColor()
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        ncTitleText.text = "Blobs"
        ncTitleText.textColor = UIColor.whiteColor()
        ncTitleText.textAlignment = .Center
        ncTitle.addSubview(ncTitleText)
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        tabBarController.navigationItem.setLeftBarButtonItem(backButtonItem, animated: true)
        tabBarController.navigationItem.titleView = ncTitle
        
        // Create the Navigation Controller, attach the Tab Bar Controller and present the View Controller
        let navController = UINavigationController(rootViewController: tabBarController)
        navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
        self.presentViewController(navController, animated: true, completion: nil)
//        navigationController!.pushViewController(listViewController, animated: true)
    }
    
    // If the Add Button is tapped, check to see if the addingBlob indicator has already been activated (true)
    // If not, hide the normal buttons and just show the buttons needed for the Add Blob action (gray circle, slider, etc.)
    // If so, create a Nav Controller and a new BlobAddViewController and load the Nav Controller and pass the new Blob data
    func tapAddView(gesture: UITapGestureRecognizer) {
        if addingBlob {
            print("addView Tap Gesture - go to Add screen")
            // If the addingBlob indicator is true, the user has already started the Add Blob process and has chosen a location and radius for the Blob
            // Instantiate the BlobAddViewController and a Nav Controller and present the View Controller
            
            addBlobVC = BlobAddViewController()
            addBlobVC.blobAddViewDelegate = self
            // Pass the Blob coordinates and the current map zoom to the new View Controller
            addBlobVC.blobCoords = mapView.camera.target
            addBlobVC.mapZoom = mapView.camera.zoom
            
            // Create a Nav Bar Back Button and Title
            let backButtonItem = UIBarButtonItem(title: "Cancel",
                                                 style: UIBarButtonItemStyle.Plain,
                                                 target: self,
                                                 action: #selector(self.popViewController(_:)))
            backButtonItem.tintColor = UIColor.whiteColor()
            
            let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
            let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
            ncTitleText.text = "Create Blob"
            ncTitleText.textColor = UIColor.whiteColor()
            ncTitleText.textAlignment = .Center
            ncTitle.addSubview(ncTitleText)
            
            // Calculate the slider point location and extrapolate the Blob radius based on the map zoom
            let sliderPoint = CGPoint(x: (mapView.frame.width / 2) + (selectorCircle.frame.width / 2), y: mapView.frame.height / 2)
            let point = self.mapView.projection.coordinateForPoint(sliderPoint)
            
            let mapCenterLocation = CLLocation(latitude: mapView.camera.target.latitude, longitude: mapView.camera.target.longitude)
            let sliderLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
            
            // Pass the Blob Radius to the View Controller
            addBlobVC.blobRadius = mapCenterLocation.distanceFromLocation(sliderLocation)
            addBlobVC.navigationItem.setLeftBarButtonItem(backButtonItem, animated: true)
            addBlobVC.navigationItem.titleView = ncTitle
            
            // Add the View Controller to the Nav Controller and present the Nav Controller
            let navController = UINavigationController(rootViewController: addBlobVC)
            navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
            self.modalPresentationStyle = .Popover
            self.presentViewController(navController, animated: true, completion: nil)
            
            // Add the buttons to the Map View Controller so that they are visible when the user navigates back to the map
            viewContainer.addSubview(locationBlobsCollectionViewContainer)
            viewContainer.addSubview(buttonListView)
            viewContainer.addSubview(buttonAccountView)
            viewContainer.addSubview(buttonTrackUser)
            viewContainer.addSubview(previewContainer)
            
            // Reset the button settings and remove the elements used in the Add Blob Process
            buttonAddImage.text = "\u{002B}"
            buttonCancelAdd.removeFromSuperview()
            selectorCircle.removeFromSuperview()
            selectorSlider.removeFromSuperview()
            
            // Change the add blob indicator back to false efore calling adjustMapViewCamera
            addingBlob = false
            
            // Adjust the Map Camera back to allow the map can be viewed at an angle
            adjustMapViewCamera()
            
        } else {
            // If the addingBlob indicator is false, the user is just starting the Add Blob process, so
            // hide the buttons not needed and show the Cancel Add Button
            print("addView Tap Gesture - add Circle")
            previewContainer.removeFromSuperview()
            locationBlobsCollectionViewContainer.removeFromSuperview()
            buttonListView.removeFromSuperview()
            buttonAccountView.removeFromSuperview()
            buttonTrackUser.removeFromSuperview()
            
            // Change the text of the Add Button to a check mark and add the needed other Views
            buttonAddImage.text = "\u{2713}" //check mark
            viewContainer.addSubview(buttonCancelAdd)
            mapView.addSubview(selectorCircle)
            mapView.addSubview(selectorSlider)
            
            // Change the add blob indicator to true before calling adjustMapViewCamera
            addingBlob = true
            
            // Adjust the Map Camera so that the map cannot be viewed at an angle while adding a new Blob
            // The circle remains a circle when the map is angled, which is not a true representation of the Blob
            // that will be added, so the mapView is kept unangled while a Blob is being added
            adjustMapViewCamera()
        }
    }
    
    // If the Cancel Add Blob button is tapped, show the buttons that were hidden and hide the elements used in the add blob process
    func tapCancelAddView(gesture: UITapGestureRecognizer) {
        viewContainer.addSubview(locationBlobsCollectionViewContainer)
        viewContainer.addSubview(buttonListView)
        viewContainer.addSubview(buttonAccountView)
        viewContainer.addSubview(buttonTrackUser)
        viewContainer.addSubview(previewContainer)
        
        buttonAddImage.text = "\u{002B}" // plus sign
        buttonCancelAdd.removeFromSuperview()
        selectorCircle.removeFromSuperview()
        selectorSlider.removeFromSuperview()
        
        // Change the add blob indicator back to false efore calling adjustMapViewCamera
        addingBlob = false
        
        // Adjust the Map Camera back to allow the map can be viewed at an angle
        adjustMapViewCamera()
    }
    
    // If the Account Button is tapped, create a Nav Bar, AccountViewController, and present the View
    func tapButtonAccount(gesture: UITapGestureRecognizer? = nil) {
        print("TAPPED ACCOUNT BUTTON")
        
        // Create the back button and title for the Nav Bar
        let backButtonItem = UIBarButtonItem(title: "< Map",
                                             style: UIBarButtonItemStyle.Plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = UIColor.whiteColor()
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 100, y: 10, width: 200, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        ncTitleText.text = "Account & Connections"
        ncTitleText.textColor = UIColor.whiteColor()
        ncTitleText.textAlignment = .Center
        ncTitle.addSubview(ncTitleText)
        
        // Instantiate the AccountViewController and the Nav Controller and attach the Nav Bar items to the view controller settings
        let accountVC = AccountViewController()
        let navController = UINavigationController(rootViewController: accountVC)
        accountVC.navigationItem.setLeftBarButtonItem(backButtonItem, animated: true)
        accountVC.navigationItem.titleView = ncTitle
        accountVC.accountViewDelegate = self
        
        // Change the Nav Bar color and present the view
        navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
        self.presentViewController(navController, animated: true, completion: {
            
            // Remove the loginScreen (in case it is showing) so that it does not show when the user returns to the map
            self.loginBox.removeFromSuperview()
            self.loginScreen.removeFromSuperview()
            
            // Since the first attempt to download the map data would have failed if the user was not logged in, refresh it again
            self.refreshMap()
        })
    }
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(sender: UIBarButtonItem) {
        print("pop Back to Map View")
        self.dismissViewControllerAnimated(true, completion: {
        })
    }
    
    // Dismiss the latest View Controller presented from this VC
    func popViewController() {
        print("pop Back to Map View")
        self.dismissViewControllerAnimated(true, completion: {
        })
    }

// *COMPLETE****** Decide how the user should be tracked without making the interface annoying
    // If the Track User button is tapped, the track functionality is toggled
    func toggleTrackUser(gesture: UITapGestureRecognizer) {
        print("TOGGLE TRACK USER")
        // Close the Preview Box - the user is not interacting with the Preview Box anymore
        closePreview()
        
        // Set all map Circles back to default (no highlighting)
        for mBlob in Constants.Data.mapBlobs {
            unhighlightMapCircleForBlob(mBlob)
        }
        
        print("MAP BLOBS: \(Constants.Data.mapBlobs)")
        print("LOCATION BLOBS: \(Constants.Data.locationBlobs)")
        
        // Check to see if the user is already being tracked (toggle functionality)
        if userTrackingCamera {
            userTrackingCamera = false
            
        } else {
            userTrackingCamera = true
            
            // Set the map center coordinate to focus on the user's current location
            // Set the zoom level to match the current map zoom setting
            if let userLocation = mapView.myLocation {
                mapCenter = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
                mapView.camera = GMSCameraPosition(target: mapCenter, zoom: mapView.camera.zoom, bearing: CLLocationDirection(0), viewingAngle: mapView.camera.viewingAngle)
            }
        }
    }
    
    // Reset the MapView and re-download the Blob data
    func refreshMap(gesture: UITapGestureRecognizer? = nil) {
        // PREPARE DATA
        // Request the Map Data for the logged in user
        getMapData()
        print("CALLED MAP DATA")
        
//        // Set the Location Data to hold the Default Blob at minimum to always show the Blobjot logo in the Collection View
//        // Users can click on the Default Blob to get more information about Blobjot
//        Constants.Data.locationBlobs = [Constants.Data.defaultBlob]
    }
    
    // If the Preview Box User Image is tapped, load the people view with the selected person at the top of the list
    func previewUserTap(gesture: UITapGestureRecognizer) {
        print("TAPPED PREVIEW USER")
        
        // Create a back button and title for the Nav Bar
        let backButtonItem = UIBarButtonItem(title: "< Map",
                                             style: UIBarButtonItemStyle.Plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = UIColor.whiteColor()
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        ncTitleText.text = "All People"
        ncTitleText.textColor = UIColor.whiteColor()
        ncTitleText.textAlignment = .Center
        ncTitle.addSubview(ncTitleText)
        
        // Instantiate the PeopleViewController and pass the Preview Blob UserID to the VC
        let peopleVC = PeopleViewController()
        peopleVC.peopleListTopPerson = previewBlob?.blobUserID
        
        // Instantiate the Nav Controller and attach the Nav Bar items to the view controller settings
        let navController = UINavigationController(rootViewController: peopleVC)
        peopleVC.navigationItem.setLeftBarButtonItem(backButtonItem, animated: true)
        peopleVC.navigationItem.titleView = ncTitle
        
        // Change the Nav Bar color and present the view
        navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    // If the Preview Box Content (Text or Thumbnail) is tapped, load the blob view with the selected blob data
    func previewContentTap(gesture: UITapGestureRecognizer) {
        print("TAPPED PREVIEW CONTENT")
        
        // Ensure that the extra blob data has already been requested and that either the blob text or thumbnail is not nil
        if let pBlob = previewBlob {
            print("CONFIRMED PREVIEW BLOB")
            print(pBlob.blobExtraRequested)
            print(pBlob.blobText)
            print(pBlob.blobThumbnailID)
            if (pBlob.blobExtraRequested || pBlob.blobUserID == "default") && (pBlob.blobText != nil || pBlob.blobThumbnailID != nil) {
                // Close the Preview Box - the user is not interacting with the Preview Box anymore
                closePreview()
                
                for mBlob in Constants.Data.mapBlobs {
                    // Set all map Circles back to default (no highlighting)
                    unhighlightMapCircleForBlob(mBlob)
                    
                    // Deselect all mapBlobs (so they don't stick out from the Collection View)
                    mBlob.blobSelected = false
                }
                
                // Create a back button and title for the Nav Bar
                let backButtonItem = UIBarButtonItem(title: "< Map",
                                                     style: UIBarButtonItemStyle.Plain,
                                                     target: self,
                                                     action: #selector(MapViewController.popViewController(_:)))
                backButtonItem.tintColor = UIColor.whiteColor()
                
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
// *COMPLETE********* find username for previewBlob.blobUserID
                // Try to access the locally stored preview Blob User to set the navigation bar title
                if let previewUser = self.previewBlobUser {
                    ncTitleText.text = previewUser.userName
                } else {
                    ncTitleText.text = ""
                }
                
                ncTitleText.textColor = UIColor.whiteColor()
                ncTitleText.textAlignment = .Center
                ncTitle.addSubview(ncTitleText)
                
                // Instantiate the BlobViewController and pass the Preview Blob to the VC
                let blobVC = BlobViewController()
                blobVC.blob = pBlob
                
                // Instantiate the Nav Controller and attach the Nav Bar items to the view controller settings
                let navController = UINavigationController(rootViewController: blobVC)
                blobVC.navigationItem.setLeftBarButtonItem(backButtonItem, animated: true)
                blobVC.navigationItem.titleView = ncTitle
                
                // Change the Nav Bar color and present the view
                navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
                self.presentViewController(navController, animated: true, completion: nil)
            }
        }
    }
    
    
    // KEY-VALUE OBSERVER HANDLERS
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        print("Change at keyPath = \(keyPath) for \(object)")
        
        // Detect if the user's location has changed
        if keyPath == "myLocation" {
            if !Constants.inBackground {
                refreshBlobsForCurrentLocation()
            }
        }
        
        // Detect if the map camera has changed
        // An alternative is the mapView delegate "willMove"
        if keyPath == "camera" {
            print("CAMERA CHANGING: MAPVIEW CAMERA BEFORE: \(mapView.camera)")
        }
    }
    
    // For KEY-VALUE OBSERVER change "myLocation" - can be used elsewhere
    // Reload Blob data based on the user's new location
    func refreshBlobsForCurrentLocation() {
        print("MVC - REFRESHING BLOBS FOR CURRENT LOCATION")
        
        // Check that the user's current location is accessible
        if let userCurrentLocation = mapView.myLocation {
            
            // If the user's initial location has not been centered on the map, do so
            if !userLocationInitialSet {
                let newCamera = GMSCameraPosition.cameraWithLatitude(userCurrentLocation.coordinate.latitude, longitude: userCurrentLocation.coordinate.longitude, zoom: 18)
                mapView.camera = newCamera
                userLocationInitialSet = true
            }
            
            // Determine the user's new coordinates and the range of accuracy around those coordinates
            let userLocation = CLLocation(latitude: userCurrentLocation.coordinate.latitude, longitude: userCurrentLocation.coordinate.longitude)
            let userRangeRadius = userCurrentLocation.horizontalAccuracy
            accuracyLabel.text = String(userRangeRadius) + " m"
            
            // Check to ensure that the location accuracy is reasonable - if too high, do not update data and wait for more accuracy
            if userRangeRadius <= Constants.Settings.locationAccuracyMax {
                // Reset the accuracy indicator
                locationInaccurate = false
                
                // Clear the array of current location Blobs and add the default Blob as the first element
                Constants.Data.locationBlobs = [Constants.Data.defaultBlob]
                
                // Loop through the array of map Blobs to find which Blobs are in range of the user's current location
                for blob in Constants.Data.mapBlobs {
                    
                    // Find the minimum distance possible to the Blob center from the user's location
                    // Determine the raw distance from the Blob center to the user's location
                    // Then subtract the user's location range radius to find the distance from the Blob center to the edge of
                    // the user location range circle closest to the Blob
                    let blobLocation = CLLocation(latitude: blob.blobLat, longitude: blob.blobLong)
                    let userDistanceFromBlobCenter = userLocation.distanceFromLocation(blobLocation)
                    let minUserDistanceFromBlobCenter = userDistanceFromBlobCenter - userRangeRadius
                    
                    // If the minimum distance from the Blob's center to the user is equal to or less than the Blob radius,
                    // request the extra Blob data (Blob Text and/or Blob Media)
                    if minUserDistanceFromBlobCenter <= blob.blobRadius {
                        print("MVC - WITHIN RANGE OF BLOB: \(blob.blobID)")
                        
                        // Ensure that the Blob data has not already been requested
                        // If so, append the Blob to the Location Blob Array
                        if !blob.blobExtraRequested {
                            blob.blobExtraRequested = true
                            print("MVC - REQUESTING BLOB EXTRA")
                            
                            // Only request the extra Blob data if it has not already been requested
//                            getBlobData(blob.blobID)
                            let awsMethods = AWSMethods()
                            awsMethods.awsMethodsDelegate = self
                            awsMethods.getBlobData(blob.blobID)
                            
                            // When downloading Blob data, always request the user data if it does not already exist
                            // Find the correct User Object in the global list
                            var userExists = false
                            loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                                if userObject.userID == blob.blobUserID {
                                    userExists = true
                                    
                                    break loopUserObjectCheck
                                }
                            }
                            // If the user has not been downloaded, request the user and the userImage
                            if !userExists {
//                                self.getSingleUserData(blob.blobUserID)
                                
                                let awsMethods = AWSMethods()
                                awsMethods.awsMethodsDelegate = self
                                awsMethods.getSingleUserData(blob.blobUserID, forPreviewBox: true)
                            }
                        } else {
                            Constants.Data.locationBlobs.append(blob)
                            print("APPENDING BLOB")
                        }
                    } else {
                        // Blob is not within user radius
                        
                        // If the Blob is not in range of the user's current location, but the Blob has already been viewed, then
                        // remove the Blob from the Map Blobs and the Map Circles
                        if blob.blobViewed {
                            
                            // Ensure blobType is not null
                            if let blobType = blob.blobType {
                                
                                // If the Blob Type is not Permanent, remove it from the Map View and Data
                                if blobType != Constants.BlobTypes.Permanent {
                                    //                                        print("DELETING BLOB: \(blob.blobID)")
                                    
                                    // Remove the Blob from the global array of locationBlobs so that it cannot be accessed
                                    loopLocationBlobsCheck: for (index, lBlob) in Constants.Data.locationBlobs.enumerate() {
                                        if lBlob.blobID == blob.blobID {
                                            //                                                print("DELETING LOCATION BLOB: \(lBlob.blobID)")
                                            Constants.Data.locationBlobs.removeAtIndex(index)
                                            
                                            break loopLocationBlobsCheck
                                        }
                                    }
                                    
                                    // Remove the Blob from the global array of mapBlobs so that it cannot be accessed
                                    loopMapBlobsCheck: for (index, mBlob) in Constants.Data.mapBlobs.enumerate() {
                                        if mBlob.blobID == blob.blobID {
                                            //                                                print("DELETING MAP BLOB: \(mBlob.blobID)")
                                            Constants.Data.mapBlobs.removeAtIndex(index)
                                            
                                            break loopMapBlobsCheck
                                        }
                                    }
                                    
                                    // Remove the Blob from the list of mapCircles so that is does not show on the mapView
                                    loopMapCirclesCheck: for (index, circle) in Constants.Data.mapCircles.enumerate() {
                                        if circle.title == blob.blobID {
                                            //                                                print("DELETING CIRCLE: \(circle.title)")
                                            circle.map = nil
                                            Constants.Data.mapCircles.removeAtIndex(index)
                                            
                                            break loopMapCirclesCheck
                                        }
                                    }
                                }
                            }
                        }
                        
                        // If the Blob is not in range of the user's current location, but the Blob's extra data has already been requested,
                        // delete the extra data and indicate that the Blob's extra data has not been requested
                        // If the Blob was deleted in the last IF statement (if viewed and not permanent), then this step is unnecessary
                        if blob.blobExtraRequested {
                            
                            // Remove all of the extra data
                            blob.blobText = nil
                            blob.blobThumbnailID = nil
                            blob.blobMediaType = nil
                            blob.blobMediaID = nil
                            
                            // Indicate that the extra data has not been requested
// *ISSUE ********** If the data has been requested, but not added to the Blob yet, it could be added again after this step, causing bugs
                            blob.blobExtraRequested = false
                        }
                    }
                }
//                print("SORTING LOCATION BLOBS")
//                // Sort the Location Blobs from newest to oldest
//                Constants.Data.locationBlobs.sortInPlace({$0.blobDatetime.timeIntervalSince1970 >  $1.blobDatetime.timeIntervalSince1970})
                
                // Reload the Collection View
                self.locationBlobsCollectionView.performSelectorOnMainThread(#selector(UICollectionView.reloadData), withObject: nil, waitUntilDone: true)
                print("BLOB REFRESH - RELOADED COLLECTION VIEW")
            } else {
                
                // Show a notification that the user's location is too inaccurate to update data
                if !locationInaccurate {
                    if Constants.Data.currentUser != "" {
                        createAlertOkView("Bad Signal!", message: "Your location is too inaccurate to gather data.  Try moving to an area with better reception.")
                    }
                }
                
                // Record that the user's location is inaccurate
                locationInaccurate = true
            }
            
//******************** GMSCameraUpdate methods not being recognized ***********************
            if userTrackingCamera {
//                    let cameraUpdate = GMSCameraUpdate()
//                    cameraUpdate.setTarget = userLocation
//                    mapView.animateWithCameraUpdate(cameraUpdate)
            }
        }
    }
    
    
    // MARK: GOOGLE MAPS DELEGATES
    
    func mapView(mapView: GMSMapView, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        print("You tapped at \(coordinate.latitude), \(coordinate.longitude)")
        
        /*
         1 - Check to see if the tap is within a Blob on the map
                - If so, highlight the Blob on the map
         2 - Check to see if the tapped Blob is one of the locationBlobs
                - If so, show the full Preview AND highlight the userImage in the collection view
                - If not, show the short Preview
        */
        var tappedBlob = false
        for (mbIndex, mBlob) in Constants.Data.mapBlobs.enumerate() {
            print("LOOPING THROUGH MAP BLOBS, CURRENT BLOB INDEX: \(mbIndex)")
            
            // Mark all Blobs as not selected so that any map tap can deselect a currently selected Blob
            mBlob.blobSelected = false
            
            // Ensure that the Blob color and width are set back to it's default setting
            unhighlightMapCircleForBlob(mBlob)
            
            // Calculate the distance from the tap to the center of the Blob
            let tapFromBlobCenterDistance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distanceFromLocation(CLLocation(latitude: mBlob.blobLat, longitude: mBlob.blobLong))
            
            // Check to see if the tap distance from the Blob is equal to or less than the Blob radius
            // If so, highlight the edge of the Blob, show the Preview Box with the Blob
            if tapFromBlobCenterDistance <= mBlob.blobRadius {
                tappedBlob = true
                print("TAPPED MAP BLOB: \(mBlob.blobID)")
                print("TAPPED MAP BLOB TEXT: \(mBlob.blobText)")
                print("TAPPED MAP BLOB THUMBNAIL ID: \(mBlob.blobThumbnailID)")
                
                // Reset the Preview Box
                self.clearPreview()
                
                // Highlight the edge of the Blob
                loopMapCircles: for circle in Constants.Data.mapCircles {
                    if circle.title == mBlob.blobID {
                        circle.strokeColor = Constants.Colors.blobHighlight
                        circle.strokeWidth = 3
                        
                        break loopMapCircles
                    }
                }
                
                // Show the Preview Box with the selected Blob data
                showBlobPreview(mBlob)
                
                // Loop through the Location Blob array to mark all Blobs within tap range
                loopLocationBlobCheck: for lBlob in Constants.Data.locationBlobs {
                    
                    // Mark all Blobs as not selected so that any map tap can deselect a currently selected Blob
                    lBlob.blobSelected = false
                    
                    // Calculate the distance from the tap to the center of the Blob
                    let tapFromBlobCenterDistance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distanceFromLocation(CLLocation(latitude: lBlob.blobLat, longitude: lBlob.blobLong))
                    
                    // Check to see if the tap distance from the Blob is equal to or less than the Blob radius and
                    // if so, indicate that the Blob was tapped (this variable can be used to highlight the Blob within the Collection View)
                    if tapFromBlobCenterDistance <= lBlob.blobRadius {
                        print("TAPPED LOCATION BLOB: \(lBlob.blobID)")
                        lBlob.blobSelected = true
                        
                        break loopLocationBlobCheck
                    }
                }
            }
        }
        // If a Blob was not tapped on the map, close the Preview Box
        if !tappedBlob {
            // Close the Preview Box - the user is not interacting with the Preview Box anymore
            self.closePreview()
        }
        
        // Reload the Collection View to ensure that any deselections also correct the User Image placement in the collection view
        self.locationBlobsCollectionView.performSelectorOnMainThread(#selector(UICollectionView.reloadData), withObject: nil, waitUntilDone: true)
    }
    
    // Called before the map is moved
    func mapView(mapView: GMSMapView, willMove gesture: Bool) {
        print("WILL MOVE: \(mapView.camera)")
//        // Close the Preview Box - the user is not interacting with the Preview Box anymore
//        closePreview()
//        
//        // Set all map Circles back to default (no highlighting)
//        for mBlob in Constants.Data.mapBlobs {
//            unhighlightMapCircleForBlob(mBlob)
//        }
    }
    
    // Called after the map is moved
    func mapView(mapView: GMSMapView, didChangeCameraPosition position: GMSCameraPosition) {
        print("DID CHANGE CAMERA POSITION: \(mapView.camera)")
        // Adjust the Map Camera back to apply the correct camera angle
        adjustMapViewCamera()
        
// *COMPLETE****** Add Map Blobs to Map is a temporary solution to resolve the issue with adding Map Blobs immediately after download
        addMapBlobsToMap()
        
        // Check each circle radius compared to the zoom height and add a marker if the zoom is too low for a Blob size
        for marker in self.blobMarkers {
            marker.map = nil
        }
        self.blobMarkers = [GMSMarker]()
        print("ADD MARKER CHECK - MAP ZOOM: \(Double(mapView.camera.zoom))")
        for blob in Constants.Data.mapBlobs {
            print("ADD MARKER CHECK - BLOB RADIUS: \(blob.blobRadius))")
            
            // Add the marker to the map for the Blob if the radius of the marker is the same or larger than the visible radius of the Blob
            // The equation relating Blob radius to Camera Zoom is:  Radius = Zoom * -30 + 480
            if blob.blobRadius <= (Double(mapView.camera.zoom) * -30) + 480 {
                addMarker(blob)
            }
        }
    }
    
    func addMarker(blob: Blob) {
        let dot = UIImage(named: "circle-small.png")!.imageWithRenderingMode(.AlwaysTemplate)
        let markerView = UIImageView(image: dot)
        markerView.tintColor = Constants().blobColorOpaque(blob.blobType)
        
        let position = CLLocationCoordinate2DMake(blob.blobLat, blob.blobLong)
        let marker = GMSMarker(position: position)
        marker.title = ""
        marker.iconView = markerView
        marker.tracksViewChanges = false
        marker.map = mapView
        self.blobMarkers.append(marker)
    }
    
    func mapView(mapView: GMSMapView, idleAtCameraPosition cameraPosition: GMSCameraPosition) {
        print("IDLE CAMERA MOVE: \(mapView.camera)")
    }
    
    // Adjust the Map Camera settings to allow or disallow angling the camera view
    // If not in the add blob process, angle the map automatically if the zoom is high enough
    func adjustMapViewCamera() {
        if !addingBlob {
            // When not in the add blob process, if the map zoom is 16 or higher, automatically angle the camera
            if mapView.camera.zoom >= 16 && mapView.camera.viewingAngle < 60 {
                let desiredAngle = Double(60)
                mapView.animateToViewingAngle(desiredAngle)
                
            } else if mapView.camera.zoom < 16 && mapView.camera.viewingAngle > 0 {
                // Keep the map from being angled if the zoom is too low
                let desiredAngle = Double(0)
                mapView.animateToViewingAngle(desiredAngle)
            }
        } else {
            // When in the add blob process, do not allow the map camera to angle
            let desiredAngle = Double(0)
            mapView.animateToViewingAngle(desiredAngle)
        }
    }
    
    // Manually set the mapView camera
    func setMapCamera(coords: CLLocationCoordinate2D) {
        self.mapView.camera = GMSCameraPosition(target: coords, zoom: 18, bearing: CLLocationDirection(0), viewingAngle: mapView.camera.viewingAngle)
    }
    
    
    // MARK: SLIDER LISTENERS
    // This is the listener for the slider used in the Add Blob process
    func sliderValueDidChange(sender: UISlider!) {
        print("Slider value changed: \(sender.value)")
        
        // Use the slider value as the new radius for the Add Blob circle
        let circleNewSize: CGFloat = CGFloat(sender.value) * 2
        
        // Resize the Add Blob circle
        selectorCircle.frame = CGRect(x: (mapView.frame.width / 2) - (circleNewSize / 2), y: (mapView.frame.height / 2) - (circleNewSize / 2), width: circleNewSize, height: circleNewSize)
        selectorCircle.layer.cornerRadius = circleNewSize / 2
    }
    
    
    // MARK: UI COLLECTION VIEW DATA SOURCE PROTOCOL
    
    // Number of cells to make in CollectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Cell Count: \(Constants.Data.locationBlobs.count)")
        
        // Resize the Location Blobs Collection View so that it only is tall enough to show all the Blobs
        // Otherwise, the Map View would be blocked by the Collection View and not allow touch responses
        
        // Calculate the height of all the cells together (multiplied by the number of Blobs)
        let maxCVHeight = Constants.Dim.mapViewLocationBlobsCVCellSize * CGFloat(Constants.Data.locationBlobs.count)
        // Determine the height of the viewContainer
        var cvHeight = viewContainer.frame.height
        // If the max height of all Blob cells together is less than the View Container height, then use the smaller height (the total cell(s) height)
        if maxCVHeight < cvHeight {
            cvHeight = maxCVHeight
        }
        locationBlobsCollectionViewContainer.frame.size.height = cvHeight
        locationBlobsCollectionView.frame.size.height = cvHeight
        
        return Constants.Data.locationBlobs.count
    }
    
    //    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    //        return CGSizeMake(Constants.Dim.mapViewLocationBlobsCVCellSize, Constants.Dim.mapViewLocationBlobsCVCellSize)
    //    }
    
    //    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    //        return CGSizeMake(viewContainer.frame.width, 100)
    //    }
    
    // Create cells for CollectionView
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("CELL \(indexPath.row): IN COLLECTION VIEW INDEX PATH: \(indexPath.row)")
        
        // Create reference to CollectionView cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.Strings.locationBlobsCellReuseIdentifier, forIndexPath: indexPath) as! LocationBlobsCollectionViewCell
        
        // Reset the needed views and start the indicator animation
        cell.userImage.image = nil
        cell.userImageActivityIndicator.startAnimating()
        
        // When the Blob is indicated as selected (blobSelected), the User Image is moved 10dp to the right (see below)
        // Reset the User Image location for all Blobs in case the Blob is no longer selected
        cell.userImageContainer.frame = CGRect(x: 5, y: 5, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize)
        
        
        // If the cell is the first one, it is the default blob, so show the Blobjot logo
        if indexPath.row > 0 {
            
            // Add the associated User Image to the User Image View
            if let userID = Constants.Data.locationBlobs[indexPath.row].blobUserID {
                
                // Find the correct User Object in the global list and assign the User Image, if it exists
                loopUserObjectCheck: for userObject in Constants.Data.userObjects {
                    if userObject.userID == userID {
                        if userObject.userImage != nil {
                            cell.userImage.image = userObject.userImage
                            cell.userImageActivityIndicator.stopAnimating()
                        }
                        
                        break loopUserObjectCheck
                    }
                }
            }
        } else {
            cell.userImage.image = UIImage(named: "logo.png")
            cell.userImageActivityIndicator.stopAnimating()
        }
        
        // Check to see if the Blob has been selected, and move the User Image to the right
        if Constants.Data.locationBlobs[indexPath.row].blobSelected {
            cell.userImageContainer.frame = CGRect(x: 5 + Constants.Dim.mapViewLocationBlobsCVHighlightAdjustSize, y: 5, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize)
        }
        
        return cell
    }
    
    
    // MARK: UI COLLECTION VIEW DELEGATE PROTOCOL
    
    // Cell Selection Blob
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("You selected cell #\(indexPath.item)!")
        // Close the Search Box - the user is not interacting with this feature anymore
        closeSearchBox()
        
        // Clear the Preview Box for new Blob data
        clearPreview()
        
        // Loop through the Map Blobs, reset the Map Circles' borders, find the matching Location Blob and highlight its border
        // Do NOT break the Map Blobs loop early.  All Map Blobs should be checked and corresponding Map Circle's border reset
        for (mbIndex, mBlob) in Constants.Data.mapBlobs.enumerate() {
            print("LOOPING THROUGH MAP BLOBS, CURRENT BLOB INDEX: \(mbIndex)")
            mBlob.blobSelected = false
            
            // Reset the border for the Map Circle that matches the Map Blob
            unhighlightMapCircleForBlob(mBlob)
            
            // Check whether the current Map Blob matches the Location Blob at the selected index
            // If so, find the Map Circle that matches the current Map Blob and highlight that Map Circle's border
            if mBlob.blobID == Constants.Data.locationBlobs[indexPath.row].blobID {
                mBlob.blobSelected = true
                
                // Reload the Collection View
                self.locationBlobsCollectionView.performSelectorOnMainThread(#selector(UICollectionView.reloadData), withObject: nil, waitUntilDone: true)
                
                loopMapCircles: for circle in Constants.Data.mapCircles {
                    if circle.title == mBlob.blobID {
                        circle.strokeColor = Constants.Colors.blobHighlight
                        circle.strokeWidth = 3
                        
                        break loopMapCircles
                    }
                }
            }
        }
        
        // Call the function to prepare and show the Preview Box using the data from the Location Blob at the selected index
        showBlobPreview(Constants.Data.locationBlobs[indexPath.row])
    }
    
    // Cell Touch Blob
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        print("Cell #\(indexPath.item) touch blob.")
    }
    
    // Cell Touch Release Blob
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
    }
    
    
    // MARK: FBSDK METHODS
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if ((error) != nil) {
            print("FBSDK ERROR: \(error)")
        }
        else if result.isCancelled {
            print("FBSDK IS CANCELLED: \(result.description)")
        }
        else {
            print("FBSDK COMPLETED WITH PERMISSIONS: \(result.grantedPermissions)")
            print("FBSDK USER ID: \(result.token.userID)")
            
            // Show the logging in indicator and label
            loginActivityIndicator.startAnimating()
            loginBox.addSubview(loginProcessLabel)
            
            // Set the new login indicator for certain settings
            self.newLogin = true
            
            // Authenticate the user in AWS Cognito
//            Constants.credentialsProvider.logins = [AWSIdentityProviderFacebook: result.token.tokenString]
            
            let customProviderManager = CustomIdentityProvider(tokens: [AWSIdentityProviderFacebook: result.token.tokenString])
            Constants.credentialsProvider = AWSCognitoCredentialsProvider(
                regionType: Constants.Strings.aws_region
                , identityPoolId: Constants.Strings.aws_cognitoIdentityPoolId
                , identityProviderManager: customProviderManager
            )
            
            
            // Retrieve your Amazon Cognito ID
            Constants.credentialsProvider.getIdentityId().continueWithBlock { (task: AWSTask!) -> AnyObject! in
                if (task.error != nil) {
                    print("AWS COGNITO GET IDENTITY ID - ERROR: " + task.error!.localizedDescription)
                } else {
                    // the task result will contain the identity id
                    let cognitoId = task.result
                    print("AWS COGNITO GET IDENTITY ID - AWS COGNITO ID: \(cognitoId)")
                    print("AWS COGNITO GET IDENTITY ID - CHECK IDENTITY ID: \(Constants.credentialsProvider.identityId)")
                    
                    // Request extra facebook data for the user ON THE MAIN THREAD
                    dispatch_async(dispatch_get_main_queue(), {
                        self.fbGraphRequest(result.token.userID)
                        print("FBSDK - REQUESTED ADDITIONAL USER INFO")
                    });
                }
                return nil
            }
        }
    }
    
    func fbGraphRequest(facebookID: String) {
        print("FBSDK - MAKING GRAPH REQUEST")
        let fbRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, picture"]) //parameters: ["fields": "id,email,name,picture"])
        print("FBSDK - MAKING GRAPH CALL")
        fbRequest.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            
            if error != nil {
                print("FBSDK - Error Getting Info \(error)")
                
            } else {
                print("FBSDK - User Info : \(result)")
                print("FBSDK - USER NAME : \(result["name"])")
                print("FBSDK - IMAGE URL : \(result["picture"]!["data"]!["url"])")
                
                if let facebookName = result["name"] {
                    print("FBSDK - FACEBOOK NAME: \(facebookName)")
                    
                    var facebookImageUrl = "none"
                    if let fUrl = result["picture"]?["data"]?["url"] {
                        print("FBSDK - GOT fURL")
                        facebookImageUrl = fUrl!
                    }
                    print("FBSDK - FACEBOOK URL: \(facebookImageUrl)")
                    
                    self.loginUser(facebookID, facebookName: (facebookName! as String), facebookThumbnailUrl: facebookImageUrl)
                }
            }
        }
    }
    
    func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
        print("FBSDK WILL LOG IN: \(loginButton)")
        return true
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("FBSDK DID LOG OUT: \(loginButton)")
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    // Check to see if the Search Bar is visible, and if so animate the container to hide it behind the Status Bar
    // Once the animation completes, remove the Search Bar Container from the view container
    func closeSearchBox() {
        if searchBarVisible {
            searchBarVisible = false
            
            // Add an animation to raise the search button container out of view
            UIView.animateWithDuration(0.2, animations: {
                self.searchBarContainer.frame = CGRect(x: 0, y: 0 - Constants.Dim.mapViewSearchBarContainerHeight, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewSearchBarContainerHeight)
                self.buttonSearchView.layer.shadowOffset = CGSizeMake(0, 0.0)
                self.buttonSearchView.layer.shadowOpacity = 0.2
                self.buttonSearchView.layer.shadowRadius = 0.0
                }, completion: {
                    (value: Bool) in
                    self.buttonSearchView.layer.shadowOffset = CGSizeMake(0, 0.2)
                    self.buttonSearchView.layer.shadowOpacity = 0.2
                    self.buttonSearchView.layer.shadowRadius = 1.0
                    
                    // Remove the Search Box from the view container so that a flip animation to show a new view controller
                    // does not show the Search Box above the Status Bar
                    self.searchBarContainer.removeFromSuperview()
            })
        }
    }
    
    // Check to see if the Preview Box is low enough to be visible
    // If so, animate the raising of the Preview Box out of view
    func closePreview() {
        //Stop animating the activity indicators
        previewThumbnailActivityIndicator.stopAnimating()
        previewUserImageActivityIndicator.stopAnimating()
        previewUserNameActivityIndicator.stopAnimating()
        
        if previewContainer.frame.minY > -45 {
            
            // Add an animation to raise the preview container out of view
            UIView.animateWithDuration(0.2, animations: {
                self.previewContainer.frame = CGRect(x: 0, y: 0 - Constants.Dim.mapViewPreviewContainerHeight, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight)
                }, completion: {
                    (value: Bool) in
                    self.clearPreview()
            })
        }
    }
    
    // Reset all Preview Box settings and values
    func clearPreview() {
        self.previewThumbnailView.image = nil
        self.previewTextBox.text = nil
        self.previewUserNameLabel.text = nil
        self.previewTimeLabel.text = nil
        
        self.previewTimeLabel.frame = CGRect(x: 10 + self.previewUserImageSize + self.previewUserNameLabel.frame.width, y: 5, width: self.previewTimeLabelWidth, height: 15)
        self.previewTextBox.frame = CGRect(x: 50, y: 10 + previewUserNameLabel.frame.height, width: previewContainer.frame.width - 60 - Constants.Dim.mapViewPreviewContainerHeight, height: 15)
        
        //Stop animating the activity indicators
        self.previewThumbnailActivityIndicator.stopAnimating()
        self.previewUserImageActivityIndicator.stopAnimating()
        self.previewUserNameActivityIndicator.stopAnimating()
    }
    
    // If the preview Blob user data has not yet been downloaded, call this method to refresh the user data in the preview
    func refreshPreviewUserData(user: User) {
        
        // Refresh the User Name
        self.previewUserNameLabel.text = user.userName
        self.previewUserNameActivityIndicator.stopAnimating()
        
        // Refresh the User Image, if it exists
        if user.userImage != nil {
            self.previewUserImageView.image = user.userImage
            self.previewUserImageActivityIndicator.stopAnimating()
        }
    }
    
    // Add Blob data to the Preview Box elements and animate the Preview Box lowering into view
    func showBlobPreview(blob: Blob) {
        
        //Animate the activity indicator
        self.previewThumbnailActivityIndicator.startAnimating()
        self.previewUserImageActivityIndicator.startAnimating()
        self.previewUserNameActivityIndicator.startAnimating()
        
        // Assign the local previewBlob to the passed blob so that other functions can access the selected blob
        self.previewBlob = blob
        
        // If Blob extra data has been requested, the Blob is in range, so download the Thumbnail,
        // otherwise, move the Blob age and text all the way to the right side of the Preview Box
        if blob.blobExtraRequested {
            print("BLOB EXTRA REQUESTED - CALLING SET THUMBNAIL")
            // Request and set the thumbnail image
            setPreviewThumbnail()
        } else {
            print("BLOB EXTRA NOT REQUESTED")
            //Stop animating the activity indicator (if not already stopped)
            self.previewThumbnailActivityIndicator.stopAnimating()
            
            self.previewTimeLabel.frame = CGRect(x: previewContainer.frame.width - 5 - self.previewTimeLabelWidth, y: 5, width: self.previewTimeLabelWidth, height: 15)
            self.previewTextBox.frame = CGRect(x: 50, y: 10 + previewUserNameLabel.frame.height, width: previewContainer.frame.width - 65, height: 15)
        }
        
        // Check whether the Blob is the default (first) Blob in the Location Blob list
        // Otherwise, find the associated User Image and User Name for the Blob User ID as add them to the proper Preview Box elements
        if blob.blobID == "default" {
            previewUserImageView.image = UIImage(named: "logo.png")
            previewUserNameLabel.text = "Blobjot"
            previewTimeLabel.text = "Since 2016"
            
            // Assign the user to the previewBlobUser
            self.previewBlobUser = defaultBlobUser
            
            //Stop animating the activity indicator
            self.previewThumbnailActivityIndicator.stopAnimating()
            self.previewUserImageActivityIndicator.stopAnimating()
            self.previewUserNameActivityIndicator.stopAnimating()
        } else {
            
            // Check if the user has already been downloaded
            // If a Blob outside the range of the user was clicked, the user may not have already been downloaded
            var userExists = false
            loopUserCheck: for user in Constants.Data.userObjects {
                if user.userID == blob.blobUserID {
                    userExists = true
                    
                    // Assign the user to the previewBlobUser
                    self.previewBlobUser = user
                    
                    // Assign the user's image and username to the preview
                    previewUserNameLabel.text = user.userName
                    self.previewUserNameActivityIndicator.stopAnimating()
                    
                    if user.userImage != nil {
                        previewUserImageView.image = user.userImage
                        self.previewUserImageActivityIndicator.stopAnimating()
                    }
                    else {
//                        self.getUserImage(user.userID, imageKey: user.userImageKey)
                        
                        let awsMethods = AWSMethods()
                        awsMethods.awsMethodsDelegate = self
                        awsMethods.getUserImage(user.userID, imageKey: user.userImageKey)
                    }
                    
                    break loopUserCheck
                }
            }
            // If the user has not been downloaded, request the user and the userImage
            if !userExists {
                let awsMethods = AWSMethods()
                awsMethods.awsMethodsDelegate = self
                awsMethods.getSingleUserData(blob.blobUserID, forPreviewBox: true)
            }
            
            // Set the Preview Time Label to show the age of the Blob
            if let datetime = blob.blobDatetime {
                let stringAge = String(-1 * Int(datetime.timeIntervalSinceNow / 3600)) + " hrs"
                previewTimeLabel.text = stringAge
            }
        }
        
        // Check whether the Blob text has been added to the Blob, and if so, display the text
        // If not, check whether the extra data has already been requested
        // if not, this means the Blob is not (or has not been) in range
        // If it has been requested, but no text exists, do nothing (leave the text area blank)
        if let bText = blob.blobText {
            previewTextBox.textColor = Constants.Colors.colorPreviewTextNormal
            previewTextBox.text = bText
        } else if !blob.blobExtraRequested {
            previewTextBox.textColor = Constants.Colors.colorPreviewTextError
            previewTextBox.text = "This Blob is not in range."
        }
        
        // Add an animation to lower the preview container into view
        UIView.animateWithDuration(0.2, animations: {
            self.previewContainer.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight)
            }, completion: nil)
    }
    
    
    // Loop through the Map Blobs, check if they have already been added as Map Circles, and create a Map Circle if needed
    func addMapBlobsToMap() {
        print("MAP BLOBS COUNT: \(Constants.Data.mapBlobs.count)")
        
        // Loop through Map Blobs and check for corresponding Map Circles
        for addBlob in Constants.Data.mapBlobs {
            var blobExists = false
            loopCircleCheck: for circle in Constants.Data.mapCircles {
                if circle.title == addBlob.blobID {
                    blobExists = true
                    break loopCircleCheck
                }
            }
            
            // If a corresponding Map Circle does not exist, call createBlobOnMap to create a new one
            if !blobExists {
                let blobCenter = CLLocationCoordinate2DMake(addBlob.blobLat, addBlob.blobLong)
                
                // Call local function to create a new Circle and add it to the Map View
                self.createBlobOnMap(blobCenter, blobRadius: addBlob.blobRadius, blobType: addBlob.blobType, blobTitle: addBlob.blobID)
            }
        }

        // ADDED FOR MANUAL LOCATION RELOAD
        // Reload the current location's Blobs to show in the Collection View
        refreshBlobsForCurrentLocation()
    }
    
    // Receive the Blob data, create a new GMSCircle, and add it to the local Map View
    func createBlobOnMap(blobCenter: CLLocationCoordinate2D, blobRadius: Double, blobType: Constants.BlobTypes, blobTitle: String) {
        print("ABOUT TO ADD CIRCLE: \(blobTitle), \(blobCenter), \(blobRadius), \(blobType)")
        
        let addCircle = GMSCircle()
        print("CIRCLE CHECK 1: \(addCircle)")
        addCircle.position = blobCenter
        addCircle.radius = blobRadius
        addCircle.title = blobTitle
        addCircle.fillColor = Constants().blobColor(blobType)
        addCircle.strokeColor = Constants().blobColor(blobType)
        addCircle.strokeWidth = 1
        addCircle.map = self.mapView
        Constants.Data.mapCircles.append(addCircle)
        
//        let path = pathForCoordinate(blobCenter, withMeterRadius: blobRadius)
//        let blob = GMSPolyline(path: path)
//        blob.map = self.mapView
    }
    
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    // Loop through all Map Circles and remove all highlighting (set back to normal)
    func unhighlightMapCircleForBlob(blob: Blob) {
        
        loopMapCircles: for circle in Constants.Data.mapCircles {
            if circle.title == blob.blobID {
                circle.strokeColor = Constants().blobColor(blob.blobType)
                circle.strokeWidth = 1
                
                break loopMapCircles
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
    
    // Set the Preview Box Thumbnail using the locally assigned Preview Blob
    func setPreviewThumbnail() {
        print("SET THUMBNAIL - CHECK 1")
        
        // First check to make sure the Preview Blob was properly assigned
        if let pBlob = self.previewBlob {
            print("SET THUMBNAIL - CHECK 2")
            
            // Use a background thread to loop until the image is available
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                print("SET THUMBNAIL - CHECK 3")
                
                // Look for the correct thumbnail until it is available - it may be downloading still
                // Only check for ten seconds - after that, the download is taking too long
                let startTime: Double = NSDate().timeIntervalSince1970 //fetch starting time
                let loopMaxTime: Double = 10.0
                while self.previewThumbnailView.image == nil && NSDate().timeIntervalSince1970 - startTime < loopMaxTime {
                    print("SET THUMBNAIL - CHECK 4")
                    print("WHILE LOOP RUNNING FOR: \(NSDate().timeIntervalSince1970 - startTime)")
                    
                    // Loop through the BlobThumbnailObjects array
                    for tObject in Constants.Data.blobThumbnailObjects {
                        print("SET THUMBNAIL - CHECK 5")
                        
                        // Check each thumbnail object to see if matches
                        if tObject.blobThumbnailID == pBlob.blobThumbnailID {
                            print("SET THUMBNAIL - CHECK 6")
                            
                            // Check to make sure the thumbnail has already been downloaded
                            if let thumbnailImage = tObject.blobThumbnail {
                                print("SET THUMBNAIL - CHECK 7")
                                
                                // Perform UI changes on the main thread
                                dispatch_async(dispatch_get_main_queue()) {
                                    print("SET THUMBNAIL - CHECK 8")
                                    
                                    // Setthe Preview Thumbnail image
                                    self.previewThumbnailView.image = thumbnailImage
                                    
                                    // Stop animating the activity indicator
                                    self.previewThumbnailActivityIndicator.stopAnimating()
                                    
                                    // Assign the thumbnail image to the previewBlob
                                    self.previewBlob?.blobThumbnail = thumbnailImage
                                }
                                break
                            }
                        }
                    }
                } // The while loop
            }
        }
    }
    
    func pathForCoordinate(coordinate: CLLocationCoordinate2D, withMeterRadius: Double) -> GMSMutablePath {
        let degreesBetweenPoints = 8.0
        
        let path = GMSMutablePath()
        
        // 45 sides
        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
        let distRadians: Double = withMeterRadius / 6371000.0
        let varianceRadians: Double = (withMeterRadius / 10) / 6371000.0
        
        // earth radius in meters
        let centerLatRadians: Double = coordinate.latitude * M_PI / 180
        let centerLonRadians: Double = coordinate.longitude * M_PI / 180
        
        //array to hold all the points
        for index in 0 ..< Int(numberOfPoints) {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * M_PI / 180
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * 180 / M_PI
            let pointLon: Double = pointLonRadians * 180 / M_PI
            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
            path.addCoordinate(point)
        }
        
        return path
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func displayNotification(blob: Blob) {
    }
    
    func refreshCollectionView() {
        
        // Reload the Collection View
        self.locationBlobsCollectionView.performSelectorOnMainThread(#selector(UICollectionView.reloadData), withObject: nil, waitUntilDone: true)
        print("BLOB REFRESH AFTER DOWNLOAD - RELOADED COLLECTION VIEW")
    }
    
    func updateBlobActionTable() {
        if self.activeBlobsVC != nil {
            self.activeBlobsVC.reloadTableView()
        }
    }
    
    func updatePreviewBoxData(user: User) {
        
        // Assign the user to the previewBlobUser
        self.previewBlobUser = user
        
        print("PVC - TRYING TO ADD DOWNLOADED USER: \(user.userName)")
        
        // Set the preview box with the downloaded data
        self.previewUserNameLabel.text = user.userName
        
        // If the new User data is for the same user and the Preview user and the preview User data is nil, refresh the preview box
        if let pBlob = self.previewBlob {
            if pBlob.blobUserID == user.userID && self.previewUserNameLabel.text == nil {
                self.refreshPreviewUserData(user)
            }
        }
    }
    
    
    // MARK: AWS METHODS
    
    // Log in the user or create a new user
    func loginUser(facebookID: String, facebookName: String, facebookThumbnailUrl: String) {
        let json: NSDictionary = ["facebook_id" : facebookID, "facebook_name": facebookName, "facebook_thumbnail_url": facebookThumbnailUrl]
        print("USER LOGIN DATA: \(json)")
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-LoginUser", JSONObject: json, completionHandler: { (responseData, err) -> Void in
            
            if (err != nil) {
                print("LOGIN - ERROR: \(err)")
            } else if (responseData != nil) {
                print("LOGIN - USER RESPONSE: \(responseData)")
                
                // The response will be the userID associated with the facebookID used, save the userID globally
                Constants.Data.currentUser = responseData as! String
                
                if self.newLogin {
                    
                    // Load the account view to show the logged in user
                    self.tapButtonAccount()
                    print("LOGIN - CALLED TAP ACCOUNT")
                    
                    // Hide the logging in indicator and label
                    self.loginActivityIndicator.stopAnimating()
                    self.loginProcessLabel.removeFromSuperview()
                } else {
                    
                    // Since the first attempt to download the map data would have failed if the user was not logged in, refresh it again
                    self.refreshMap()
                }
            }
        })
    }
    
    // The initial request for Map Blob data - called when the View Controller is instantiated
    func getMapData() {
        print("REQUESTING GMD")
        
        // Clear global mapBlobs
        Constants.Data.mapBlobs = [Blob]()
        
        // Create some JSON to send the logged in userID
        let json: NSDictionary = ["user_id" : Constants.Data.currentUser]
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        lambdaInvoker.invokeFunction("Blobjot-GetMapData", JSONObject: json, completionHandler: { (response, err) -> Void in
            
            if (err != nil) {
                print("GET MAP DATA ERROR: \(err)")
                print("GET MAP DATA ERROR CODE: \(err!.code)")
                
                // Process the error codes and alert the user if needed
                if err!.code == 1 && Constants.Data.currentUser != "" {
                    self.createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please refresh the map to try again.")
                }
                
            } else if (response != nil) {
                
                // Convert the response to an array of AnyObjects
                if let newMapBlobs = response as? [AnyObject] {
                    print("MVC-GMD: jsonData: \(newMapBlobs)")
                    print("BLOB COUNT: \(newMapBlobs.count)")
                    
                    // Loop through each AnyObject (Blob) in the array
                    for newBlob in newMapBlobs {
                        print("NEW BLOB: \(newBlob)")
                        
                        // Convert the AnyObject to JSON with keys and AnyObject values
                        // Then convert the AnyObject values to Strings or Numbers depending on their key
                        if let checkBlob = newBlob as? [String: AnyObject] {
                            let blobTimestamp = checkBlob["blobTimestamp"] as! Double
                            let blobDatetime = NSDate(timeIntervalSince1970: blobTimestamp)
                            let blobTypeInt = checkBlob["blobType"] as! Int
                            
                            // Evaluate the blobType Integer received and convert it to the appropriate BlobType Class
                            var blobType: Constants.BlobTypes!
                            switch blobTypeInt {
                                case 1:
                                    blobType = Constants.BlobTypes.Temporary
                                case 2:
                                    blobType = Constants.BlobTypes.Permanent
                                case 3:
                                    blobType = Constants.BlobTypes.Public
                                case 4:
                                    blobType = Constants.BlobTypes.Invisible
                                case 5:
                                    blobType = Constants.BlobTypes.SponsoredTemporary
                                case 6:
                                    blobType = Constants.BlobTypes.SponsoredPermanent
                                default:
                                    blobType = Constants.BlobTypes.Temporary
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
                    
                    // Clear the mapCircles (for when the refresh map method is called)
                    // Each circle must individually have their map nullified, otherwise the mapView will still display the circle
                    for circle in Constants.Data.mapCircles {
                        circle.map = nil
                    }
                    Constants.Data.mapCircles = [GMSCircle]()
                    
                    // Attempt to call the local function to add the Map Blobs to the Map
                    self.addMapBlobsToMap()
                }
            }
            
        })
    }
    
}
