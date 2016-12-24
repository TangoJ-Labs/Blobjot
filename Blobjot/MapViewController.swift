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


class MapViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, GMSMapViewDelegate, BlobAddViewControllerDelegate, GMSAutocompleteResultsViewControllerDelegate, FBSDKLoginButtonDelegate, UITabBarControllerDelegate, AWSRequestDelegate, PeopleViewControllerDelegate, AccountViewControllerDelegate, HoleViewDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // The views to hold major components of the view controller
    var viewContainer: UIView!
    var statusBarView: UIView!
    var mapView: GMSMapView!
    
    // The view components for adding a view Blob
    var selectorMessageBox: UIView!
    var selectorMessageLabel: UILabel!
    var selectorCircle: UIView!
    var selectorSlider: UISlider!
    
    // The search bar will be used to search Blobs on the map
//    var searchBarContainer: UIView!
//    var searchBar: UISearchBar!
//    var searchBarExitView: UIView!
//    var searchBarExitLabel: UILabel!
    
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
    var buttonAddImage: UIImageView!
    var buttonCancelAdd: UIView!
    var buttonCancelAddImage: UIImageView!
//    var buttonSearchView: UIView!
//    var buttonSearchViewImage: UIImageView!
//    var buttonListView: UIView!
//    var buttonListViewImage: UIImageView!
    var buttonTrackUser: UIView!
    var buttonTrackUserImage: UIImageView!
    var buttonRefreshMap: UIView!
    var buttonRefreshMapImage: UIImageView!
    var buttonRefreshMapActivityIndicator: UIActivityIndicatorView!
    var backgroundActivityView: UIView!
    var backgroundActivityIndicator: UIActivityIndicatorView!
    
    var lowAccuracyView: UIView!
    var lowAccuracyLabel: UILabel!
    var accuracyLabel: UILabel!
    
    var loginScreen: UIView!
    var loginBox: UIView!
    var loginButtonContainer: UIView!
    var fbLoginButton: FBSDKLoginButton!
    var loginActivityIndicator: UIActivityIndicatorView!
    var loginProcessLabel: UILabel!
    
    // The tap gestures for buttons and other interactive components
//    var searchExitTapGesture: UITapGestureRecognizer!
    var accountTapGesture: UITapGestureRecognizer!
    var buttonAddTapGesture: UITapGestureRecognizer!
    var buttonCancelAddTapGesture: UITapGestureRecognizer!
//    var buttonSearchTapGesture: UITapGestureRecognizer!
//    var buttonProfileTapGesture: UITapGestureRecognizer!
    var buttonTrackUserTapGesture: UITapGestureRecognizer!
    var buttonRefreshMapTapGesture: UITapGestureRecognizer!
    
    var lowAccuracyViewTapGesture: UITapGestureRecognizer!
    var previewUserTapGesture: UITapGestureRecognizer!
    var previewContentTapGesture: UITapGestureRecognizer!
    var guideSwipeGestureRight: UISwipeGestureRecognizer!
    var guideSwipeGestureLeft: UISwipeGestureRecognizer!
    
    // Use the same size as the collection view items for the Preview User Image
    let previewUserImageSize = Constants.Dim.mapViewLocationBlobsCVItemSize
    
    // Set the Preview Time Label Width for use with multiple views
    let previewTimeLabelWidth: CGFloat = 100
    
    // Set the selectionMessageBox dimensions
    let selectorBoxWidth: CGFloat = 120
    let selectorBoxHeight: CGFloat = 40
    
    // View controller variables for temporary user settings and view controls
    
    // Indicates that map data was requested from AWS, and is still downloading
    var waitingForMapData: Bool = false
    
    // The Google Maps Coordinate Object for the current center of the map and the default Camera
    var mapCenter: CLLocationCoordinate2D!
    var defaultCamera: GMSCameraPosition!
    
    // The local user setting whether or not the user has the map camera tracking and following the user's location
    var userTrackingCamera: Bool = false
    
    // The marker used to show the search pick location
    var searchMarker: GMSMarker?
    
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
    var activeBlobsVC: BlobsActiveTableViewController?
    var blobsVC: BlobsTableViewController?
    var accountVC: AccountViewController?
    var peopleVC: PeopleViewController?
    var addBlobVC: BlobAddViewController?
    var tabBarControllerCustom: UITabBarController?
    
    // If the user is manually logging in, set the indicator for certain settings
    var newLogin: Bool = false
    
    var showLoginScreenBool: Bool = false
    
//    // Create boolean properties to indicate whether the menu buttons are open
//    var menuButtonMapOpen: Bool = false
//    var menuButtonBlobOpen: Bool = false
    
    // Create a local property to hold the child VC
    var blobVC: BlobViewController!
    
    // Track the recent location changes in location and time changed
    var lastLocation: CLLocation?
    var lastLocationTime: Double = Date().timeIntervalSince1970
    var lastBlobjotBlobsLocation: CLLocation?
    
    // Properties for the tutorial
    let tutorialCircle = GMSCircle()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge.all
        
        // Create a fake user for the default blob
        defaultBlobUser = User()
        defaultBlobUser.userID = "default"
        defaultBlobUser.userName = "default"
        defaultBlobUser.userImage = UIImage(named: Constants.Strings.iconStringBlobjotLogo)
        defaultBlobUser.userStatus = Constants.UserStatusTypes.connected
        
        // Record the status bar settings to adjust the view if needed
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = 44.0
        if let navController = self.navigationController
        {
            print("MVC - NAV BAR HEIGHT: \(navController.navigationBar.frame.height)")
            navBarHeight = navController.navigationBar.frame.height
        }
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        let vcHeight = screenSize.height - statusBarHeight - navBarHeight
        var vcY = statusBarHeight + navBarHeight
        if statusBarHeight > 20 {
            vcY = 20 + navBarHeight
        }
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcY, width: screenSize.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        // Create a camera with the default location (if location services are used, this should not be shown for long)
        defaultCamera = GMSCameraPosition.camera(withLatitude: Constants.Settings.mapViewDefaultLat, longitude: Constants.Settings.mapViewDefaultLong, zoom: Constants.Settings.mapViewDefaultZoom)
        mapView = GMSMapView.map(withFrame: viewContainer.bounds, camera: defaultCamera)
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
        
        // Add a message box for the selector zoom interaction //0 - (selectorBoxHeight + 10)
        selectorMessageBox = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (selectorBoxWidth / 2), y: -selectorBoxHeight, width: selectorBoxWidth, height: selectorBoxHeight))
        selectorMessageBox.layer.cornerRadius = 5
        selectorMessageBox.backgroundColor = UIColor.white
        selectorMessageBox.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        selectorMessageBox.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        selectorMessageBox.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        
        selectorMessageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: selectorMessageBox.frame.width, height: selectorMessageBox.frame.height))
        selectorMessageLabel.text = "Zoom Limit"
        selectorMessageLabel.textColor = Constants.Colors.colorTextGray
        selectorMessageLabel.textAlignment = .center
        selectorMessageLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        selectorMessageBox.addSubview(selectorMessageLabel)
        
        // For Adding Blobs, create a default gray circle at the center of the screen with a slider for the user to change the circle radius
        // These components are not initially shown (until the user taps the Add Blob button)
        let circleInitialSize: CGFloat = 100
        selectorCircle = UIView(frame: CGRect(x: (mapView.frame.width / 2) - (circleInitialSize / 2), y: (mapView.frame.height / 2) - (circleInitialSize / 2), width: circleInitialSize, height: circleInitialSize))
        selectorCircle.layer.cornerRadius = circleInitialSize / 2
        selectorCircle.backgroundColor = Constants.Colors.blobGray
        selectorCircle.isUserInteractionEnabled = false
        
        let sliderHeight: CGFloat = 4
        let sliderCircleSize: Float = 20
        selectorSlider = UISlider(frame: CGRect(x: mapView.frame.width / 2, y: mapView.frame.height / 2 - (sliderHeight / 2), width: mapView.frame.width / 2, height: sliderHeight))
        selectorSlider.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        selectorSlider.minimumValue = sliderCircleSize / 2
        selectorSlider.maximumValue = Float(mapView.frame.width) / 2 - (sliderCircleSize / 2)
        selectorSlider.setValue(Float(circleInitialSize) / 2 - (sliderCircleSize / 2), animated: false)
        selectorSlider.tintColor = Constants.Colors.colorGrayDark
        selectorSlider.thumbTintColor = Constants.Colors.colorGrayDark
        selectorSlider.addTarget(self, action: #selector(MapViewController.sliderValueDidChange(_:)), for: .valueChanged)
        
        // Add the "My Location" Tracker Button in the bottom right corner, to the left of the Add Button
        buttonTrackUser = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonTrackUserSize, y: 5, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize))
        buttonTrackUser.layer.cornerRadius = Constants.Dim.mapViewButtonTrackUserSize / 2
        buttonTrackUser.backgroundColor = Constants.Colors.colorMapViewButton
        buttonTrackUser.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonTrackUser.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonTrackUser.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(buttonTrackUser)
        
        buttonTrackUserImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
        buttonTrackUserImage.image = UIImage(named: Constants.Strings.iconStringMapViewLocation)
        buttonTrackUserImage.contentMode = UIViewContentMode.scaleAspectFit
        buttonTrackUserImage.clipsToBounds = true
        buttonTrackUser.addSubview(buttonTrackUserImage)
        
        // Add the Map Refresh button in the bottom right corner, just above the Add Button
        buttonRefreshMap = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonTrackUserSize, y: 10 + Constants.Dim.mapViewButtonTrackUserSize, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize))
        buttonRefreshMap.layer.cornerRadius = Constants.Dim.mapViewButtonSearchSize / 2
        buttonRefreshMap.backgroundColor = Constants.Colors.colorMapViewButton
        buttonRefreshMap.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonRefreshMap.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonRefreshMap.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(buttonRefreshMap)
        
        buttonRefreshMapImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
        buttonRefreshMapImage.image = UIImage(named: Constants.Strings.iconStringMapViewRefresh)
        buttonRefreshMapImage.contentMode = UIViewContentMode.scaleAspectFit
        buttonRefreshMapImage.clipsToBounds = true
        buttonRefreshMap.addSubview(buttonRefreshMapImage)
        
        // Show a loading indicator for when the Map is refreshing
        buttonRefreshMapActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: buttonRefreshMap.frame.width, height: buttonRefreshMap.frame.height))
        buttonRefreshMapActivityIndicator.color = UIColor.white
        buttonRefreshMap.addSubview(buttonRefreshMapActivityIndicator)
        
//        // The Search Button
//        buttonSearchView = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonSearchSize, y: 5, width: Constants.Dim.mapViewButtonSearchSize, height: Constants.Dim.mapViewButtonSearchSize))
//        buttonSearchView.layer.cornerRadius = Constants.Dim.mapViewButtonSearchSize / 2
//        buttonSearchView.backgroundColor = Constants.Colors.colorMapViewButton
//        buttonSearchView.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
//        buttonSearchView.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
//        buttonSearchView.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
//        viewContainer.addSubview(buttonSearchView)
//        
//        buttonSearchViewImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
//        buttonSearchViewImage.image = UIImage(named: Constants.Strings.iconStringMapViewSearchCombo)
//        buttonSearchViewImage.contentMode = UIViewContentMode.scaleAspectFit
//        buttonSearchViewImage.clipsToBounds = true
//        buttonSearchView.addSubview(buttonSearchViewImage)
//        
//        // Add the List Button in the top right corner, just below the search button
//        buttonListView = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonListSize, y: viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonListSize, width: Constants.Dim.mapViewButtonListSize, height: Constants.Dim.mapViewButtonListSize))
//        buttonListView.layer.cornerRadius = Constants.Dim.mapViewButtonListSize / 2
//        buttonListView.backgroundColor = Constants.Colors.colorMapViewButton
//        buttonListView.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
//        buttonListView.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
//        buttonListView.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
//        viewContainer.addSubview(buttonListView)
//        
//        buttonListViewImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
//        buttonListViewImage.image = UIImage(named: Constants.Strings.iconStringMapViewList)
//        buttonListViewImage.contentMode = UIViewContentMode.scaleAspectFit
//        buttonListViewImage.clipsToBounds = true
//        buttonListView.addSubview(buttonListViewImage)
        
        // Add the Add Button in the bottom right corner
        buttonAdd = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAddSize, y: viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonAddSize, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonAdd.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonAdd.backgroundColor = Constants.Colors.colorMapViewButton
        buttonAdd.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonAdd.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonAdd.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(buttonAdd)
        
        buttonAddImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
        buttonAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewAdd)
        buttonAddImage.contentMode = UIViewContentMode.scaleAspectFit
        buttonAddImage.clipsToBounds = true
        buttonAdd.addSubview(buttonAddImage)
        
        // Add the Cancel Add Button to show in the bottom right corner above the Add Button
        // Do not show the Cancel Add Button until the user selects Add Button
        buttonCancelAdd = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAddSize, y: viewContainer.frame.height - 10 - Constants.Dim.mapViewButtonAddSize * 2, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonCancelAdd.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonCancelAdd.backgroundColor = Constants.Colors.colorMapViewButton
        buttonCancelAdd.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonCancelAdd.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonCancelAdd.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        
        buttonCancelAddImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
        buttonCancelAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewClose)
        buttonCancelAddImage.contentMode = UIViewContentMode.scaleAspectFit
        buttonCancelAddImage.clipsToBounds = true
        buttonCancelAdd.addSubview(buttonCancelAddImage)
        
        // The small icon that indicates that the current user location accuracy is too low to enable Blob viewing
        let lavSize: CGFloat = 40
        lowAccuracyView = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - lavSize, y: (viewContainer.frame.height / 2) - (lavSize / 2), width: lavSize, height: lavSize))
        lowAccuracyView.layer.cornerRadius = lavSize / 2
        lowAccuracyView.backgroundColor = UIColor.white
        lowAccuracyView.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        lowAccuracyView.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        lowAccuracyView.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(lowAccuracyView)
        lowAccuracyView.isHidden = true
        
        lowAccuracyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: lavSize, height: lavSize))
        lowAccuracyLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 34)
        lowAccuracyLabel.text = "!"
        lowAccuracyLabel.textColor = UIColor.red
        lowAccuracyLabel.textAlignment = .center
        lowAccuracyView.addSubview(lowAccuracyLabel)
        
        // Add the Current Location Collection View Container in the top left corner, under the status bar
        // Give it a clear background, and initialize with a height of 0 - the height will be adjusted to the number of cells
        // so that the mapView will not be blocked by the Collection View
        locationBlobsCollectionViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Dim.mapViewLocationBlobsCVCellSize + Constants.Dim.mapViewLocationBlobsCVHighlightAdjustSize, height: 0))
        locationBlobsCollectionViewContainer.backgroundColor = UIColor.clear
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
        locationBlobsCollectionView.register(LocationBlobsCollectionViewCell.self, forCellWithReuseIdentifier: Constants.Strings.locationBlobsCellReuseIdentifier)
        locationBlobsCollectionView.backgroundColor = UIColor.clear
        locationBlobsCollectionView.alwaysBounceVertical = false
        locationBlobsCollectionView.showsVerticalScrollIndicator = false
        locationBlobsCollectionViewContainer.addSubview(locationBlobsCollectionView)
        
//        // Add the Search Box with the width of the screen and a height so that only the top buttons will by covered when deployed
//        // Initialize with the Search Bar Y location as negative so that the Search Bar is not visible
//        searchBarContainer = UIView(frame: CGRect(x: 0, y: 0 - Constants.Dim.mapViewSearchBarContainerHeight, width: viewContainer.frame.width, height: Constants.Dim.mapViewSearchBarContainerHeight))
//        searchBarContainer.backgroundColor = Constants.Colors.colorStatusBar
//        searchBarContainer.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
//        searchBarContainer.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
//        searchBarContainer.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
//        
//        // The search bar exit view and label should be on the right side of the search bar container
//        searchBarExitView = UIView(frame: CGRect(x: viewContainer.frame.width - 50, y: 0, width: 50, height: 50))
//        searchBarContainer.addSubview(searchBarExitView)
        
        // MARK: SEARCH BAR COMPONENTS
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Add the search bar to the right of the nav bar,
        // use a popover to display the results.
        // Set an explicit size as we don't want to use the entire nav bar.
        searchController?.searchBar.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width - 50, height: navBarHeight)
        searchController?.searchBar.searchBarStyle = UISearchBarStyle.minimal
        searchController?.searchBar.setValue("\u{2573}", forKey: "_cancelButtonText")
        searchController?.searchBar.clipsToBounds = true
        self.navigationItem.titleView = searchController?.searchBar
//        searchBarContainer.addSubview((searchController?.searchBar)!)
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Keep the navigation bar visible.
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.modalPresentationStyle = UIModalPresentationStyle.popover
        
        let leftButtonItem = UIBarButtonItem(image: UIImage(named: "MV_list_icon.png"),
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.loadBlobsTabViewController))
        leftButtonItem.tintColor = Constants.Colors.colorTextNavBar
        self.navigationItem.setLeftBarButton(leftButtonItem, animated: true)
        
        let rightButtonItem = UIBarButtonItem(image: UIImage(named: "TAB_ICON_account_gray.png"),
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.loadSettingsTabViewController(_:)))
        rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
        self.navigationItem.setRightBarButton(rightButtonItem, animated: true)
        
//        searchBarExitLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
//        searchBarExitLabel.text = "\u{2573}"
//        searchBarExitLabel.textColor = Constants.Colors.colorTextNavBar
//        searchBarExitLabel.textAlignment = .center
//        searchBarExitLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 24)
//        searchBarExitView.addSubview(searchBarExitLabel)
        
        // Add the Preview Box to be the same size as the Search Box
        // Initialize with the Y location as negative (hide the box) just like the Search Box
        previewContainer = UIView(frame: CGRect(x: 0, y: 0 - Constants.Dim.mapViewPreviewContainerHeight, width: viewContainer.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewContainer.backgroundColor = Constants.Colors.standardBackground
        previewContainer.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        previewContainer.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        previewContainer.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        previewContainer.isUserInteractionEnabled = true
        viewContainer.addSubview(previewContainer)
        
        // The Preview Box User Image should fill the height of the Preview Box, be circular in shape, and on the left side of the Preview Box
        previewUserImageView = UIImageView(frame: CGRect(x: 5, y: 3, width: previewUserImageSize, height: previewUserImageSize))
        previewUserImageView.layer.cornerRadius = Constants.Dim.mapViewLocationBlobsCVItemSize / 2
        previewUserImageView.contentMode = UIViewContentMode.scaleAspectFill
        previewUserImageView.clipsToBounds = true
        previewUserImageView.isUserInteractionEnabled = true
        previewContainer.addSubview(previewUserImageView)
        
        // Add a loading indicator in case the User Image is still downloading when the Preview Box is shown
        // Give it the same size and location as the previewUserImageView
        previewUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 5, y: 5, width: previewUserImageSize, height: previewUserImageSize))
        previewUserImageActivityIndicator.color = UIColor.black
        previewContainer.addSubview(previewUserImageActivityIndicator)
        
        // The Preview Box User Name Label should start just to the right (5dp margin) of the Preview Box User Image and extend to the Time Label
        previewUserNameLabel = UILabel(frame: CGRect(x: 10 + previewUserImageSize, y: 5, width: previewContainer.frame.width - 60 - Constants.Dim.mapViewPreviewContainerHeight - previewTimeLabelWidth, height: 15))
        previewUserNameLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewUserNameLabel.textColor = Constants.Colors.colorTextGrayLight
        previewUserNameLabel.textAlignment = .left
        previewUserNameLabel.isUserInteractionEnabled = false
        previewContainer.addSubview(previewUserNameLabel)
        
        // Add a loading indicator in case the User Name is still downloading when the Preview Box is shown
        // Give it the same size and location as the previewUserNameLabel
        previewUserNameActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 10 + previewUserImageSize, y: 5, width: 25, height: 15))
        previewUserNameActivityIndicator.color = UIColor.black
        previewContainer.addSubview(previewUserNameActivityIndicator)
        
        // The Preview Box Time Label should start just to the right of the Preview Box User Name and extend to the Thumbnail Image
        // Because the Thumbnail Image is square, you can use the Preview Container Height as a substitute for calculating the Thumbnail Image width
        previewTimeLabel = UILabel(frame: CGRect(x: 10 + previewUserImageSize + previewUserNameLabel.frame.width, y: 5, width: previewTimeLabelWidth, height: 15))
        previewTimeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewTimeLabel.textColor = Constants.Colors.colorTextGrayLight
        previewTimeLabel.textAlignment = .right
        previewTimeLabel.isUserInteractionEnabled = false
        previewContainer.addSubview(previewTimeLabel)
        
        // The Preview Box Text Box should be a single line of text (UILabel is sufficient), have the same X location and width as the 
        // Preview Box User Name Label, and be placed just below the User Name Label
        previewTextBox = UILabel(frame: CGRect(x: 50, y: 10 + previewUserNameLabel.frame.height, width: previewContainer.frame.width - 60 - Constants.Dim.mapViewPreviewContainerHeight, height: 15))
        previewTextBox.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewTextBox.isUserInteractionEnabled = false
        previewContainer.addSubview(previewTextBox)
        
        // The Preview Box Thumbnail View should be square and on the right side of the Preview Box
        previewThumbnailView = UIImageView(frame: CGRect(x: previewContainer.frame.width - Constants.Dim.mapViewPreviewContainerHeight, y: 0, width: Constants.Dim.mapViewPreviewContainerHeight, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewThumbnailView.contentMode = UIViewContentMode.scaleAspectFill
        previewThumbnailView.clipsToBounds = true
        previewThumbnailView.isUserInteractionEnabled = false
        previewContainer.addSubview(previewThumbnailView)
        
        // Add a loading indicator in case the Thumbnail is still loading when the Preview Box is shown
        // Give it the same size and location as the previewThumbnailView
        previewThumbnailActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: previewContainer.frame.width - Constants.Dim.mapViewPreviewContainerHeight, y: 0, width: Constants.Dim.mapViewPreviewContainerHeight, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewThumbnailActivityIndicator.color = UIColor.black
        previewContainer.addSubview(previewThumbnailActivityIndicator)
        
        
        // Create the login screen, login box, and facebook login button
        // Create the login screen and facebook login button
        loginScreen = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        loginScreen.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        
        loginBox = UIView(frame: CGRect(x: (loginScreen.frame.width / 2) - 140, y: (loginScreen.frame.height / 2) - 80, width: 280, height: 160))
        loginBox.layer.cornerRadius = 5
        loginBox.backgroundColor = Constants.Colors.standardBackground
        loginScreen.addSubview(loginBox)
        
        fbLoginButton = FBSDKLoginButton()
        fbLoginButton.center = CGPoint(x: loginBox.frame.width / 2, y: loginBox.frame.height / 2)
        fbLoginButton.readPermissions = ["public_profile", "email", "user_likes"]
        fbLoginButton.delegate = self
        loginBox.addSubview(fbLoginButton)
        
        // Add a loading indicator for the pause showing the "Log out" button after the FBSDK is logged in and before the Account VC loads
        loginActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: loginBox.frame.height / 2 + 30, width: loginBox.frame.width, height: 20))
        loginActivityIndicator.color = UIColor.black
        loginBox.addSubview(loginActivityIndicator)
        
        loginProcessLabel = UILabel(frame: CGRect(x: 0, y: loginBox.frame.height / 2 + 55, width: loginBox.frame.width, height: 14))
        loginProcessLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        loginProcessLabel.text = "Logging you in..."
        loginProcessLabel.textColor = UIColor.black
        loginProcessLabel.textAlignment = .center
        
        // Add a loading indicator to display on the map, so users can see when data is downloading without having to reveal the refresh button
        backgroundActivityView = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (Constants.Dim.mapViewBackgroundActivityViewSize / 2) , y: viewContainer.frame.height - 5 - Constants.Dim.mapViewBackgroundActivityViewSize, width: Constants.Dim.mapViewBackgroundActivityViewSize, height: Constants.Dim.mapViewBackgroundActivityViewSize))
        backgroundActivityView.layer.cornerRadius = Constants.Dim.mapViewBackgroundActivityViewSize / 2
        backgroundActivityView.backgroundColor = UIColor.white
        backgroundActivityView.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        backgroundActivityView.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        backgroundActivityView.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        
        backgroundActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: backgroundActivityView.frame.width, height: backgroundActivityView.frame.height))
        backgroundActivityIndicator.color = UIColor.black
        backgroundActivityView.addSubview(backgroundActivityIndicator)
        backgroundActivityIndicator.startAnimating()
        
        
        // Add the Status Bar, Top Bar and Search Bar last so that they are placed above (z-index) all other views
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: Constants.Dim.statusBarStandardHeight))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
//        // Add the Tap Gesture Recognizers for all Buttons
//        buttonSearchTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapButtonSearch(_:)))
//        buttonSearchTapGesture.numberOfTapsRequired = 1  // add single tap
//        buttonSearchView.addGestureRecognizer(buttonSearchTapGesture)
        
//        searchExitTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapSearchExit(_:)))
//        searchExitTapGesture.numberOfTapsRequired = 1  // add single tap
//        searchBarExitView.addGestureRecognizer(searchExitTapGesture)
        
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
        
        lowAccuracyViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapLowAccuracyView(_:)))
        lowAccuracyViewTapGesture.numberOfTapsRequired = 1  // add single tap
        lowAccuracyView.addGestureRecognizer(lowAccuracyViewTapGesture)
        
        // Add the Tap Gesture Recognizers for the Preview Box tap gestures
        previewUserTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.previewUserTap(_:)))
        previewUserTapGesture.numberOfTapsRequired = 1  // add single tap
        previewUserImageView.addGestureRecognizer(previewUserTapGesture)
        
        previewContentTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.previewContentTap(_:)))
        previewContentTapGesture.numberOfTapsRequired = 1  // add single tap
        previewContainer.addGestureRecognizer(previewContentTapGesture)
        
        // Add the Key Path Observers for changes in the user's location and for when the map is moved (the map camera)
        mapView.addObserver(self, forKeyPath: "myLocation", options:NSKeyValueObservingOptions(), context: nil)
        mapView.addObserver(self, forKeyPath: "camera", options:NSKeyValueObservingOptions(), context: nil)
        
        // Setup the Blob list
        Constants.Data.locationBlobs = [Constants.Data.defaultBlob]
        
//        // Recall the userLikes from Core Data and set them to the global variable
//        Constants.Data.currentUserLikes = CoreDataFunctions().likesRetrieve()
        
        // Recall the Tutorial Views data in Core Data.  If it is empty for the current ViewController's tutorial, it has not been seen by the curren user.
        let tutorialViews = CoreDataFunctions().tutorialViewRetrieve()
        print("MVC: TUTORIAL VIEWS MAPVIEW: \(tutorialViews.tutorialMapViewDatetime)")
        if tutorialViews.tutorialMapViewDatetime == nil
//        if 2 == 2
        {
            let holeView = HoleView(holeViewPosition: 1, frame: viewContainer.bounds, circleOffsetX: 0, circleOffsetY: 0, circleRadius: 0, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 50, textWidth: 200, textFontSize: 24, text: "Welcome to Blobjot!\n\nBlobjot is a location-based messaging and social media service.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        }
        else
        {
            self.refreshMap()
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        // Run the addBlobs function in case additional data has not been added
        self.addMapBlobsToMap()
        
        if showLoginScreenBool
        {
            self.showLoginScreen()
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool
    {
        return self.statusBarHidden
    }
    
    
    // MARK: HOLE VIEW DELEGATE
    func holeViewRemoved(removingViewAtPosition: Int)
    {
        switch removingViewAtPosition
        {
        case 1:
            // Create the example Blob and add it to the map
            let blobCenter = CLLocationCoordinate2DMake(Constants.Settings.mapViewDefaultLat, Constants.Settings.mapViewDefaultLong)
            tutorialCircle.position = blobCenter
            tutorialCircle.radius = 50
            tutorialCircle.title = "example"
            tutorialCircle.fillColor = Constants().blobColor(Constants.BlobTypes.blobjot, mainMap: true)
            tutorialCircle.strokeColor = Constants().blobColor(Constants.BlobTypes.blobjot, mainMap: true)
            tutorialCircle.strokeWidth = 1
            tutorialCircle.map = self.mapView
            
            // Move the camera to see the example Blob
            let camera = GMSCameraPosition.camera(withLatitude: Constants.Settings.mapViewDefaultLat, longitude: Constants.Settings.mapViewDefaultLong, zoom: 17)
            self.mapView.camera = camera
            
            let holeView = HoleView(holeViewPosition: 2, frame: viewContainer.bounds, circleOffsetX: (viewContainer.bounds.width / 2), circleOffsetY: 275, circleRadius: 120, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 20, textWidth: 200, textFontSize: 18, text: "Blobs are messages attached to a specific location.  Users must visit this location to view the message.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 2:
            // Change the color of the tutorial Blob
            tutorialCircle.fillColor = Constants().blobColor(Constants.BlobTypes.invisible, mainMap: true)
            tutorialCircle.strokeColor = Constants().blobColor(Constants.BlobTypes.invisible, mainMap: true)
            
            let holeView = HoleView(holeViewPosition: 3, frame: viewContainer.bounds, circleOffsetX: (viewContainer.bounds.width / 2), circleOffsetY: 275, circleRadius: 120, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 20, textWidth: 200, textFontSize: 18, text: "Blobs can be invisible...")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 3:
            // Change the color of the tutorial Blob
            tutorialCircle.fillColor = Constants().blobColor(Constants.BlobTypes.permanent, mainMap: true)
            tutorialCircle.strokeColor = Constants().blobColor(Constants.BlobTypes.permanent, mainMap: true)
            
            let holeView = HoleView(holeViewPosition: 4, frame: viewContainer.bounds, circleOffsetX: (viewContainer.bounds.width / 2), circleOffsetY: 275, circleRadius: 120, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 20, textWidth: 200, textFontSize: 18, text: "...or visible on the map.\n\nBlobs can be permanent...")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 4:
            // Change the color of the tutorial Blob
            tutorialCircle.fillColor = Constants().blobColor(Constants.BlobTypes.temporary, mainMap: true)
            tutorialCircle.strokeColor = Constants().blobColor(Constants.BlobTypes.temporary, mainMap: true)
            
            let holeView = HoleView(holeViewPosition: 5, frame: viewContainer.bounds, circleOffsetX: (viewContainer.bounds.width / 2), circleOffsetY: 275, circleRadius: 120, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 20, textWidth: 200, textFontSize: 18, text: "...or temporary, where the Blob disappears after you visit and view the Blob content.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 5:
            let holeView = HoleView(holeViewPosition: 6, frame: viewContainer.bounds, circleOffsetX: viewContainer.bounds.width - 25, circleOffsetY: 25, circleRadius: 50, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 50, textWidth: 200, textFontSize: 24, text: "You can search for locations, center the map on your location, or refresh your Blobs.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 6:
            let holeView = HoleView(holeViewPosition: 7, frame: viewContainer.bounds, circleOffsetX: viewContainer.bounds.width - 25, circleOffsetY: viewContainer.bounds.height - 25, circleRadius: 50, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 50, textWidth: 200, textFontSize: 24, text: "You can add a new Blob, see area Blobs in a list, search for friends, and access your account.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 7:
            let holeView = HoleView(holeViewPosition: 8, frame: viewContainer.bounds, circleOffsetX: 25, circleOffsetY: 25, circleRadius: 50, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 70, textWidth: 200, textFontSize: 24, text: "This list will show the Blobs at your current location.  You can tap the Blob user's image to view a preview.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 8:
            self.showBlobPreview(Constants.Data.defaultBlob)
            
            let holeView = HoleView(holeViewPosition: 9, frame: viewContainer.bounds, circleOffsetX: 100, circleOffsetY: -50, circleRadius: 140, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 120, textWidth: 200, textFontSize: 24, text: "When you select a Blob, you can preview the Blob here, and tap the preview to view the entire Blob.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
            
        default:
            self.closePreview()
            
            // Remove the tutorial Blob and refresh the Map to recall the user's Blobs
            tutorialCircle.map = nil
            self.refreshMap()
            
            // Set the map center coordinate to focus on the user's current location
            if let userLocation = mapView.myLocation
            {
                mapCenter = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
                mapView.camera = GMSCameraPosition(target: mapCenter, zoom: Constants.Settings.mapViewDefaultZoom, bearing: CLLocationDirection(0), viewingAngle: mapView.camera.viewingAngle)
            }
            else
            {
                self.mapView.camera = self.defaultCamera
            }
            
            // Record the Tutorial View in Core Data
            let moc = DataController().managedObjectContext
            let tutorialView = NSEntityDescription.insertNewObject(forEntityName: "TutorialViews", into: moc) as! TutorialViews
            tutorialView.setValue(NSDate(), forKey: "tutorialMapViewDatetime")
            CoreDataFunctions().tutorialViewSave(tutorialViews: tutorialView)
        }
    }
    
    
    // MARK: SEARCH BAR METHODS
    
    // Capture the Google Places Search Result
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didAutocompleteWith place: GMSPlace)
    {
        print("MVC - SEARCH BAR RESULTS CONTROLLER")
        searchController?.isActive = false
        
        // Show the status bar now that the search view is gone
        UIApplication.shared.isStatusBarHidden = false
        self.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Use the place coordinate to center the map
        mapCenter = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        
        // Add a marker to the center of the coordinates
        let position = mapCenter
        searchMarker = GMSMarker(position: position!)
        searchMarker!.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        searchMarker!.title = ""
        searchMarker!.icon = GMSMarker.markerImage(with: .black)
        searchMarker!.tracksViewChanges = false
        searchMarker!.map = mapView
        
        // Center the camera on the place
        mapView.camera = GMSCameraPosition(target: mapCenter, zoom: 18, bearing: CLLocationDirection(0), viewingAngle: mapView.camera.viewingAngle)
        // mapView.camera.zoom
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error)
    {
        // TODO: handle the error.
        print("MVC - SEARCH BAR Error: ", error)
        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController)
    {
        print("MVC - SEARCH BAR didRequestAutocompletePredictions")
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
//        // Hide the status bar while the user searches for the place
//        UIApplication.shared.isStatusBarHidden = true
//        self.statusBarHidden = true
//        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func didUpdateAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController)
    {
        print("MVC - SEARCH BAR didUpdateAutocompletePredictions")
//        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//        
//        // Show the status bar
//        UIApplication.shared.isStatusBarHidden = false
//        self.statusBarHidden = false
//        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: TAP GESTURE METHODS
    
    // If the low accuracy alert view is showing, tapping it will display the popup explaining that the user's current location range is too high
    func tapLowAccuracyView(_ gesture: UITapGestureRecognizer)
    {
        // Show a notification that the user's location is too inaccurate to update data
        createAlertOkView("Bad Signal!", message: "Your location is too inaccurate to gather data.  Try moving to an area with better reception.")
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
//    // When the Search Button is tapped, check to see if the search bar is visible
//    // If it is not visible, and add it to the view and animate in down into view
//    func tapButtonSearch(_ gesture: UITapGestureRecognizer)
//    {        
//        // Check whether the button has already been pushed - if not, expand the hidden buttons
//        // else, display the search bar
//        if !menuButtonMapOpen
//        {
//            menuButtonMapOpen = true
//            
//            // Add an animation to lower the hidden buttons
//            UIView.animate(withDuration: 0.2, animations:
//                {
//                    self.buttonTrackUser.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonTrackUserSize, y: 10 + Constants.Dim.mapViewButtonTrackUserSize, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize)
//                    self.buttonRefreshMap.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonTrackUserSize, y: 15 + Constants.Dim.mapViewButtonTrackUserSize * 2, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize)
//                }, completion:
//                { (finished: Bool) -> Void in
//                    self.buttonSearchViewImage.image = UIImage(named: Constants.Strings.iconStringMapViewSearch)
//            })
//        }
//        else
//        {
//            // Ensure that the search bar is not visible - if it is, the search button should not be visible to touch
//            if !searchBarVisible
//            {
//                searchBarVisible = true
//                viewContainer.addSubview(searchBarContainer)
//                
//                // Add an animation to lower the search button container into view
//                UIView.animate(withDuration: 0.2, animations:
//                    {
//                        self.searchBarContainer.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewSearchBarContainerHeight)
//                    }, completion: nil)
//            }
//        }
//        
//        // Save an action in Core Data
//        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
//    }
    
//    // If the Search Box Exit Button is tapped, call the custom function to hide the box
//    func tapSearchExit(_ gesture: UITapGestureRecognizer)
//    {
//        self.closeSearchBox()
//        
//        // Save an action in Core Data
//        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
//    }
    
    // If the List View Button is tapped, prepare a Navigation Controller and a Tab View Controller
    // Attach the needed Table Views to the Tab View Controller and load the Navigation Controller
    func prepPushView()
    {
        // Ensure that the Preview Screen is hidden
        self.closePreview()
        
        // Set all map Circles back to default (no highlighting)
        for mBlob in Constants.Data.mapBlobs
        {
            unhighlightMapCircleForBlob(mBlob)
        }
        
//        self.loadTabViewController(false)
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: "prepPushView")
    }
    
    func loadBlobsTabViewController()
    {
        // Reset features on the MVC
        prepPushView()
        
//        // Create the Back Button Item and Title View for the Tab View
//        // These settings will be passed up to the assigned Navigation Controller for the Tab View Controller
//        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
//                                             style: UIBarButtonItemStyle.plain,
//                                             target: self,
//                                             action: #selector(MapViewController.popViewController(_:)))
//        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
//        
//        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
//        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
//        ncTitleText.text = "Nearby Blobs"
//        ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
//        ncTitleText.textColor = Constants.Colors.colorTextNavBar
//        ncTitleText.textAlignment = .center
//        ncTitle.addSubview(ncTitleText)
//        
//        // Prepare the Active Blobs VC
//        // Assign the created Nav Bar settings to the Tab Bar Controller
//        activeBlobsVC = BlobsActiveTableViewController()
//        activeBlobsVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
//        activeBlobsVC.navigationItem.titleView = ncTitle
        
        ///////
        // Prepare both of the Table View Controllers and add Tab Bar Items to them
        activeBlobsVC = BlobsActiveTableViewController()
        let activeBlobsTabBarItem = UITabBarItem()
        activeBlobsTabBarItem.tag = 1
        activeBlobsTabBarItem.image = UIImage(named: Constants.Strings.iconStringTabIconConnectionsGray)
        activeBlobsTabBarItem.selectedImage = UIImage(named: Constants.Strings.iconStringTabIconConnectionsWhite)
        activeBlobsTabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        activeBlobsVC!.tabBarItem = activeBlobsTabBarItem
        
        blobsVC = BlobsTableViewController()
        let blobsTabBarItem = UITabBarItem()
        blobsTabBarItem.tag = 2
        blobsTabBarItem.image = UIImage(named: Constants.Strings.iconStringTabIconAccountGray)
        blobsTabBarItem.selectedImage = UIImage(named: Constants.Strings.iconStringTabIconAccountWhite)
        blobsTabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        blobsVC!.tabBarItem = blobsTabBarItem
        
        // Create the Tab Bar Controller to hold the Table View Controllers
        tabBarControllerCustom = UITabBarController()
        tabBarControllerCustom!.delegate = self
        tabBarControllerCustom!.tabBar.barTintColor = Constants.Colors.colorStatusBarLight
        tabBarControllerCustom!.tabBar.tintColor = Constants.Colors.colorTextNavBar
        tabBarControllerCustom!.viewControllers = [activeBlobsVC!, blobsVC!]
        
        // Create the Back Button Item and Title View for the Tab View
        // These settings will be passed up to the assigned Navigation Controller for the Tab View Controller
        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        tabBarControllerCustom!.navigationItem.setLeftBarButton(backButtonItem, animated: true)
        
        print("MVC - LBTVC - NAV CONTROLLER: \(self.navigationController)")
        if let navController = self.navigationController
        {
            navController.pushViewController(tabBarControllerCustom!, animated: true)
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    func loadSettingsTabViewController(_ goToAccountTab: Bool)
    {
        // Reset features on the MVC
        prepPushView()
        
        // Prepare both of the Table View Controllers and add Tab Bar Items to them
        peopleVC = PeopleViewController()
        peopleVC!.peopleViewDelegate = self
        peopleVC!.tabBarUsed = true
        let peopleTabBarItem = UITabBarItem()
        peopleTabBarItem.tag = 1
        peopleTabBarItem.image = UIImage(named: Constants.Strings.iconStringTabIconConnectionsGray)
        peopleTabBarItem.selectedImage = UIImage(named: Constants.Strings.iconStringTabIconConnectionsWhite)
        peopleTabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        peopleVC!.tabBarItem = peopleTabBarItem
        
        accountVC = AccountViewController()
        accountVC!.accountViewDelegate = self
        let accountTabBarItem = UITabBarItem()
        accountTabBarItem.tag = 2
        accountTabBarItem.image = UIImage(named: Constants.Strings.iconStringTabIconAccountGray)
        accountTabBarItem.selectedImage = UIImage(named: Constants.Strings.iconStringTabIconAccountWhite)
        accountTabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        accountVC!.tabBarItem = accountTabBarItem
        
        // Create the Tab Bar Controller to hold the Table View Controllers
        tabBarControllerCustom = UITabBarController()
        tabBarControllerCustom!.delegate = self
        tabBarControllerCustom!.tabBar.barTintColor = Constants.Colors.colorStatusBarLight
        tabBarControllerCustom!.tabBar.tintColor = Constants.Colors.colorTextNavBar
        tabBarControllerCustom!.viewControllers = [peopleVC!, accountVC!]
        
        // If the account tab should be loaded, set the last (1) index to load
        if goToAccountTab
        {
            tabBarControllerCustom!.selectedIndex = 1
        }
        
        // Create the Back Button Item and Title View for the Tab View
        // These settings will be passed up to the assigned Navigation Controller for the Tab View Controller
        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        tabBarControllerCustom!.navigationItem.setLeftBarButton(backButtonItem, animated: true)
        
        print("MVC - LSTVC - NAV CONTROLLER: \(self.navigationController)")
        if let navController = self.navigationController
        {
            navController.pushViewController(tabBarControllerCustom!, animated: true)
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    
    // MARK: TAB BAR DELEGATE METHODS
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController)
    {
        print("MVC - TAB BAR - DID SELECT: \(viewController)")
        if let tabBar = self.tabBarControllerCustom
        {
            if peopleVC != nil && viewController == peopleVC
            {
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
                ncTitleText.text = "People"
                ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
                ncTitleText.textColor = Constants.Colors.colorTextNavBar
                ncTitleText.textAlignment = .center
                ncTitle.addSubview(ncTitleText)
                tabBar.navigationItem.titleView = ncTitle
            }
            else if accountVC != nil && viewController == accountVC
            {
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
                ncTitleText.text = "Account"
                ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
                ncTitleText.textColor = Constants.Colors.colorTextNavBar
                ncTitleText.textAlignment = .center
                ncTitle.addSubview(ncTitleText)
                tabBar.navigationItem.titleView = ncTitle
            }
            else if activeBlobsVC != nil && viewController == activeBlobsVC
            {
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
                ncTitleText.text = "Nearby Blobs"
                ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
                ncTitleText.textColor = Constants.Colors.colorTextNavBar
                ncTitleText.textAlignment = .center
                ncTitle.addSubview(ncTitleText)
                tabBar.navigationItem.titleView = ncTitle
            }
            else if blobsVC != nil && viewController == blobsVC
            {
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
                ncTitleText.text = "All Blobs"
                ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
                ncTitleText.textColor = Constants.Colors.colorTextNavBar
                ncTitleText.textAlignment = .center
                ncTitle.addSubview(ncTitleText)
                tabBar.navigationItem.titleView = ncTitle
            }
        }
        
    }
    
    
    // If the Add Button is tapped, check to see if the addingBlob indicator has already been activated (true)
    // If not, hide the normal buttons and just show the buttons needed for the Add Blob action (gray circle, slider, etc.)
    // If so, create a Nav Controller and a new BlobAddViewController and load the Nav Controller and pass the new Blob data
    func tapAddView(_ gesture: UITapGestureRecognizer)
    {
        if addingBlob
        {
            // If the addingBlob indicator is true, the user has already started the Add Blob process and has chosen a location and radius for the Blob
            // Instantiate the BlobAddViewController and a Nav Controller and present the View Controller
            
            self.bringAddBlobViewControllerTopOfStack(true)
        }
        else
        {
            // If the addingBlob indicator is false, the user is just starting the Add Blob process, so
            // hide the buttons not needed and show the Cancel Add Button
            
            // Change the add blob indicator to true before calling adjustMapViewCamera
            addingBlob = true
            
            buttonAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewCheck)
            
            viewContainer.addSubview(buttonCancelAdd)
            mapView.addSubview(selectorMessageBox)
            mapView.addSubview(selectorCircle)
            mapView.addSubview(selectorSlider)
            
            // Adjust the Map Camera so that the map cannot be viewed at an angle while adding a new Blob
            // The circle remains a circle when the map is angled, which is not a true representation of the Blob
            // that will be added, so the mapView is kept unangled while a Blob is being added
            adjustMapViewCamera()
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // If the Cancel Add Blob button is tapped, show the buttons that were hidden and hide the elements used in the add blob process
    func tapCancelAddView(_ gesture: UITapGestureRecognizer)
    {
        buttonAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewAdd)
        
        buttonCancelAdd.removeFromSuperview()
        selectorMessageBox.removeFromSuperview()
        selectorCircle.removeFromSuperview()
        selectorSlider.removeFromSuperview()
        
        // Change the add blob indicator back to false efore calling adjustMapViewCamera
        addingBlob = false
        
        // Adjust the Map Camera back to allow the map can be viewed at an angle
        adjustMapViewCamera()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
//        self.dismiss(animated: true, completion: {})
        self.navigationController!.popViewController(animated: true)
    }
    
    // Dismiss the latest View Controller presented from this VC
    func popViewController()
    {
//        self.dismiss(animated: true, completion: {})
        self.navigationController!.popViewController(animated: true)
    }

// *COMPLETE****** Decide how the user should be tracked without making the interface annoying
    // If the Track User button is tapped, the track functionality is toggled
    func toggleTrackUser(_ gesture: UITapGestureRecognizer)
    {
        // Close the Preview Box - the user is not interacting with the Preview Box anymore
        closePreview()
        
        // Set all map Circles back to default (no highlighting)
        for mBlob in Constants.Data.mapBlobs
        {
            unhighlightMapCircleForBlob(mBlob)
        }
        
        // Check to see if the user is already being tracked (toggle functionality)
        if userTrackingCamera
        {
            userTrackingCamera = false
        }
        else
        {
            userTrackingCamera = true
            
            // Set the map center coordinate to focus on the user's current location
            // Set the zoom level to match the current map zoom setting
            if let userLocation = mapView.myLocation
            {
                mapCenter = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
                mapView.camera = GMSCameraPosition(target: mapCenter, zoom: mapView.camera.zoom, bearing: CLLocationDirection(0), viewingAngle: mapView.camera.viewingAngle)
            }
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Reset the MapView and re-download the Blob data
    func refreshMap(_ gesture: UITapGestureRecognizer? = nil)
    {
        // Show the Map refreshing indicator
        self.buttonRefreshMapActivityIndicator.startAnimating()
        self.mapView.addSubview(backgroundActivityView)
        
        // PREPARE DATA
        // Request the Map Data for the logged in user
        AWSPrepRequest(requestToCall: AWSGetMapData(), delegate: self as AWSRequestDelegate).prepRequest()
        
        self.waitingForMapData = true
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // If the Preview Box User Image is tapped, load the people view with the selected person at the top of the list
    func previewUserTap(_ gesture: UITapGestureRecognizer)
    {
        if let previewBlob = self.previewBlob
        {
            // Ensure that the previewBlob is not the default Blob (Blobjot Blob)
            if previewBlob.blobExtraRequested
            {
                // Create a back button and title for the Nav Bar
                let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                                     style: UIBarButtonItemStyle.plain,
                                                     target: self,
                                                     action: #selector(MapViewController.popViewController(_:)))
                backButtonItem.tintColor = Constants.Colors.colorTextNavBar
                
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
                ncTitleText.text = "All People"
                ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
                ncTitleText.textColor = Constants.Colors.colorTextNavBar
                ncTitleText.textAlignment = .center
                ncTitle.addSubview(ncTitleText)
                
                // Instantiate the PeopleViewController and pass the Preview Blob UserID to the VC
                let peopleVC = PeopleViewController()
                peopleVC.peopleListTopPerson = previewBlob.blobUserID
                
                // Assign the created Nav Bar settings to the Tab Bar Controller
                peopleVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
                peopleVC.navigationItem.titleView = ncTitle
                
                if let navController = self.navigationController
                {
                    navController.pushViewController(peopleVC, animated: true)
                }
            }
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // If the Preview Box Content (Text or Thumbnail) is tapped, load the blob view with the selected blob data
    func previewContentTap(_ gesture: UITapGestureRecognizer)
    {
        // Ensure that the extra blob data has already been requested and that either the blob text or thumbnail is not nil
        if let pBlob = previewBlob
        {
            if pBlob.blobExtraRequested && (pBlob.blobText != nil || pBlob.blobThumbnailID != nil)
            {
                // Close the Preview Box - the user is not interacting with the Preview Box anymore
                closePreview()
                
                for mBlob in Constants.Data.mapBlobs
                {
                    // Set all map Circles back to default (no highlighting)
                    unhighlightMapCircleForBlob(mBlob)
                    
                    // Deselect all mapBlobs (so they don't stick out from the Collection View)
                    mBlob.blobSelected = false
                }
                
                // Create a back button and title for the Nav Bar
                let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                                     style: UIBarButtonItemStyle.plain,
                                                     target: self,
                                                     action: #selector(MapViewController.popViewController(_:)))
                backButtonItem.tintColor = Constants.Colors.colorTextNavBar
                
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
                
                // Try to access the locally stored preview Blob User to set the navigation bar title
                if let previewUser = self.previewBlobUser
                {
                    ncTitleText.text = previewUser.userName
                }
                else
                {
                    ncTitleText.text = ""
                }
                
                ncTitleText.textColor = Constants.Colors.colorTextNavBar
                ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
                ncTitleText.textAlignment = .center
                ncTitle.addSubview(ncTitleText)
                
                // Instantiate the BlobViewController and pass the Preview Blob to the VC
                blobVC = BlobViewController()
                blobVC.blob = pBlob
                
                // Assign the created Nav Bar settings to the Tab Bar Controller
                blobVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
                blobVC.navigationItem.titleView = ncTitle
                
                print("MVC - NAV CONTROLLER: \(self.navigationController)")
                if let navController = self.navigationController
                {
                    navController.pushViewController(blobVC, animated: true)
                }
                
                // Reload the collectionView so that the previously selected Blob is no longer sticking out
                self.refreshCollectionView()
            }
            else if pBlob.blobID == Constants.Data.defaultBlob.blobID
            {
                // Show the error message
                self.createAlertOkView("Blobjot", message: "Thanks for using Blobjot!  This placeholder Blob will always be visible and does not have a full Blob view, but try tapping on some other Blobs to see more details!")
            }
            else
            {
                // Show the error message
                self.createAlertOkView("Blob not in range", message: "This Blob is not in range.  Travel within the perimeter of the Blob to see all the details!")
            }
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    
    // KEY-VALUE OBSERVER HANDLERS
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        // Detect if the user's location has changed
        if keyPath == "myLocation"
        {
            if !Constants.inBackground
            {
                refreshBlobsForCurrentLocation()
            }
        }
        
        // Detect if the map camera has changed
        // An alternative is the mapView delegate "willMove"
        if keyPath == "camera"
        {
//            print("CAMERA CHANGING: MAPVIEW CAMERA BEFORE: \(mapView.camera)")
        }
    }
    
    // For KEY-VALUE OBSERVER change "myLocation" - can be used elsewhere
    // Reload Blob data based on the user's new location
    func refreshBlobsForCurrentLocation()
    {
        // Check that the user's current location is accessible
        if let userLocationCurrent = mapView.myLocation
        {
            if self.lastLocation != nil
            {
                let locationDistance = userLocationCurrent.distance(from: self.lastLocation!)
                let timeSinceLocationChange = Date().timeIntervalSince1970 - self.lastLocationTime
                
                // Ensure that the distance change is greater than the minimum setting
                if locationDistance >= Constants.Settings.locationDistanceMinChange || timeSinceLocationChange >= Constants.Settings.locationTimeMinChange
                {
                    self.refreshBlobs(userLocationCurrent)
                }
            }
            else
            {
                // The app was just initialized, so no lastLocation exists - go ahead and reload the Blobs
                self.refreshBlobs(userLocationCurrent)
            }
            
//*ISSUE ******************* GMSCameraUpdate methods not being recognized ***********************
            if userTrackingCamera
            {
//                    let cameraUpdate = GMSCameraUpdate()
//                    cameraUpdate.setTarget = userLocation
//                    mapView.animateWithCameraUpdate(cameraUpdate)
            }
        }
    }
    
    func refreshBlobs(_ userLocationCurrent: CLLocation)
    {
        print("MVC - refreshBlobs - CURRENT LOCATION: \(userLocationCurrent), PREVIOUS LOCATION: \(self.lastBlobjotBlobsLocation)")
        
        // Ensure that the distance change is greater than the minimum setting for updating Blobjot Blobs
        if let blobjotBlobsLocationPrevious = self.lastBlobjotBlobsLocation
        {
            print("MVC - CURRENT LOCATION: \(userLocationCurrent), PREVIOUS LOCATION: \(blobjotBlobsLocationPrevious)")
            let locationDistance = userLocationCurrent.distance(from: blobjotBlobsLocationPrevious)
            
            // Ensure that the distance change is greater than the minimum setting
            if locationDistance >= Constants.Settings.locationDistanceUpdateBlobjotBlobs
            {
                // Download the local place Blobs
                AWSPrepRequest(requestToCall: AWSGetBlobjotBlobs(userLat: Float(userLocationCurrent.coordinate.latitude), userLng: Float(userLocationCurrent.coordinate.longitude)), delegate: self as AWSRequestDelegate).prepRequest()
                
                // Update the previous Blobjot Blobs location property with the latest data
                self.lastBlobjotBlobsLocation = userLocationCurrent
            }
        }
        else
        {
            // Download the local place Blobs
            AWSPrepRequest(requestToCall: AWSGetBlobjotBlobs(userLat: Float(userLocationCurrent.coordinate.latitude), userLng: Float(userLocationCurrent.coordinate.longitude)), delegate: self as AWSRequestDelegate).prepRequest()
            
            // Update the previous Blobjot Blobs location property with the latest data
            self.lastBlobjotBlobsLocation = userLocationCurrent
        }
        
        // Update the previous location and time properties with the latest data
        self.lastLocation = userLocationCurrent
        self.lastLocationTime = Date().timeIntervalSince1970
        
        // If the user's initial location has not been centered on the map, do so
        if !userLocationInitialSet
        {
            let newCamera = GMSCameraPosition.camera(withLatitude: userLocationCurrent.coordinate.latitude, longitude: userLocationCurrent.coordinate.longitude, zoom: Constants.Settings.mapViewAddBlobMinZoom)
            mapView.camera = newCamera
            userLocationInitialSet = true
        }
        
        // Determine the user's new coordinates and the range of accuracy around those coordinates
        let userLocation = CLLocation(latitude: userLocationCurrent.coordinate.latitude, longitude: userLocationCurrent.coordinate.longitude)
        let userRangeRadius = userLocationCurrent.horizontalAccuracy
        
        // Check to ensure that the location accuracy is reasonable - if too high, do not update data and wait for more accuracy
        if userRangeRadius <= Constants.Settings.locationAccuracyMax
        {
            // Reset the accuracy indicator
            locationInaccurate = false
            
            // Hide the low accuracy view
            self.lowAccuracyView.isHidden = true
            
            // Clear the array of current location Blobs and add the default Blob as the first element
            Constants.Data.locationBlobs = [Constants.Data.defaultBlob]
            
            // Loop through the array of map Blobs to find which Blobs are in range of the user's current location
            for blob in Constants.Data.mapBlobs
            {
                // Find the minimum distance possible to the Blob center from the user's location
                // Determine the raw distance from the Blob center to the user's location
                // Then subtract the user's location range radius to find the distance from the Blob center to the edge of
                // the user location range circle closest to the Blob
                let blobLocation = CLLocation(latitude: blob.blobLat, longitude: blob.blobLong)
                let userDistanceFromBlobCenter = userLocation.distance(from: blobLocation)
                let minUserDistanceFromBlobCenter: Double! = userDistanceFromBlobCenter - userRangeRadius
                
                // If the minimum distance from the Blob's center to the user is equal to or less than the Blob radius,
                // request the extra Blob data (Blob Text and/or Blob Media)
                if minUserDistanceFromBlobCenter <= blob.blobRadius
                {
                    // Ensure that the Blob data has not already been requested
                    // If so, append the Blob to the Location Blob Array
                    if !blob.blobExtraRequested
                    {
                        blob.blobExtraRequested = true
                        
                        AWSPrepRequest(requestToCall: AWSGetBlobExtraData(blob: blob), delegate: self as AWSRequestDelegate).prepRequest()
                        
                        // When downloading Blob data, always request the user data if it does not already exist (ONLY IF NOT A BLOBJOT BLOB)
                        if blob.blobType != Constants.BlobTypes.blobjot
                        {
                            // Find the correct User Object in the global list
                            var userExists = false
                            loopUserObjectCheck: for userObject in Constants.Data.userObjects
                            {
                                if userObject.userID == blob.blobUserID
                                {
                                    userExists = true
                                    
                                    // If the userName or userImage does not exist, request them from FB
                                    if userObject.userName == nil || userObject.userImage == nil
                                    {
                                        AWSPrepRequest(requestToCall: FBGetUserProfileData(user: userObject, downloadImage: true), delegate: self as AWSRequestDelegate).prepRequest()
                                    }
                                    
                                    break loopUserObjectCheck
                                }
                            }
                            // If the user has not been downloaded, request the user and the userImage
                            if !userExists
                            {
                                AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: blob.blobUserID, forPreviewBox: true), delegate: self as AWSRequestDelegate).prepRequest()
                            }
                        }
                        else
                        {
                            self.updatePreviewBoxData(Constants.Data.userPublicArea)
                        }
                    }
                    else
                    {
                        Constants.Data.locationBlobs.append(blob)
                    }
                    
                    // If the Blob is invisible, change the circle to gray
                    if blob.blobType == Constants.BlobTypes.invisible
                    {
                        loopMapCirclesCheck: for circle in Constants.Data.mapCircles
                        {
                            if circle.title == blob.blobID
                            {
                                // Indicate that it is "not used on the main map" to get the gray color returned
                                circle.fillColor = Constants().blobColor(blob.blobType, mainMap: false)
                                
                                break loopMapCirclesCheck
                            }
                        }
                    }
                }
                else
                {
                    // Blob is not within user radius
                    
                    // If the Blob is not in range of the user's current location, but the Blob has already been viewed, then
                    // remove the Blob from the Map Blobs and the Map Circles
                    if blob.blobViewed
                    {
                        // Ensure blobType is not null
                        if let blobType = blob.blobType
                        {
                            // If the Blob Type is not Permanent, remove it from the Map View and Data
                            if blobType != Constants.BlobTypes.permanent && blobType != Constants.BlobTypes.blobjot
                            {
                                // Remove the Blob from the global array of locationBlobs so that it cannot be accessed
                                loopLocationBlobsCheck: for (index, lBlob) in Constants.Data.locationBlobs.enumerated()
                                {
                                    if lBlob.blobID == blob.blobID
                                    {
                                        Constants.Data.locationBlobs.remove(at: index)
                                        
                                        break loopLocationBlobsCheck
                                    }
                                }
                                
                                // Remove the Blob from the global array(s) of Blobs so that it cannot be accessed
                                loopTaggedBlobsCheck: for (index, tBlob) in Constants.Data.taggedBlobs.enumerated()
                                {
                                    if tBlob.blobID == blob.blobID
                                    {
                                        Constants.Data.taggedBlobs.remove(at: index)
                                        
                                        break loopTaggedBlobsCheck
                                    }
                                }
                                loopMapBlobsCheck: for (index, mBlob) in Constants.Data.mapBlobs.enumerated()
                                {
                                    if mBlob.blobID == blob.blobID
                                    {
                                        Constants.Data.mapBlobs.remove(at: index)
                                        
                                        break loopMapBlobsCheck
                                    }
                                }
                                
                                // Remove the Blob from the list of mapCircles so that is does not show on the mapView
                                loopMapCirclesCheck: for (index, circle) in Constants.Data.mapCircles.enumerated()
                                {
                                    if circle.title == blob.blobID
                                    {
                                        circle.map = nil
                                        Constants.Data.mapCircles.remove(at: index)
                                        
                                        break loopMapCirclesCheck
                                    }
                                }
                            }
                        }
                    }
                    // Since the Blob is not within the current radius, remove the extra data and change the color, if it is an invisible Blob
                    
                    // If the Blob is not in range of the user's current location, but the Blob's extra data has already been requested,
                    // delete the extra data and indicate that the Blob's extra data has not been requested
                    // If the Blob was deleted in the last IF statement (if viewed and not permanent), then this step is unnecessary
                    if blob.blobExtraRequested
                    {
                        // Remove all of the extra data
                        blob.blobText = nil
                        blob.blobThumbnailID = nil
                        blob.blobMediaType = nil
                        blob.blobMediaID = nil
                        
                        // Indicate that the extra data has not been requested
// *ISSUE ********** If the data has been requested, but not added to the Blob yet, it could be added again after this step, causing bugs
                        blob.blobExtraRequested = false
                    }
                    // If the Blob is invisible, change the circle back to clear
                    if blob.blobType == Constants.BlobTypes.invisible
                    {
                        loopMapCirclesCheck: for circle in Constants.Data.mapCircles
                        {
                            if circle.title == blob.blobID
                            {
                                circle.fillColor = Constants().blobColor(blob.blobType, mainMap: true)
                                
                                break loopMapCirclesCheck
                            }
                        }
                    }
                }
            }
            
            // Reload the Collection View
            self.refreshCollectionView()
            
            // Only hide the background activity indicator if the global sending property is false
            if !Constants.Data.stillSendingBlob && !self.waitingForMapData
            {
                self.hideBackgroundActivityView(false)
            }
        }
        else
        {
            // Show the low accuracy view
            self.lowAccuracyView.isHidden = false
            
            // Record that the user's location is inaccurate
            self.locationInaccurate = true
        }
    }
    
    
    // MARK: GOOGLE MAPS DELEGATES
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
    {
//        // Check whether any menu button is expanded - if so, close them
//        if menuButtonMapOpen
//        {
//            menuButtonMapOpen = false
//            
//            // Add an animation to hide the buttons
//            UIView.animate(withDuration: 0.2, animations:
//                {
//                    self.buttonTrackUser.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonTrackUserSize, y: 5, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize)
//                    self.buttonRefreshMap.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonTrackUserSize, y: 5, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize)
//                }, completion:
//                {(finished: Bool) -> Void in
//                    self.buttonSearchViewImage.image = UIImage(named: Constants.Strings.iconStringMapViewSearchCombo)
//            })
//        }
//        // However, only close the Blob menu buttons if the addingBlob indicator is false - if adding a Blob, the Blob menu buttons should remain expanded
//        if menuButtonBlobOpen && !addingBlob
//        {
//            menuButtonBlobOpen = false
//            
//            // Add an animation to hide the buttons
//            UIView.animate(withDuration: 0.2, animations:
//                {
//                    self.buttonListView.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonListSize, y: self.viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonListSize, width: Constants.Dim.mapViewButtonListSize, height: Constants.Dim.mapViewButtonListSize)
//                }, completion:
//                {(finished: Bool) -> Void in
//                    self.buttonAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewAddCombo)
//            })
//        }
        
        /*
         1 - Check to see if the tap is within a Blob on the map
                - If so, highlight the Blob on the map
         2 - Check to see if the tapped Blob is one of the locationBlobs
                - If so, show the full Preview AND highlight the userImage in the collection view
                - If not, show the short Preview
        */
        // Create a tapped Blob indicator property so only the hightest tapped Blob is selected, but all others are deselected
        var tappedBlob = false
        loopMapBlobs: for mBlob in Constants.Data.mapBlobs
        {
            // Mark all Blobs as not selected so that any map tap can deselect a currently selected Blob
            mBlob.blobSelected = false
            
            // Ensure that the Blob color and width are set back to it's default setting
            unhighlightMapCircleForBlob(mBlob)
            
            // Calculate the distance from the tap to the center of the Blob
            let tapFromBlobCenterDistance: Double! = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: CLLocation(latitude: mBlob.blobLat, longitude: mBlob.blobLong))
            
            // Check to see if the tap distance from the Blob is equal to or less than the Blob radius
            // and another Blob has not been tapped (the highest Blob should only be highlighted)
            // and the Blob is not invisible (unless the user is within the invisible Blob's radius)
            // If all that is true, highlight the edge of the Blob, show the Preview Box with the Blob
            if tapFromBlobCenterDistance <= mBlob.blobRadius && !tappedBlob && (mBlob.blobType != Constants.BlobTypes.invisible || mBlob.blobExtraRequested)
            {
                tappedBlob = true
                
                // Reset the Preview Box
                self.clearPreview()
                
                // Highlight the edge of the Blob
                loopMapCircles: for circle in Constants.Data.mapCircles
                {
                    if circle.title == mBlob.blobID
                    {
                        circle.strokeColor = Constants.Colors.blobHighlight
                        circle.strokeWidth = 3
                        
                        break loopMapCircles
                    }
                }
                
                // Show the Preview Box with the selected Blob data
                showBlobPreview(mBlob)
                
                // Loop through the Location Blob array to mark the top Blobs within tap range
                loopLocationBlobCheck: for lBlob in Constants.Data.locationBlobs
                {
                    // Mark all Blobs as not selected so that any map tap can deselect a currently selected Blob
                    lBlob.blobSelected = false
                    
                    // Calculate the distance from the tap to the center of the Blob
                    let tapFromBlobCenterDistance: Double! = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: CLLocation(latitude: lBlob.blobLat, longitude: lBlob.blobLong))
                    
                    // Check to see if the tap distance from the Blob is equal to or less than the Blob radius and
                    // if so, indicate that the Blob was tapped (this variable can be used to highlight the Blob within the Collection View)
                    if tapFromBlobCenterDistance <= lBlob.blobRadius
                    {
                        lBlob.blobSelected = true
                        
                        break loopLocationBlobCheck
                    }
                }
                
                // DO NOT STOP looping through Blobs after the first matched Blob - other Blobs may need to be unhighlighted
            }
        }
        
        // If a Blob was not tapped on the map, close the Preview Box
        if !tappedBlob
        {
            // Close the Preview Box - the user is not interacting with the Preview Box anymore
            self.closePreview()
        }
        
        // Reload the Collection View to ensure that any deselections also correct the User Image placement in the collection view
        self.refreshCollectionView()
    }
    
    // Called before the map is moved
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool)
    {
//        // Check whether any menu button is expanded - if so, close them
//        if menuButtonMapOpen
//        {
//            menuButtonMapOpen = false
//            
//            // Add an animation to hide the buttons
//            UIView.animate(withDuration: 0.2, animations:
//                {
//                    self.buttonTrackUser.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonTrackUserSize, y: 5, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize)
//                    self.buttonRefreshMap.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonTrackUserSize, y: 5, width: Constants.Dim.mapViewButtonTrackUserSize, height: Constants.Dim.mapViewButtonTrackUserSize)
//                }, completion:
//                {(finished: Bool) -> Void in
//                    self.buttonSearchViewImage.image = UIImage(named: Constants.Strings.iconStringMapViewSearchCombo)
//            })
//        }
//        // However, only close the Blob menu buttons if the addingBlob indicator is false - if adding a Blob, the Blob menu buttons should remain expanded
//        if menuButtonBlobOpen && !addingBlob
//        {
//            menuButtonBlobOpen = false
//            
//            // Add an animation to hide the buttons
//            UIView.animate(withDuration: 0.2, animations:
//                {
//                    self.buttonListView.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonListSize, y: self.viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonListSize, width: Constants.Dim.mapViewButtonListSize, height: Constants.Dim.mapViewButtonListSize)
//                }, completion:
//                {(finished: Bool) -> Void in
//                    self.buttonAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewAddCombo)
//            })
//        }
        
        // If the user is adding a Blob, do not allow them to zoom lower than mapViewAddBlobMinZoom (higher view)
        if addingBlob
        {
            if mapView.camera.zoom < Constants.Settings.mapViewAddBlobMinZoom
            {
                mapView.animate(toZoom: Constants.Settings.mapViewAddBlobMinZoom)
                
                // Display the message box to explain the zoom minimum
                self.showSelectorMessageBox()
            }
            else if mapView.camera.zoom == Constants.Settings.mapViewAddBlobMinZoom
            {
                // Display the message box to explain the zoom minimum
                self.showSelectorMessageBox()
            }
            else
            {
                // Hide the message box
                self.hideSelectorMessageBox()
            }
        }
    }
    
    // Called after the map is moved
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition)
    {
        // Adjust the Map Camera back to apply the correct camera angle
        adjustMapViewCamera()
        
        // Check the markers again since the zoom may have changed
        addMarkersToBlobs()
    }
    
    // Add markers for Blobs on the map
    func addMarkersToBlobs()
    {
        // Check each circle radius compared to the zoom height and add a marker if the zoom is too low for a Blob size
        // Nullify all current markers
        for marker in self.blobMarkers
        {
            marker.map = nil
        }
        self.blobMarkers = [GMSMarker]()
        for blob in Constants.Data.mapBlobs
        {
            // Add the marker to the map for the Blob if the radius of the marker is the same or larger than the visible radius of the Blob
            // The equation relating Blob radius to Camera Zoom is:  Radius = Zoom * -30 + 480
            if blob.blobRadius <= (Double(mapView.camera.zoom) * -30) + 480
            {
                addMarker(blob)
            }
        }
    }
    
    func addMarker(_ blob: Blob)
    {
        let dotDiameter: CGFloat = 6
        let dot = UIImage(color: Constants().blobColorOpaque(blob.blobType, mainMap: true), size: CGSize(width: dotDiameter, height: dotDiameter))
        let markerView = UIImageView(image: dot)
        markerView.layer.cornerRadius = markerView.frame.height / 2
        markerView.contentMode = UIViewContentMode.scaleAspectFill
        markerView.clipsToBounds = true
        
        let position = CLLocationCoordinate2DMake(blob.blobLat, blob.blobLong)
        let marker = GMSMarker(position: position)
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.title = ""
        marker.iconView = markerView
        marker.tracksViewChanges = false
        marker.map = mapView
        self.blobMarkers.append(marker)
    }
    
    // Show the selectorMessageBox
    func showSelectorMessageBox()
    {
        // Add an animation to show and then hide the selectorMessageBox //0 - (self.selectorBoxHeight + 10)
        UIView.animate(withDuration: 0.5, animations:
            {
                self.selectorMessageBox.frame = CGRect(x: (self.viewContainer.frame.width / 2) - (self.selectorBoxWidth / 2), y: 10, width: self.selectorBoxWidth, height: self.selectorBoxHeight)
            }, completion: nil)
    }
    // Hide the selectorMessageBox
    func hideSelectorMessageBox()
    {
        // Add an animation to show and then hide the selectorMessageBox //0 - (self.selectorBoxHeight + 10)
        UIView.animate(withDuration: 0.5, animations:
            {
                self.selectorMessageBox.frame = CGRect(x: (self.viewContainer.frame.width / 2) - (self.selectorBoxWidth / 2), y: -self.selectorBoxHeight, width: self.selectorBoxWidth, height: self.selectorBoxHeight)
            }, completion: nil)
    }
    
    // Adjust the Map Camera settings to allow or disallow angling the camera view
    // If not in the add blob process, angle the map automatically if the zoom is high enough
    func adjustMapViewCamera()
    {
        if !addingBlob
        {
            // When not in the add blob process, if the map zoom is 16 or higher, automatically angle the camera
            if mapView.camera.zoom >= 16 && mapView.camera.viewingAngle < 60
            {
                let desiredAngle = Double(60)
                mapView.animate(toViewingAngle: desiredAngle)
                
            }
            else if mapView.camera.zoom < 16 && mapView.camera.viewingAngle > 0
            {
                // Keep the map from being angled if the zoom is too low
                let desiredAngle = Double(0)
                mapView.animate(toViewingAngle: desiredAngle)
            }
        }
        else
        {
            // When in the add blob process, do not allow the map camera to angle
            let desiredAngle = Double(0)
            mapView.animate(toViewingAngle: desiredAngle)
            
            // If the zoom is less than mapViewAddBlobMinZoom, zoom in to mapViewAddBlobMinZoom (enough to allow a Blob to encompass a city block)
            if mapView.camera.zoom < Constants.Settings.mapViewAddBlobMinZoom
            {
                mapView.animate(toZoom: Constants.Settings.mapViewAddBlobMinZoom)
            }
            else if mapView.camera.zoom == Constants.Settings.mapViewAddBlobMinZoom
            {
                // Display the message box to explain the zoom minimum
                self.showSelectorMessageBox()
            }
            else
            {
                // Hide the message box
                self.hideSelectorMessageBox()
            }
        }
    }
    
    // Manually set the mapView camera
    func setMapCamera(_ coords: CLLocationCoordinate2D, zoom: Float, viewingAngle: Double?)
    {
        if viewingAngle == nil
        {
            self.mapView.camera = GMSCameraPosition(target: coords, zoom: zoom, bearing: CLLocationDirection(0), viewingAngle: mapView.camera.viewingAngle)
        }
        else
        {
            self.mapView.camera = GMSCameraPosition(target: coords, zoom: zoom, bearing: CLLocationDirection(0), viewingAngle: viewingAngle!)
        }
    }
    
    
    // MARK: SLIDER LISTENERS
    // This is the listener for the slider used in the Add Blob process
    func sliderValueDidChange(_ sender: UISlider!)
    {
        // Use the slider value as the new radius for the Add Blob circle
        let circleNewSize: CGFloat = CGFloat(sender.value) * 2
        
        // Resize the Add Blob circle
        selectorCircle.frame = CGRect(x: (mapView.frame.width / 2) - (circleNewSize / 2), y: (mapView.frame.height / 2) - (circleNewSize / 2), width: circleNewSize, height: circleNewSize)
        selectorCircle.layer.cornerRadius = circleNewSize / 2
    }
    
    
    // MARK: UI COLLECTION VIEW DATA SOURCE PROTOCOL
    
    // Number of cells to make in CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        // Resize the Location Blobs Collection View so that it only is tall enough to show all the Blobs
        // Otherwise, the Map View would be blocked by the Collection View and not allow touch responses
        
        // Calculate the height of all the cells together (multiplied by the number of Blobs)
        let maxCVHeight = Constants.Dim.mapViewLocationBlobsCVCellSize * CGFloat(Constants.Data.locationBlobs.count)
        // Determine the height of the viewContainer
        var cvHeight = viewContainer.frame.height
        // If the max height of all Blob cells together is less than the View Container height, then use the smaller height (the total cell(s) height)
        if maxCVHeight < cvHeight
        {
            cvHeight = maxCVHeight
        }
        locationBlobsCollectionViewContainer.frame.size.height = cvHeight
        locationBlobsCollectionView.frame.size.height = cvHeight
        
        return Constants.Data.locationBlobs.count
    }
    
    // Create cells for CollectionView
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        // Create reference to CollectionView cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Strings.locationBlobsCellReuseIdentifier, for: indexPath) as! LocationBlobsCollectionViewCell
        
        // Reset the needed views and start the indicator animation
        cell.userImage.image = nil
        cell.userImageActivityIndicator.startAnimating()
        
        // When the Blob is indicated as selected (blobSelected), the User Image is moved 10dp to the right (see below)
        // Reset the User Image location for all Blobs in case the Blob is no longer selected
        cell.userImageContainer.frame = CGRect(x: 5, y: 5, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize)
        
        
        // If the cell is the first one, it is the default blob, so show the Blobjot logo
        if (indexPath as NSIndexPath).row > 0
        {
            // Ensure that the blob is not a BLOBJOT BLOB
            if Constants.Data.locationBlobs[(indexPath as NSIndexPath).row].blobType != Constants.BlobTypes.blobjot
            {
                // Add the associated User Image to the User Image View
                if let userID = Constants.Data.locationBlobs[(indexPath as NSIndexPath).row].blobUserID
                {
                    // Find the correct User Object in the global list and assign the User Image, if it exists
                    loopUserObjectCheck: for userObject in Constants.Data.userObjects
                    {
                        if userObject.userID == userID
                        {
                            if userObject.userImage != nil
                            {
                                cell.userImage.image = userObject.userImage
                                cell.userImageActivityIndicator.stopAnimating()
                            }
                            
                            break loopUserObjectCheck
                        }
                    }
                }
            }
            else
            {
                // Assign the default Public Area Blob to the user data features
                cell.userImage.image = Constants.Data.userPublicArea.userImage
                cell.userImageActivityIndicator.stopAnimating()
            }
        }
        else
        {
            cell.userImage.image = UIImage(named: Constants.Strings.iconStringBlobjotLogo)
            cell.userImageActivityIndicator.stopAnimating()
        }
        
        // Check to see if the Blob has been selected, and move the User Image to the right
        if Constants.Data.locationBlobs[(indexPath as NSIndexPath).row].blobSelected
        {
            cell.userImageContainer.frame = CGRect(x: 5 + Constants.Dim.mapViewLocationBlobsCVHighlightAdjustSize, y: 5, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize)
        }
        return cell
    }
    
    
    // MARK: UI COLLECTION VIEW DELEGATE PROTOCOL
    
    // Cell Selection Blob
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
//        // Close the Search Box - the user is not interacting with this feature anymore
//        self.closeSearchBox()
        
        // Clear the Preview Box for new Blob data
        self.clearPreview()
        
        // Loop through the Map Blobs, reset the Map Circles' borders, find the matching Location Blob and highlight its border
        // Do NOT break the Map Blobs loop early.  All Map Blobs should be checked and corresponding Map Circle's border reset
        for mBlob in Constants.Data.mapBlobs
        {
            mBlob.blobSelected = false
            
            // Reset the border for the Map Circle that matches the Map Blob
            unhighlightMapCircleForBlob(mBlob)
            
            // Check whether the current Map Blob matches the Location Blob at the selected index
            // If so, find the Map Circle that matches the current Map Blob and highlight that Map Circle's border
            if mBlob.blobID == Constants.Data.locationBlobs[(indexPath as NSIndexPath).row].blobID
            {
                mBlob.blobSelected = true
                
                // Reload the Collection View
                self.refreshCollectionView()
                
                loopMapCircles: for circle in Constants.Data.mapCircles
                {
                    if circle.title == mBlob.blobID
                    {
                        circle.strokeColor = Constants.Colors.blobHighlight
                        circle.strokeWidth = 3
                        
                        break loopMapCircles
                    }
                }
            }
        }
        
        // Call the function to prepare and show the Preview Box using the data from the Location Blob at the selected index
        showBlobPreview(Constants.Data.locationBlobs[(indexPath as NSIndexPath).row])
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Cell Touch Blob
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
    {
    }
    
    // Cell Touch Release Blob
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
    {
    }
    
    
    // MARK: FBSDK METHODS
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!)
    {
        if ((error) != nil)
        {
            print("MVC - FBSDK ERROR: \(error)")
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
        }
        else if result.isCancelled
        {
            print("MVC - FBSDK IS CANCELLED: \(result.description)")
            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: result.debugDescription)
        }
        else
        {
            // Show the logging in indicator and label
            loginActivityIndicator.startAnimating()
            loginBox.addSubview(loginProcessLabel)
            
            // Set the new login indicator for certain settings
            self.newLogin = true
            
            // Now that the Facebook token has been retrieved, get the Cognito IdentityID
            print("MVC - FBSDK TOKEN: \(FBSDKAccessToken.current())")
            AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self as AWSRequestDelegate).prepRequest()
            
            // Call APNS registration again (need to also log in to AWS SNS, but do this first)
            let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
            let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(pushNotificationSettings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool
    {
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
        
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!)
    {
        print("MVC - FBSDK DID LOG OUT: \(loginButton)")
        
        Constants.credentialsProvider.clearCredentials()
        Constants.credentialsProvider.clearKeychain()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
//    // Check to see if the Search Bar is visible, and if so animate the container to hide it behind the Status Bar
//    // Once the animation completes, remove the Search Bar Container from the view container
//    func closeSearchBox()
//    {
//        if searchBarVisible
//        {
//            // Hide the search marker
//            if searchMarker != nil
//            {
//                searchMarker!.map = nil
//            }
//            
//            searchBarVisible = false
//            
//            // Add an animation to raise the search button container out of view
//            UIView.animate(withDuration: 0.2, animations:
//                {
//                    self.searchBarContainer.frame = CGRect(x: 0, y: 0 - Constants.Dim.mapViewSearchBarContainerHeight, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewSearchBarContainerHeight)
//                    self.buttonSearchView.layer.shadowOffset = CGSize(width: 0, height: 0.0)
//                    self.buttonSearchView.layer.shadowOpacity = 0.2
//                    self.buttonSearchView.layer.shadowRadius = 0.0
//                }, completion:
//                {
//                    (value: Bool) in
//                    self.buttonSearchView.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
//                    self.buttonSearchView.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
//                    self.buttonSearchView.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
//                    
//                    // Remove the Search Box from the view container so that a flip animation to show a new view controller
//                    // does not show the Search Box above the Status Bar
//                    self.searchBarContainer.removeFromSuperview()
//            })
//        }
//    }
    
    // Check to see if the Preview Box is low enough to be visible
    // If so, animate the raising of the Preview Box out of view
    func closePreview()
    {
        if previewContainer.frame.minY > -45
        {
            // Add an animation to raise the preview container out of view
            UIView.animate(withDuration: 0.2, animations:
                {
                    self.previewContainer.frame = CGRect(x: 0, y: 0 - Constants.Dim.mapViewPreviewContainerHeight, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight)
                }, completion:
                {
                    (value: Bool) in
                    self.clearPreview()
            })
        }
    }
    
    // Reset all Preview Box settings and values
    func clearPreview()
    {
        self.previewThumbnailView.image = nil
        self.previewTextBox.text = nil
        self.previewUserImageView.image = UIImage(named: "PROFILE_DEFAULT.png")
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
    func refreshPreviewUserData(_ user: User)
    {
        // Refresh the User Name
        self.previewUserNameLabel.text = user.userName
        self.previewUserNameActivityIndicator.stopAnimating()
        
        // Refresh the User Image, if it exists
        if user.userImage != nil
        {
            self.previewUserImageView.image = user.userImage
            self.previewUserImageActivityIndicator.stopAnimating()
        }
    }
    
    func hideBackgroundActivityView(_ refreshBlobs: Bool)
    {
        // Stop the refresh Map button indicator if it is running
        self.buttonRefreshMapActivityIndicator.stopAnimating()
        self.backgroundActivityView.removeFromSuperview()
        
        // If indicated, refresh the map data in case it was changed
        if refreshBlobs
        {
            if let currentLocation = mapView.myLocation
            {
                self.refreshBlobs(currentLocation)
            }
        }
    }
    
    func bringAddBlobViewControllerTopOfStack(_ newVC: Bool)
    {
        if newVC || addBlobVC == nil
        {
            addBlobVC = BlobAddViewController()
            addBlobVC!.blobAddViewDelegate = self
            // Pass the Blob coordinates and the current map zoom to the new View Controller
            addBlobVC!.blobCoords = mapView.camera.target
            addBlobVC!.mapZoom = mapView.camera.zoom
//            addBlobVC.mapZoom = UtilityFunctions().mapZoomForBlobSize(Float(self.blobRadius))
            
            // Create a Nav Bar Back Button and Title
            let backButtonItem = UIBarButtonItem(title: "CANCEL",
                                                 style: UIBarButtonItemStyle.plain,
                                                 target: self,
                                                 action: #selector(self.popViewController(_:)))
            backButtonItem.tintColor = Constants.Colors.colorTextNavBar
            
            let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
            let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
            ncTitleText.text = "Create Blob"
            ncTitleText.textColor = Constants.Colors.colorTextNavBar
            ncTitleText.textAlignment = .center
            ncTitle.addSubview(ncTitleText)
            
            // Calculate the slider point location and extrapolate the Blob radius based on the map zoom
            let sliderPoint = CGPoint(x: (mapView.frame.width / 2) + (selectorCircle.frame.width / 2), y: mapView.frame.height / 2)
            let point = self.mapView.projection.coordinate(for: sliderPoint)
            
            let mapCenterLocation = CLLocation(latitude: mapView.camera.target.latitude, longitude: mapView.camera.target.longitude)
            let sliderLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
            
            // Pass the Blob Radius to the View Controller
            addBlobVC!.blobRadius = mapCenterLocation.distance(from: sliderLocation)
            addBlobVC!.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            addBlobVC!.navigationItem.titleView = ncTitle
        }
        
        // Add the View Controller to the Nav Controller and present the Nav Controller
        let navController = UINavigationController(rootViewController: addBlobVC!)
        navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
        self.modalPresentationStyle = .popover
        self.present(navController, animated: true, completion: nil)
        
        // Reset the button settings and remove the elements used in the Add Blob Process
        buttonAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewAdd)
        
        buttonCancelAdd.removeFromSuperview()
        selectorMessageBox.removeFromSuperview()
        selectorCircle.removeFromSuperview()
        selectorSlider.removeFromSuperview()
        
//        // Double-check that the Blob menu buttons are still expanded, and hide them if they are visible
//        if menuButtonBlobOpen
//        {
//            menuButtonBlobOpen = false
//            
//            // Add an animation to hide the buttons
//            UIView.animate(withDuration: 0.2, animations:
//                {
//                    self.buttonListView.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonListSize, y: self.viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonListSize, width: Constants.Dim.mapViewButtonListSize, height: Constants.Dim.mapViewButtonListSize)
//                }, completion:
//                {(finished: Bool) -> Void in
//                    self.buttonAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewAddCombo)
//            })
//        }
        
        // Change the add blob indicator back to false efore calling adjustMapViewCamera
        addingBlob = false
        
        // Adjust the Map Camera back to allow the map can be viewed at an angle
        adjustMapViewCamera()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // The function to lower the previewBox
    func lowerPreviewBox()
    {
        //Stop animating the activity indicator (if not already stopped)
        self.previewThumbnailActivityIndicator.stopAnimating()
        
        self.previewTimeLabel.frame = CGRect(x: previewContainer.frame.width - 5 - self.previewTimeLabelWidth, y: 5, width: self.previewTimeLabelWidth, height: 15)
        self.previewTextBox.frame = CGRect(x: 50, y: 10 + previewUserNameLabel.frame.height, width: previewContainer.frame.width - 65, height: 15)
    }
    
    // Add Blob data to the Preview Box elements and animate the Preview Box lowering into view
    func showBlobPreview(_ blob: Blob)
    {
        //Animate the activity indicator
        self.previewThumbnailActivityIndicator.startAnimating()
        self.previewUserImageActivityIndicator.startAnimating()
        self.previewUserNameActivityIndicator.startAnimating()
        
        // Assign the local previewBlob to the passed blob so that other functions can access the selected blob
        self.previewBlob = blob
        
        // If Blob extra data has been requested, the Blob is in range, so download the Thumbnail,
        // otherwise, move the Blob age and text all the way to the right side of the Preview Box
        if blob.blobExtraRequested
        {
            // Check whether the Blob has media - if not, do not show the Thumbnail box
            if blob.blobMediaType != nil && blob.blobMediaType == 0
            {
                self.lowerPreviewBox()
            }
            else
            {
                // Check to see if the thumbnail was already downloaded
                // If not, the return function from AWS will apply the thumbnail to the preview box
                // Loop through the BlobThumbnailObjects array
                loopThumbnail: for tObject in Constants.Data.blobThumbnailObjects
                {
                    // Check each thumbnail object to see if matches
                    if tObject.blobThumbnailID == blob.blobThumbnailID
                    {
                        // Check to make sure the thumbnail has already been downloaded
                        if let thumbnailImage = tObject.blobThumbnail
                        {
                            // Setthe Preview Thumbnail image
                            self.previewThumbnailView.image = thumbnailImage
                            
                            // Stop animating the activity indicator
                            self.previewThumbnailActivityIndicator.stopAnimating()
                            
                            // Assign the thumbnail image to the previewBlob
                            self.previewBlob?.blobThumbnail = thumbnailImage
                            
                            break loopThumbnail
                        }
                    }
                }
            }
        }
        else
        {
            self.lowerPreviewBox()
        }
        
        // Check whether the Blob is the default (first) Blob in the Location Blob list
        // Otherwise, find the associated User Image and User Name for the Blob User ID as add them to the proper Preview Box elements
        if blob.blobID == "default"
        {
            previewUserImageView.image = UIImage(named: Constants.Strings.iconStringBlobjotLogo)
            previewUserNameLabel.text = "Blobjot"
            previewTimeLabel.text = "Since 2016"
            
            // Assign the user to the previewBlobUser
            self.previewBlobUser = defaultBlobUser
            
            //Stop animating the activity indicator
            self.previewThumbnailActivityIndicator.stopAnimating()
            self.previewUserImageActivityIndicator.stopAnimating()
            self.previewUserNameActivityIndicator.stopAnimating()
        }
        else if blob.blobType == Constants.BlobTypes.blobjot
        {
            previewUserImageView.image = UIImage(named: Constants.Strings.iconStringBlobjotLogo)
            previewUserNameLabel.text = "Public Area"
            
            // Display the current year
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY"
            let stringDate: String = dateFormatter.string(from: Date())
            previewTimeLabel.text = stringDate
            
            // Create and assign a user to the previewBlobUser
            let publicAreaUser = User()
            publicAreaUser.userID = "blobjotBlob"
            publicAreaUser.facebookID = "blobjotBlob"
            publicAreaUser.userName = "Public Area"
            publicAreaUser.userImage = UIImage(named: Constants.Strings.iconStringBlobjotLogo)
            self.previewBlobUser = publicAreaUser
            
            //Stop animating the activity indicator
            self.previewThumbnailActivityIndicator.stopAnimating()
            self.previewUserImageActivityIndicator.stopAnimating()
            self.previewUserNameActivityIndicator.stopAnimating()
        }
        else
        {
            // Check if the user has already been downloaded ONLY IF NOT A BLOBJOT BLOB
            // If a Blob outside the range of the user was clicked, the user may not have already been downloaded
            if blob.blobType != Constants.BlobTypes.blobjot
            {
                var userExists = false
                loopUserCheck: for user in Constants.Data.userObjects
                {
                    if user.userID == blob.blobUserID
                    {
                        userExists = true
                        
                        // Assign the user to the previewBlobUser
                        self.previewBlobUser = user
                        
                        // Assign the user's image and username to the preview
                        if user.userName != nil
                        {
                            previewUserNameLabel.text = user.userName
                            self.previewUserNameActivityIndicator.stopAnimating()
                            
                            if user.userImage != nil
                            {
                                previewUserImageView.image = user.userImage
                                self.previewUserImageActivityIndicator.stopAnimating()
                            }
                            else
                            {
                                AWSPrepRequest(requestToCall: FBGetUserProfileData(user: user, downloadImage: true), delegate: self as AWSRequestDelegate).prepRequest()
                            }
                        }
                        else
                        {
                            AWSPrepRequest(requestToCall: FBGetUserProfileData(user: user, downloadImage: true), delegate: self as AWSRequestDelegate).prepRequest()
                        }
                        
                        break loopUserCheck
                    }
                }
                // If the user has not been downloaded, request the user and the userImage
                if !userExists
                {
                    AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: blob.blobUserID, forPreviewBox: true), delegate: self as AWSRequestDelegate).prepRequest()
                }
            }
            else
            {
                self.updatePreviewBoxData(Constants.Data.userPublicArea)
            }
            
            // Set the Preview Time Label to show the age of the Blob
            if let datetime = blob.blobDatetime
            {
                // Capture the number of hours it has been since the Blob was created (as a positive integer)
                let dateAgeHrs: Int = -1 * Int(datetime.timeIntervalSinceNow / 3600)
                
                // Set the date age label.  If the age is less than 24 hours, just show it in hours.  Otherwise, show the number of days and hours.
                var stringAge = String(dateAgeHrs / Int(24)) + " days" //+ String(dateAgeHrs % 24) + " hrs"
                if dateAgeHrs < 24
                {
                    stringAge = String(dateAgeHrs) + " hrs"
                }
                else if dateAgeHrs < 48
                {
                    stringAge = "1 day"
                }
                previewTimeLabel.text = stringAge
            }
        }
        
        // Check whether the Blob text has been added to the Blob, and if so, display the text
        // If not, check whether the extra data has already been requested
        // if not, this means the Blob is not (or has not been) in range
        // If it has been requested, but no text exists, do nothing (leave the text area blank)
        if let bText = blob.blobText
        {
            previewTextBox.textColor = Constants.Colors.colorPreviewTextNormal
            previewTextBox.text = bText
        }
        else if !blob.blobExtraRequested
        {
            previewTextBox.textColor = Constants.Colors.colorPreviewTextError
            previewTextBox.text = "This Blob is not in range."
        }
        
        // Add an animation to lower the preview container into view
        UIView.animate(withDuration: 0.2, animations:
            {
                self.previewContainer.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight)
            }, completion: nil)
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Loop through the Map Blobs, check if they have already been added as Map Circles, and create a Map Circle if needed
    func addMapBlobsToMap()
    {
        print("MVC-AMBM - ADDING MAP BLOBS")
        // Loop through Map Blobs and check for corresponding Map Circles
        for addBlob in Constants.Data.mapBlobs
        {
            var blobExists = false
            loopCircleCheck: for circle in Constants.Data.mapCircles
            {
                if circle.title == addBlob.blobID
                {
                    blobExists = true
                    print("MVC-AMBM - BLOB EXISTS")
                    break loopCircleCheck
                }
            }
            
            // If a corresponding Map Circle does not exist, call createBlobOnMap to create a new one
            if !blobExists
            {
                print("MVC-AMBM - BLOB DOES NOT EXIST")
                // Call local function to create a new Circle and add it to the Map View
                self.createBlobOnMap(addBlob)
            }
        }
        
        // Now add the markers to the Blobs
        self.addMarkersToBlobs()

        // ADDED FOR MANUAL LOCATION RELOAD
        // Reload the current location's Blobs to show in the Collection View
        refreshBlobsForCurrentLocation()
    }
    
    // Receive the Blob data, create a new GMSCircle, and add it to the local Map View
    func createBlobOnMap(_ blob: Blob)
    {
        let blobCenter = CLLocationCoordinate2DMake(blob.blobLat, blob.blobLong)
        
        let addCircle = GMSCircle()
        addCircle.position = blobCenter
        addCircle.radius = blob.blobRadius
        addCircle.title = blob.blobID
        addCircle.fillColor = Constants().blobColor(blob.blobType, mainMap: true)
        addCircle.strokeColor = Constants().blobColor(blob.blobType, mainMap: true)
        addCircle.strokeWidth = 1
        // If the Blob is a Blobjot (Public) Blob, and it contains user-liked keywords, highlight the Blob edge
        if blob.blobPublicInterest
        {
            addCircle.strokeColor = Constants().blobColorOpaque(blob.blobType, mainMap: true)
            addCircle.strokeWidth = 5
        }
        addCircle.map = self.mapView
        Constants.Data.mapCircles.append(addCircle)
        print("MVC-AMBM - ADDED CIRCLE")
//        let path = UtilityFunctions().pathForCoordinate(blobCenter, withMeterRadius: blobRadius)
//        let blob = GMSPolyline(path: path)
//        blob.map = self.mapView
    }
    
    func getImageWithColor(_ color: UIColor, size: CGSize) -> UIImage
    {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // Loop through all Map Circles and remove all highlighting (set back to normal)
    func unhighlightMapCircleForBlob(_ blob: Blob)
    {
        loopMapCircles: for circle in Constants.Data.mapCircles
        {
            if circle.title == blob.blobID
            {
                circle.strokeColor = Constants().blobColor(blob.blobType, mainMap: true)
                circle.strokeWidth = 1
                
                break loopMapCircles
            }
        }
    }
    
    // Create an alert screen with only an acknowledgment option (an "OK" button)
    func createAlertOkView(_ title: String, message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: OTHER DELEGATE METHODS
    func logoutUser()
    {
        // The logged in username has been cleared, so run the login process again to show the login screen
        AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    
    func displayNotification(_ blob: Blob)
    {
    }
    
    func refreshCollectionView()
    {
        // Reload the Collection View
        self.locationBlobsCollectionView.performSelector(onMainThread: #selector(UICollectionView.reloadData), with: nil, waitUntilDone: true)
        
        // Reload the current location blob view table if it is not nil
        if self.activeBlobsVC != nil
        {
            self.activeBlobsVC!.reloadTableView()
        }
    }
    
    func updateBlobActionTable()
    {
        if self.activeBlobsVC != nil
        {
            self.activeBlobsVC!.reloadTableView()
        }
    }
    
    func updatePreviewBoxData(_ user: User)
    {
        // Assign the user to the previewBlobUser
        self.previewBlobUser = user
        
        // Set the preview box with the downloaded data
        self.previewUserNameLabel.text = user.userName
        
        // If the new User data is for the same user and the Preview user and the preview User data is nil, refresh the preview box
        if let pBlob = self.previewBlob
        {
            if pBlob.blobUserID == user.userID && self.previewUserNameLabel.text == nil
            {
                self.refreshPreviewUserData(user)
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        self.showLoginScreenBool = true
        
        self.viewContainer.addSubview(loginScreen)
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSLoginUser:
                    if success
                    {
                        if self.newLogin
                        {
                            // Load the account view to show the logged in user
                            self.loadSettingsTabViewController(true)
                            self.showLoginScreenBool = false
                            
                            // Hide the logging in screen, indicator, and label
                            self.loginScreen.removeFromSuperview()
                            self.loginActivityIndicator.stopAnimating()
                            self.loginProcessLabel.removeFromSuperview()
                        }
                        else
                        {
                            // Since the first attempt to download the map data would have failed if the user was not logged in, refresh it again
                            // Recall the Tutorial Views data in Core Data.  If it is empty for the current ViewController's tutorial, it has not been seen by the curren user.
                            let tutorialViews = CoreDataFunctions().tutorialViewRetrieve()
                            if tutorialViews.tutorialMapViewDatetime != nil
                            {
                                self.refreshMap()
                            }
                        }
                    }
                    else
                    {
                        // Hide the logging in indicator and label
                        self.loginActivityIndicator.stopAnimating()
                        self.loginProcessLabel.removeFromSuperview()
                        
                        // Show the error message
                        self.createAlertOkView("Login Error", message: "We're sorry, but we seem to have an issue logging you in.  Please tap the \"Log out\" button and try logging in again.")
                        
                        print("LOGIN - MVC - ***** LOG IN ERROR *****")
                        
                        // Increase the server attempt count above the maximum to immediately stop any requests
                        Constants.Data.serverTries = 6
                        
                        // Show the login screen for manual login
                        self.showLoginScreen()
                    }
                case _ as AWSGetMapData:
                    if success
                    {
                        // Attempt to call the local function to add the Map Blobs to the Map
                        self.addMapBlobsToMap()
                        print("MVC - AWSGetMapData Returned - called addBlobsToMap")
                        
                        // Reset the waiting for map data indicator
                        self.waitingForMapData = false
                    }
                    else
                    {
                        // Show the error message
                        self.createAlertOkView("AWSGetMapData Network Error", message: "I'm sorry, you appear to be having network issues.  Please refresh the map to try again.")
                    }
                case _ as AWSGetBlobjotBlobs:
                    if success
                    {
                        // Attempt to call the local function to add the Map Blobs to the Map
                        self.addMapBlobsToMap()
                    }
                    else
                    {
                        // Show the error message
                        self.createAlertOkView("AWSGetBlobjotBlobs Network Error", message: "I'm sorry, you appear to be having network issues.  Please refresh the map to try again.")
                    }
                case let awsGetBlobData as AWSGetBlobExtraData:
                    if success
                    {
                        // Refresh the collection view and show the blob notification if needed
                        self.refreshCollectionView()
                        self.displayNotification(awsGetBlobData.blob)
                        
                        // Refresh child VCs
                        if self.blobVC != nil
                        {
                            self.blobVC.refreshBlobViewTable()
                        }
                    }
                    else
                    {
                        // Show the error message
                        self.createAlertOkView("AWSGetBlobExtraData Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    }
                case let awsGetThumbnailImage as AWSGetThumbnailImage:
                    if success
                    {
                        // Loop through the BlobThumbnailObjects array
                        loopThumbnail: for tObject in Constants.Data.blobThumbnailObjects
                        {
                            // Check each thumbnail object to see if matches
                            if tObject.blobThumbnailID == awsGetThumbnailImage.blob.blobThumbnailID
                            {
                                // Check to make sure the thumbnail has already been downloaded
                                if let thumbnailImage = tObject.blobThumbnail
                                {
                                    // Ensure that the same Blob is being previewed
                                    if let previewBlob = self.previewBlob
                                    {
                                        if previewBlob.blobID == awsGetThumbnailImage.blob.blobID
                                        {
                                            // Setthe Preview Thumbnail image
                                            self.previewThumbnailView.image = thumbnailImage
                                            
                                            // Stop animating the activity indicator
                                            self.previewThumbnailActivityIndicator.stopAnimating()
                                            
                                            // Assign the thumbnail image to the previewBlob
                                            self.previewBlob?.blobThumbnail = thumbnailImage
                                        }
                                    }
                                    
                                    break loopThumbnail
                                }
                            }
                        }
                    }
                    else
                    {
                        // Show the error message
                        self.createAlertOkView("AWSGetThumbnailImage Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    }
                case let awsGetSingleUserData as AWSGetSingleUserData:
                    if success
                    {
                        // Refresh the collection view
                        self.refreshCollectionView()
                        
                        // If the Blob Active View Controller is not null, send a refresh command so that the Parent VC's Child's VC's Table View's rows look for the new data
                        self.updateBlobActionTable()
                        
                        // If the MapView called this method to update the Preview Box, send the needed data to the PreviewBox
                        if awsGetSingleUserData.forPreviewBox!
                        {
                            self.updatePreviewBoxData(awsGetSingleUserData.user)
                        }
                        
                        // Refresh child VCs
                        if self.blobVC != nil
                        {
                            self.blobVC.refreshBlobViewTable()
                        }
                    }
                    else
                    {
                        // Show the error message
                        self.createAlertOkView("AWSGetSingleUserData Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    }
                case let FBGetUserProfileData as FBGetUserProfileData:
                    // Do not distinguish between success and failure for this class - both need to have the userList updated
                    // Refresh the collection view
                    self.refreshCollectionView()
                    
                    // If the Blob Active View Controller is not null, send a refresh command so that the Parent VC's Child's VC's Table View's rows look for the new data
                    self.updateBlobActionTable()
                    
                    // Update the preview data
                    self.refreshPreviewUserData(FBGetUserProfileData.user)
                    
                    // Refresh child VCs
                    if self.blobVC != nil
                    {
                        self.blobVC.refreshBlobViewTable()
                    }
                default:
                    print("MVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    self.createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                }
        })
    }
    
}
