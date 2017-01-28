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


class MapViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, GMSMapViewDelegate, GMSAutocompleteResultsViewControllerDelegate, FBSDKLoginButtonDelegate, AWSRequestDelegate, PeopleViewControllerDelegate, BlobAddViewControllerDelegate, HoleViewDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // The components of the menu view
    var menuContainer: UIView!
    var menuAccountContainer: UIView!
    var displayUserImageContainer: UIView!
    var displayUserImageActivityIndicator: UIActivityIndicatorView!
    var displayUserImage: UIImageView!
    var displayUserLabel: UILabel!
    var displayUserLabelActivityIndicator: UIActivityIndicatorView!
    
    var logoutButton: UIView!
    var logoutButtonLabel: UILabel!
    var locationButton: UIView!
    var locationButtonLabel: UILabel!
    
    var menuPeopleTableButton: UIView!
    var menuPeopleTableButtonLabel: UILabel!
    var menuInterestsTableButton: UIView!
    var menuInterestsTableButtonLabel: UILabel!
    var menuFilterUserBlobsButton: UIView!
    var menuFilterUserBlobsButtonLabel: UILabel!
    
    // The views to hold major components of the view controller
    var viewContainer: UIView!
    var statusBarView: UIView!
    var mapView: GMSMapView!
    
    // The view components for adding a view Blob
    var selectorMessageBox: UIView!
    var selectorMessageLabel: UILabel!
    var selectorCircle: UIView!
    var selectorSlider: UISlider!
    var selectorTypeMessageBox: UIView!
    var selectorTypeMessageLabel: UILabel!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    
    // The preview container will display a preview message for the Blob content
    var previewContainer: UIView!
    var previewActivityIndicator: UIActivityIndicatorView!
    var previewCollectionView: UICollectionView!
    var previewCVLayout: UICollectionViewFlowLayout!
    var previewCountCircleLeft: UIView!
    var previewCountLabelLeft: UILabel!
    var previewCountCircleRight: UIView!
    var previewCountLabelRight: UILabel!
    
    // The location blob collection view will show which Blobs are currently in range
    var locationBlobContentCollectionViewContainer: UIView!
    var locationBlobContentCollectionView: UICollectionView!
    var locationBlobContentCVLayout: UICollectionViewFlowLayout!
    
    // The navigation buttons to show other view controllers
    var buttonAdd: UIView!
    var buttonAddImage: UIImageView!
    var buttonCancelAdd: UIView!
    var buttonCancelAddImage: UIImageView!
    var buttonAddToggleType: UIView!
    var buttonAddToggleTypeImage: UIImageView!
    var buttonTrackUser: UIView!
    var buttonTrackUserImage: UIImageView!
    var buttonRefreshMap: UIView!
    var buttonRefreshMapImage: UIImageView!
    var buttonRefreshMapActivityIndicator: UIActivityIndicatorView!
    var backgroundActivityView: UIView!
    var backgroundActivityIndicator: UIActivityIndicatorView!
    
    var buttonZoomIn: UIView!
    var buttonZoomOut: UIView!
    var buttonZoomInTapGesture: UITapGestureRecognizer!
    var buttonZoomOutTapGesture: UITapGestureRecognizer!
    
    var lowAccuracyView: UIView!
    var lowAccuracyLabel: UILabel!
    var accuracyLabel: UILabel!
    
    var loginScreen: UIView!
    var loginBox: UIView!
    var loginButtonContainer: UIView!
    var fbLoginButton: FBSDKLoginButton!
    var loginActivityIndicator: UIActivityIndicatorView!
    var loginProcessLabel: UILabel!
    
    // The tap gestures for menu buttons
    var logoutButtonTapGesture: UITapGestureRecognizer!
    var locationButtonTapGesture: UITapGestureRecognizer!
    var menuPeopleTableTapGesture: UITapGestureRecognizer!
    var menuInterestsTableTapGesture: UITapGestureRecognizer!
    var menuFilterUserBlobsTapGesture: UITapGestureRecognizer!
    
    // The tap gestures for buttons and other interactive components
    var accountTapGesture: UITapGestureRecognizer!
    var buttonAddTapGesture: UITapGestureRecognizer!
    var buttonCancelAddTapGesture: UITapGestureRecognizer!
    var buttonAddToggleTypeTapGesture: UITapGestureRecognizer!
    var buttonTrackUserTapGesture: UITapGestureRecognizer!
    var buttonRefreshMapTapGesture: UITapGestureRecognizer!
    
    var lowAccuracyViewTapGesture: UITapGestureRecognizer!
    var guideSwipeGestureRight: UISwipeGestureRecognizer!
    var guideSwipeGestureLeft: UISwipeGestureRecognizer!
    
    var vcHeight: CGFloat!
    var vcOffsetY: CGFloat!
    
    // Set the selectionMessageBox dimensions
    let selectorBoxWidth: CGFloat = 120
    let selectorBoxHeight: CGFloat = 40
    let selectorTypeBoxWidth: CGFloat = 210
    let selectorTypeBoxHeight: CGFloat = 30
    
    // VC for adding content to a new Blob
    var addBlobVC: BlobAddViewController!
    
    // View controller variables for temporary user settings and view controls
    var previewStartingScrollPosition: CGFloat = 0
    
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
    var addBlobType = Constants.BlobType.location
    
    // This indicator is true of the user's location accuracy is too high
    // This allows the app to know that the user's location has already been indicated as too high without going back into accuracy range
    var locationInaccurate: Bool = false
    
    // Stores the markers that have been added to the map
    var blobMarkers = [GMSMarker]()
    
    // MUST USE a local array, in case the global array is updated in the background
    var mapBlobContent = [BlobContent]()
    var userBlobContent = [BlobContent]()
    
//    // The Blob shown in the preview box will be assigned for local access
//    var previewBlob: Blob?
//    
//    // The User (Creator) of the Blob shown in the preview box will be assigned for local access
//    var previewBlobUser: User?
    
//******* IS THIS NECESSARY?
    // Track which Blobs are being shown in the Preview Box to prevent overwriting the PreviewBlobs array when in use
    var previewSelection: String = ""
    
    // Create a local Circle to be used for the Preview view if the Blob does not already exist in the global Circle array
    var previewBlobCircle: GMSCircle!
    
    // Use only once - check when the user's location is first available, and move the map center to that location
    var userLocationInitialSet: Bool = false
    
//    // A default Blob User to use with the default Blob
//    var defaultBlobUser: User!
    
    // Store the local class variables so that information can be passed from background processes if needed
    var interestsVC: InterestsViewController?
    var peopleVC: PeopleViewController?
    var tabBarControllerCustom: UITabBarController?
    
    // If the user is manually logging in, set the indicator for certain settings
    var newLogin: Bool = false
    var showLoginScreenBool: Bool = false
    
    // Record when the menu is showing
    var menuOpen: Bool = false
    
    // Create a local property to hold the child VC
    var blobVC: BlobTableViewController!
    
    // Track the recent location changes in location and time changed
    var lastLocation: CLLocation?
    var lastLocationTime: Double = Date().timeIntervalSince1970
    
    // Properties for the tutorial
    let tutorialCircle = GMSCircle()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge.all
        
//        // Create a fake user for the default blob
//        defaultBlobUser = User()
//        defaultBlobUser.userID = "default"
//        defaultBlobUser.userName = "default"
//        defaultBlobUser.userImage = UIImage(named: Constants.Strings.iconStringBlobjotLogo)
//        defaultBlobUser.userStatus = Constants.UserStatusTypes.following
        
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
        
        vcHeight = screenSize.height - statusBarHeight - navBarHeight
        vcOffsetY = statusBarHeight + navBarHeight
        if statusBarHeight > 20 {
            vcOffsetY = 20 + navBarHeight
        }
        
        // Add the menu container to hold all menu items and hide it off to the right of the screen
        menuContainer = UIView(frame: CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight))
        menuContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(menuContainer)
        
        menuAccountContainer = UIView(frame: CGRect(x: menuContainer.frame.width - Constants.Dim.mapViewMenuWidth, y: 0, width: Constants.Dim.mapViewMenuWidth, height: 230))
        menuAccountContainer.backgroundColor = Constants.Colors.standardBackground
        menuContainer.addSubview(menuAccountContainer)
        
        // Local User Account Box
        displayUserLabel = UILabel(frame: CGRect(x: 0, y: 95, width: menuAccountContainer.frame.width, height: 20))
        displayUserLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        displayUserLabel.textColor = Constants.Colors.colorTextGray
        displayUserLabel.textAlignment = NSTextAlignment.center
        displayUserLabel.isUserInteractionEnabled = true
        menuAccountContainer.addSubview(displayUserLabel)
        
        // Add a loading indicator while downloading the logged in user name
        displayUserLabelActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 90, width: menuAccountContainer.frame.width, height: 30))
        displayUserLabelActivityIndicator.color = UIColor.black
        menuAccountContainer.addSubview(displayUserLabelActivityIndicator)
        displayUserLabelActivityIndicator.startAnimating()
        
        displayUserImageContainer = UIView(frame: CGRect(x: (menuAccountContainer.frame.width / 2) - 40, y: 5, width: 80, height: 80))
        displayUserImageContainer.layer.cornerRadius = displayUserImageContainer.frame.width / 2
        displayUserImageContainer.backgroundColor = UIColor.white
        displayUserImageContainer.layer.shadowOffset = CGSize(width: 0.5, height: 2)
        displayUserImageContainer.layer.shadowOpacity = 0.5
        displayUserImageContainer.layer.shadowRadius = 1.0
        menuAccountContainer.addSubview(displayUserImageContainer)
        
        // Add a loading indicator while downloading the logged in user image
        displayUserImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: displayUserImageContainer.frame.width, height: displayUserImageContainer.frame.height))
        displayUserImageActivityIndicator.color = UIColor.black
        displayUserImageContainer.addSubview(displayUserImageActivityIndicator)
        displayUserImageActivityIndicator.startAnimating()
        
        displayUserImage = UIImageView(frame: CGRect(x: 0, y: 0, width: displayUserImageContainer.frame.width, height: displayUserImageContainer.frame.height))
        displayUserImage.layer.cornerRadius = displayUserImageContainer.frame.width / 2
        displayUserImage.contentMode = UIViewContentMode.scaleAspectFill
        displayUserImage.clipsToBounds = true
        displayUserImageContainer.addSubview(displayUserImage)
        
        // Add a custom logout button
        logoutButton = UIView(frame: CGRect(x: (menuAccountContainer.frame.width / 2) - 65, y: menuAccountContainer.frame.height - 105, width: 130, height: 45))
        logoutButton.layer.cornerRadius = 5
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = Constants.Colors.colorPurple.cgColor
        logoutButton.backgroundColor = Constants.Colors.standardBackground
        menuAccountContainer.addSubview(logoutButton)
        
        logoutButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: logoutButton.frame.width, height: logoutButton.frame.height))
        logoutButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        logoutButtonLabel.textColor = Constants.Colors.colorPurple
        logoutButtonLabel.textAlignment = NSTextAlignment.center
        logoutButtonLabel.numberOfLines = 2
        logoutButtonLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        logoutButtonLabel.text = "Log Out"
        logoutButton.addSubview(logoutButtonLabel)
        
        // Add a custom location button
        locationButton = UIView(frame: CGRect(x: (menuAccountContainer.frame.width / 2) - 65, y: menuAccountContainer.frame.height - 55, width: 130, height: 45))
        locationButton.layer.cornerRadius = 5
        locationButton.layer.borderWidth = 1
        locationButton.layer.borderColor = Constants.Colors.colorPurple.cgColor
        locationButton.backgroundColor = Constants.Colors.standardBackground
        menuAccountContainer.addSubview(locationButton)
        
        locationButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: locationButton.frame.width, height: locationButton.frame.height))
        locationButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        locationButtonLabel.textColor = Constants.Colors.colorPurple
        locationButtonLabel.textAlignment = NSTextAlignment.center
        locationButtonLabel.numberOfLines = 2
        locationButtonLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        locationButton.addSubview(locationButtonLabel)
        
        // Retrieve the LocationManagerSettings in Core Data and assign that setting to the global locationManagerConstant property
        // If Core Data does not have that setting data, assign the default setting "constant" to Core Data
        // Also set the locationManager toggle button color and text based on the global setting
        let locationManagerSettingArray = CoreDataFunctions().locationManagerSettingRetrieve()
        if locationManagerSettingArray.count == 0
        {
            // If the array is empty, no previous setting was saved - set and save the default
            
            Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.significant
            locationButtonLabel.text = Constants.Strings.stringLMSignificant
            
            // Now save the default to Core Data
            CoreDataFunctions().locationManagerSettingSave(Constants.LocationManagerSettingType.significant)
        }
        else
        {
            print("MVC - CD Location Manager Setting: \(locationManagerSettingArray[0].locationManagerSetting)")
            if locationManagerSettingArray[0].locationManagerSetting == Constants.LocationManagerSettingType.always.rawValue
            {
                Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.always
                locationButtonLabel.text = Constants.Strings.stringLMAlways
            }
            else if locationManagerSettingArray[0].locationManagerSetting == Constants.LocationManagerSettingType.off.rawValue
            {
                Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.off
                locationButtonLabel.text = Constants.Strings.stringLMOff
            }
            else
            {
                Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.significant
                locationButtonLabel.text = Constants.Strings.stringLMSignificant
            }
        }
        
        let menuAccountContainerBorder = CALayer()
        menuAccountContainerBorder.frame = CGRect(x: 0, y: menuAccountContainer.frame.height - 1, width: menuAccountContainer.frame.width, height: 1)
        menuAccountContainerBorder.backgroundColor = Constants.Colors.colorPurple.cgColor
        menuAccountContainer.layer.addSublayer(menuAccountContainerBorder)
        
        menuInterestsTableButton = UIView(frame: CGRect(x: menuContainer.frame.width - Constants.Dim.mapViewMenuWidth, y: menuAccountContainer.frame.height, width: Constants.Dim.mapViewMenuWidth, height: 50))
        menuInterestsTableButton.backgroundColor = Constants.Colors.standardBackground
        menuContainer.addSubview(menuInterestsTableButton)
        
        menuInterestsTableButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: menuInterestsTableButton.frame.width, height: menuInterestsTableButton.frame.height))
        menuInterestsTableButtonLabel.text = "Your Interests \u{2192}"
        menuInterestsTableButtonLabel.textColor = Constants.Colors.colorPurple
        menuInterestsTableButtonLabel.textAlignment = .center
        menuInterestsTableButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        menuInterestsTableButton.addSubview(menuInterestsTableButtonLabel)
        
        let menuInterestsTableButtonBorder = CALayer()
        menuInterestsTableButtonBorder.frame = CGRect(x: 0, y: menuInterestsTableButton.frame.height - 1, width: menuInterestsTableButton.frame.width, height: 1)
        menuInterestsTableButtonBorder.backgroundColor = Constants.Colors.colorPurple.cgColor
        menuInterestsTableButton.layer.addSublayer(menuInterestsTableButtonBorder)
        
        menuPeopleTableButton = UIView(frame: CGRect(x: menuContainer.frame.width - Constants.Dim.mapViewMenuWidth, y: menuAccountContainer.frame.height + menuInterestsTableButton.frame.height, width: Constants.Dim.mapViewMenuWidth, height: 50))
        menuPeopleTableButton.backgroundColor = Constants.Colors.standardBackground
        menuContainer.addSubview(menuPeopleTableButton)
        
        menuPeopleTableButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: menuPeopleTableButton.frame.width, height: menuPeopleTableButton.frame.height))
        menuPeopleTableButtonLabel.text = "People \u{2192}"
        menuPeopleTableButtonLabel.textColor = Constants.Colors.colorPurple
        menuPeopleTableButtonLabel.textAlignment = .center
        menuPeopleTableButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        menuPeopleTableButton.addSubview(menuPeopleTableButtonLabel)
        
        let menuPeopleTableButtonBorder = CALayer()
        menuPeopleTableButtonBorder.frame = CGRect(x: 0, y: menuPeopleTableButton.frame.height - 1, width: menuPeopleTableButton.frame.width, height: 1)
        menuPeopleTableButtonBorder.backgroundColor = Constants.Colors.colorPurple.cgColor
        menuPeopleTableButton.layer.addSublayer(menuPeopleTableButtonBorder)
        
        
        
        menuFilterUserBlobsButton = UIView(frame: CGRect(x: menuContainer.frame.width - Constants.Dim.mapViewMenuWidth, y: menuContainer.frame.height - 50, width: Constants.Dim.mapViewMenuWidth, height: 50))
        menuFilterUserBlobsButton.backgroundColor = Constants.Colors.standardBackground
        menuContainer.addSubview(menuFilterUserBlobsButton)
        
        menuFilterUserBlobsButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: menuFilterUserBlobsButton.frame.width, height: menuFilterUserBlobsButton.frame.height))
        menuFilterUserBlobsButtonLabel.text = "Your Blobs"
        menuFilterUserBlobsButtonLabel.textColor = Constants.Colors.colorPurple
        menuFilterUserBlobsButtonLabel.textAlignment = .center
        menuFilterUserBlobsButtonLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 18)
        menuFilterUserBlobsButton.addSubview(menuFilterUserBlobsButtonLabel)
        
        let menuFilterUserBlobsButtonBorder = CALayer()
        menuFilterUserBlobsButtonBorder.frame = CGRect(x: 0, y: 0, width: menuFilterUserBlobsButton.frame.width, height: 1)
        menuFilterUserBlobsButtonBorder.backgroundColor = Constants.Colors.colorPurple.cgColor
        menuFilterUserBlobsButton.layer.addSublayer(menuFilterUserBlobsButtonBorder)
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        viewContainer.layer.shadowOpacity = 0.2
        viewContainer.layer.shadowRadius = 1.0
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
        viewContainer.addSubview(selectorMessageBox)
        selectorMessageBox.isHidden = true
        
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
        selectorCircle.backgroundColor = Constants.Colors.blobYellowMinorTransparent
        selectorCircle.isUserInteractionEnabled = false
        viewContainer.addSubview(selectorCircle)
        selectorCircle.isHidden = true
        
        let sliderHeight: CGFloat = 4
        let sliderCircleSize: Float = 20
        selectorSlider = UISlider(frame: CGRect(x: mapView.frame.width / 2, y: mapView.frame.height / 2 - (sliderHeight / 2), width: mapView.frame.width / 2, height: sliderHeight))
        selectorSlider.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        selectorSlider.minimumValue = sliderCircleSize / 2
        selectorSlider.maximumValue = Float(mapView.frame.width) / 2 - (sliderCircleSize / 2)
        selectorSlider.setValue(Float(circleInitialSize) / 2 - (sliderCircleSize / 2), animated: false)
        selectorSlider.tintColor = Constants.Colors.blobYellowDark
        selectorSlider.thumbTintColor = Constants.Colors.blobYellowDark
        selectorSlider.addTarget(self, action: #selector(MapViewController.sliderValueDidChange(_:)), for: .valueChanged)
        viewContainer.addSubview(selectorSlider)
        selectorSlider.isHidden = true
        
        // Add a message box for the selector type interaction
        selectorTypeMessageBox = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (selectorTypeBoxWidth / 2), y: viewContainer.frame.height + selectorTypeBoxHeight, width: selectorTypeBoxWidth, height: selectorTypeBoxHeight))
        selectorTypeMessageBox.layer.cornerRadius = 5
        selectorTypeMessageBox.backgroundColor = UIColor.white
        selectorTypeMessageBox.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        selectorTypeMessageBox.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        selectorTypeMessageBox.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(selectorTypeMessageBox)
        selectorTypeMessageBox.isHidden = true
        
        selectorTypeMessageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: selectorTypeMessageBox.frame.width, height: selectorTypeMessageBox.frame.height))
        selectorTypeMessageLabel.text = ""
        selectorTypeMessageLabel.textColor = Constants.Colors.colorTextGray
        selectorTypeMessageLabel.textAlignment = .center
        selectorTypeMessageLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        selectorTypeMessageBox.addSubview(selectorTypeMessageLabel)
        
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
        
        // Add the Add Button in the bottom right corner
        buttonAdd = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAddSize, y: viewContainer.frame.height - 5 - Constants.Dim.mapViewButtonAddSize, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonAdd.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonAdd.backgroundColor = Constants.Colors.colorMapViewButton
        buttonAdd.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonAdd.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonAdd.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(buttonAdd)
        
        buttonAddImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
        buttonAddImage.image = UIImage(named: Constants.Strings.iconStringBlobAdd)
        buttonAddImage.contentMode = UIViewContentMode.scaleAspectFit
        buttonAddImage.clipsToBounds = true
        buttonAdd.addSubview(buttonAddImage)
        
        // Add the Cancel Add and Toggle Type Buttons to show in the bottom right corner above the Add Button
        // Do not show the Cancel Add Button until the user selects Add Button
        buttonCancelAdd = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAddSize, y: viewContainer.frame.height - 10 - Constants.Dim.mapViewButtonAddSize * 2, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonCancelAdd.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonCancelAdd.backgroundColor = Constants.Colors.colorMapViewButton
        buttonCancelAdd.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonCancelAdd.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonCancelAdd.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(buttonCancelAdd)
        buttonCancelAdd.isHidden = true
        
        buttonCancelAddImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
        buttonCancelAddImage.image = UIImage(named: Constants.Strings.iconStringMapViewClose)
        buttonCancelAddImage.contentMode = UIViewContentMode.scaleAspectFit
        buttonCancelAddImage.clipsToBounds = true
        buttonCancelAdd.addSubview(buttonCancelAddImage)
        
        // Do not show the Toggle Type Button until the user selects Add Button
        buttonAddToggleType = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAddSize, y: viewContainer.frame.height - 15 - Constants.Dim.mapViewButtonAddSize * 3, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonAddToggleType.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonAddToggleType.backgroundColor = Constants.Colors.colorMapViewButton
        buttonAddToggleType.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonAddToggleType.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonAddToggleType.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(buttonAddToggleType)
        buttonAddToggleType.isHidden = true
        
        buttonAddToggleTypeImage = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.mapViewButtonSize - 10, height: Constants.Dim.mapViewButtonSize - 10))
//        buttonAddToggleTypeImage.image = UIImage(named: Constants.Strings.iconStringMapViewClose)
        buttonAddToggleTypeImage.contentMode = UIViewContentMode.scaleAspectFit
        buttonAddToggleTypeImage.clipsToBounds = true
        buttonAddToggleType.addSubview(buttonAddToggleTypeImage)
        
        // ZOOM BUTTONS
        buttonZoomIn = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAddSize, y: viewContainer.frame.height / 2 - 5 - Constants.Dim.mapViewButtonAddSize, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonZoomIn.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonZoomIn.backgroundColor = Constants.Colors.colorMapViewButton
        buttonZoomIn.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonZoomIn.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonZoomIn.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(buttonZoomIn)
        buttonZoomOut = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.mapViewButtonAddSize, y: viewContainer.frame.height / 2 + 5, width: Constants.Dim.mapViewButtonAddSize, height: Constants.Dim.mapViewButtonAddSize))
        buttonZoomOut.layer.cornerRadius = Constants.Dim.mapViewButtonAddSize / 2
        buttonZoomOut.backgroundColor = Constants.Colors.colorMapViewButton
        buttonZoomOut.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        buttonZoomOut.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        buttonZoomOut.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(buttonZoomOut)
        
        buttonZoomInTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapZoomIn(_:)))
        buttonZoomInTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonZoomIn.addGestureRecognizer(buttonZoomInTapGesture)
        buttonZoomOutTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapZoomOut(_:)))
        buttonZoomOutTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonZoomOut.addGestureRecognizer(buttonZoomOutTapGesture)
        
        
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
        locationBlobContentCollectionViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Dim.mapViewLocationBlobsCVCellSize + Constants.Dim.mapViewLocationBlobsCVHighlightAdjustSize, height: 0))
        locationBlobContentCollectionViewContainer.backgroundColor = UIColor.clear
        viewContainer.addSubview(locationBlobContentCollectionViewContainer)
        
        // Add the Collection View Controller and Subview to the Collection View Container
        locationBlobContentCVLayout = UICollectionViewFlowLayout()
        locationBlobContentCVLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        locationBlobContentCVLayout.headerReferenceSize = CGSize(width: locationBlobContentCollectionViewContainer.frame.width, height: 0)
        locationBlobContentCVLayout.footerReferenceSize = CGSize(width: locationBlobContentCollectionViewContainer.frame.width, height: 0)
        locationBlobContentCVLayout.minimumLineSpacing = 0
        locationBlobContentCVLayout.itemSize = CGSize(width: Constants.Dim.mapViewLocationBlobsCVCellSize, height: Constants.Dim.mapViewLocationBlobsCVCellSize)
        
        locationBlobContentCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: locationBlobContentCollectionViewContainer.frame.width, height: locationBlobContentCollectionViewContainer.frame.height), collectionViewLayout: locationBlobContentCVLayout)
        locationBlobContentCollectionView.dataSource = self
        locationBlobContentCollectionView.delegate = self
        locationBlobContentCollectionView.register(MapViewLocationBlobsCell.self, forCellWithReuseIdentifier: Constants.Strings.locationBlobsCellReuseIdentifier)
        locationBlobContentCollectionView.backgroundColor = UIColor.clear
        locationBlobContentCollectionView.alwaysBounceVertical = false
        locationBlobContentCollectionView.showsVerticalScrollIndicator = false
        locationBlobContentCollectionViewContainer.addSubview(locationBlobContentCollectionView)
        
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
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Keep the navigation bar visible.
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.modalPresentationStyle = UIModalPresentationStyle.popover
        
//        let leftButtonItem = UIBarButtonItem(image: UIImage(named: "TAB_ICON_active_blobs_gray.png"),
//                                             style: UIBarButtonItemStyle.plain,
//                                             target: self,
//                                             action: #selector(MapViewController.dummyMethod))
//        leftButtonItem.tintColor = Constants.Colors.colorTextNavBar
//        self.navigationItem.setLeftBarButton(leftButtonItem, animated: true)
        
        let rightButtonItem = UIBarButtonItem(image: UIImage(named: "TAB_ICON_account_gray.png"),
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.menuShow))
        rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
        self.navigationItem.setRightBarButton(rightButtonItem, animated: true)
        
        
        // The preview table should show just below the navigation bar and fill the width of the screen
        previewContainer = UIView(frame: CGRect(x: 0, y: 0 - Constants.Dim.mapViewPreviewContainerHeight, width: viewContainer.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight))
        previewContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.addSubview(previewContainer)
        
        previewActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: previewContainer.frame.width, height: previewContainer.frame.height))
        previewActivityIndicator.color = UIColor.black
        previewContainer.addSubview(previewActivityIndicator)
        previewActivityIndicator.startAnimating()
        
        // Add the Prevoew Collection View Controller and Subview to the Preview Container
        previewCVLayout = UICollectionViewFlowLayout()
        previewCVLayout.scrollDirection = .horizontal
        previewCVLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        previewCVLayout.headerReferenceSize = CGSize(width: 0, height: 0)
        previewCVLayout.footerReferenceSize = CGSize(width: 0, height: 0)
        previewCVLayout.minimumLineSpacing = 0
        previewCVLayout.itemSize = CGSize(width: previewContainer.frame.width, height: previewContainer.frame.height)
        
        previewCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: previewContainer.frame.width, height: previewContainer.frame.height), collectionViewLayout: previewCVLayout)
        previewCollectionView.dataSource = self
        previewCollectionView.delegate = self
        previewCollectionView.register(MapViewPreviewCell.self, forCellWithReuseIdentifier: Constants.Strings.previewBlobsCellReuseIdentifier)
        previewCollectionView.backgroundColor = UIColor.clear
        previewCollectionView.alwaysBounceHorizontal = false
        previewCollectionView.showsHorizontalScrollIndicator = false
        previewContainer.addSubview(previewCollectionView)
        
        // The Preview Count Circles show how many Blobs are to the right or left in the preview collection view
        previewCountCircleLeft = UIView(frame: CGRect(x: 0 - (previewContainer.frame.height / 2), y: 0, width: previewContainer.frame.height, height: previewContainer.frame.height))
        previewCountCircleLeft.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLightTransparent
        previewCountCircleLeft.layer.cornerRadius = previewContainer.frame.height / 2
        previewContainer.addSubview(previewCountCircleLeft)
        
        previewCountLabelLeft = UILabel(frame: CGRect(x: previewCountCircleLeft.frame.width / 2, y: 0, width: previewCountCircleLeft.frame.width / 2, height: previewCountCircleLeft.frame.height))
        previewCountLabelLeft.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewCountLabelLeft.textColor = Constants.Colors.colorTextGrayLight
        previewCountLabelLeft.textAlignment = .center
        previewCountLabelLeft.isUserInteractionEnabled = false
        previewCountCircleLeft.addSubview(previewCountLabelLeft)
        
        previewCountCircleRight = UIView(frame: CGRect(x: previewContainer.frame.width - (previewContainer.frame.height / 2), y: 0, width: previewContainer.frame.height, height: previewContainer.frame.height))
        previewCountCircleRight.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLightTransparent
        previewCountCircleRight.layer.cornerRadius = previewContainer.frame.height / 2
        previewContainer.addSubview(previewCountCircleRight)
        
        previewCountLabelRight = UILabel(frame: CGRect(x: 0, y: 0, width: previewCountCircleRight.frame.width / 2, height: previewCountCircleRight.frame.height))
        previewCountLabelRight.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        previewCountLabelRight.textColor = Constants.Colors.colorTextGrayLight
        previewCountLabelRight.textAlignment = .center
        previewCountLabelRight.isUserInteractionEnabled = false
        previewCountCircleRight.addSubview(previewCountLabelRight)
        
        
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
        
        logoutButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapLogoutButton(_:)))
        logoutButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        logoutButton.addGestureRecognizer(logoutButtonTapGesture)
        
        locationButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapLocationButton(_:)))
        locationButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        locationButton.addGestureRecognizer(locationButtonTapGesture)
        
        menuPeopleTableTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapMenuPeopleButton(_:)))
        menuPeopleTableTapGesture.numberOfTapsRequired = 1  // add single tap
        menuPeopleTableButton.addGestureRecognizer(menuPeopleTableTapGesture)
        
        menuInterestsTableTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapMenuInterestsButton(_:)))
        menuInterestsTableTapGesture.numberOfTapsRequired = 1  // add single tap
        menuInterestsTableButton.addGestureRecognizer(menuInterestsTableTapGesture)
        
        menuFilterUserBlobsTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapMenuFilterUserBlobs(_:)))
        menuFilterUserBlobsTapGesture.numberOfTapsRequired = 1  // add single tap
        menuFilterUserBlobsButton.addGestureRecognizer(menuFilterUserBlobsTapGesture)
        
        buttonTrackUserTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapToggleTrackUser(_:)))
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
        
        buttonAddToggleTypeTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapAddToggleTypeView(_:)))
        buttonAddToggleTypeTapGesture.numberOfTapsRequired = 1  // add single tap
        buttonAddToggleType.addGestureRecognizer(buttonAddToggleTypeTapGesture)
        
        lowAccuracyViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapLowAccuracyView(_:)))
        lowAccuracyViewTapGesture.numberOfTapsRequired = 1  // add single tap
        lowAccuracyView.addGestureRecognizer(lowAccuracyViewTapGesture)
        
        // Add the Key Path Observers for changes in the user's location and for when the map is moved (the map camera)
        mapView.addObserver(self, forKeyPath: "myLocation", options:NSKeyValueObservingOptions(), context: nil)
        mapView.addObserver(self, forKeyPath: "camera", options:NSKeyValueObservingOptions(), context: nil)
        
        // Setup the BlobContent list for the user's current location
        Constants.Data.locationBlobContent = [Constants.Data.defaultBlobContent]
        
//        // Recall the userLikes from Core Data and set them to the global variable
//        Constants.Data.currentUserInterests = CoreDataFunctions().likesRetrieve()
        
        // Refresh the Current User Elements
        self.refreshCurrentUserElements()
        print("MVC - CURRENT USER 1: \(Constants.Data.currentUser.userID)")
        // Go ahead and request the user data from AWS again in case the data has been updated
        if let currentUserID = Constants.Data.currentUser.userID
        {
            print("MVC - CALLING AWSGetSingleUserData FOR: \(currentUserID)")
            AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: currentUserID, forPreviewData: false), delegate: self as AWSRequestDelegate).prepRequest()
        }
        
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
        
        let coreDataFunctionsInstance = CoreDataFunctions()
        coreDataFunctionsInstance.blobsDeleteOld()
        coreDataFunctionsInstance.blobContentDeleteOld()
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
    
    func dummyMethod(){}
    
    // MARK: HOLE VIEW DELEGATE
    func holeViewRemoved(removingViewAtPosition: Int)
    {
        let blobColorOrigin = Constants().blobColor(Constants.BlobType.origin, blobFeature: Constants.BlobFeature.standard, blobAccess: Constants.BlobAccess.standard, blobAccount: Constants.BlobAccount.standard, mainMap: true)
        let blobColorLocationInvisible = Constants().blobColor(Constants.BlobType.location, blobFeature: Constants.BlobFeature.invisible, blobAccess: Constants.BlobAccess.standard, blobAccount: Constants.BlobAccount.standard, mainMap: true)
        
        switch removingViewAtPosition
        {
        case 1:
            // Create the example Blob and add it to the map
            let blobCenter = CLLocationCoordinate2DMake(Constants.Settings.mapViewDefaultLat, Constants.Settings.mapViewDefaultLong)
            tutorialCircle.position = blobCenter
            tutorialCircle.radius = 50
            tutorialCircle.title = "example"
            tutorialCircle.fillColor = blobColorOrigin
            tutorialCircle.strokeColor = blobColorOrigin
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
            tutorialCircle.fillColor = blobColorLocationInvisible
            tutorialCircle.strokeColor = blobColorLocationInvisible
            
            let holeView = HoleView(holeViewPosition: 3, frame: viewContainer.bounds, circleOffsetX: (viewContainer.bounds.width / 2), circleOffsetY: 275, circleRadius: 120, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 20, textWidth: 200, textFontSize: 18, text: "Blobs can be invisible...")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 3:
            // Change the color of the tutorial Blob
            tutorialCircle.fillColor = blobColorOrigin
            tutorialCircle.strokeColor = blobColorOrigin
            
            let holeView = HoleView(holeViewPosition: 4, frame: viewContainer.bounds, circleOffsetX: (viewContainer.bounds.width / 2), circleOffsetY: 275, circleRadius: 120, textOffsetX: (viewContainer.bounds.width / 2) - 100, textOffsetY: 20, textWidth: 200, textFontSize: 18, text: "...or visible on the map.\n\nBlobs can be permanent...")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        case 4:
            // Change the color of the tutorial Blob
            tutorialCircle.fillColor = blobColorOrigin
            tutorialCircle.strokeColor = blobColorOrigin
            
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
            Constants.Data.previewBlobContent = [Constants.Data.defaultBlobContent]
            self.previewShow()
            
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
    
    // Log out the user from the app and facebook
    func tapLogoutButton(_ sender: UITapGestureRecognizer)
    {
        print("TRYING TO LOG OUT THE USER")
        
        // Log out the user from Facebook
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        
        // Log out the user from the app
        Constants.Data.currentUser = User()
        Constants.credentialsProvider.clearCredentials()
        
        // Clear the data from the app
        Constants.Data.allBlobs = [Blob]()
        Constants.Data.mapBlobIDs = [String]()
        Constants.Data.blobContent = [BlobContent]()
        Constants.Data.userBlobContentIDs = [String]()
        Constants.Data.locationBlobContent = [BlobContent]()
        Constants.Data.previewBlobContent = [BlobContent]()
        Constants.Data.previewCurrentIndex = nil
        
        Constants.Data.thumbnailObjects = [ThumbnailObject]()
        Constants.Data.userObjects = [User]()
        
        // Remove the userBlobs from the local array
        self.userBlobContent = [BlobContent]()
        
        for circle in Constants.Data.mapCircles
        {
            circle.map = nil
        }
        Constants.Data.mapCircles = [GMSCircle]()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Toggle the location manager type
    func tapLocationButton(_ sender: UITapGestureRecognizer)
    {
        // Toggle the location manager type
        if Constants.Settings.locationManagerSetting == Constants.LocationManagerSettingType.always
        {
            // Change the locationManagerAlways toggle indicator
            Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.significant
            
            // Change the button color and text
            locationButtonLabel.text = Constants.Strings.stringLMSignificant
            
            // Save the locationManagerSetting in Core Data
            CoreDataFunctions().locationManagerSettingSave(Constants.LocationManagerSettingType.significant)
        }
        else if Constants.Settings.locationManagerSetting == Constants.LocationManagerSettingType.off
        {
            // Change the locationManagerAlways toggle indicator
            Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.always
            
            // Change the button color and text
            locationButtonLabel.text = Constants.Strings.stringLMAlways
            
            // Save the locationManagerSetting in Core Data
            CoreDataFunctions().locationManagerSettingSave(Constants.LocationManagerSettingType.always)
        }
        else
        {
            // Change the locationManagerAlways toggle indicator
            Constants.Settings.locationManagerSetting = Constants.LocationManagerSettingType.off
            
            // Change the button color and text
            locationButtonLabel.text = Constants.Strings.stringLMOff
            
            // Save the locationManagerSetting in Core Data
            CoreDataFunctions().locationManagerSettingSave(Constants.LocationManagerSettingType.off)
        }
        
        // Implement the changed settings immediately
        UtilityFunctions().toggleLocationManagerSettings()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // If the low accuracy alert view is showing, tapping it will display the popup explaining that the user's current location range is too high
    func tapLowAccuracyView(_ gesture: UITapGestureRecognizer)
    {
        // Show a notification that the user's location is too inaccurate to update data
        createAlertOkView("Bad Signal!", message: "Your location is too inaccurate to gather data.  Try moving to an area with better reception.")
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Filter the preview data with the logged in user's Blobs and show the preview box
    func tapMenuFilterUserBlobs(_ gesture: UITapGestureRecognizer)
    {
        // Set the selection indicator
        previewSelection = "UserBlobs"
        
        // Request the Blobs that the user has posted
        AWSPrepRequest(requestToCall: AWSGetUserBlobContent(), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Reset the userBlobs array and try to load the userBlobs from Core Data
        userBlobContent = [BlobContent]()
        let savedBlobContent = CoreDataFunctions().blobContentRetrieve()
        for sBlobContent in savedBlobContent
        {
            if sBlobContent.userID == Constants.Data.currentUser.userID
            {
                userBlobContent.append(sBlobContent)
            }
        }
        
        // Sort the User Blobs from newest to oldest
        userBlobContent.sort(by: {$0.contentDatetime.timeIntervalSince1970 > $1.contentDatetime.timeIntervalSince1970})
        
        // Reset the global preview Blobs list to ensure all associated variables are also reset
        UtilityFunctions().resetPreviewData()
        
        // Set the previewBlobs array to the userBlobs array since the preview CollectionView will use the global previewBlobs
        Constants.Data.previewBlobContent = self.userBlobContent
        print("MVC - PREVIEW BLOBS COUNT: \(Constants.Data.previewBlobContent.count)")
        
        // If the previewBlobs array is populated, indicate that the preview index is on the first Blob
        if Constants.Data.previewBlobContent.count > 0
        {
            Constants.Data.previewCurrentIndex = 0
        }
        
        // Close the menu
        self.menuHide()
        
        // Animate the preview box down into view
        self.previewShow()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    func tapMenuPeopleButton(_ gesture: UITapGestureRecognizer)
    {
        // Prepare both of the Table View Controllers and add Tab Bar Items to them
        peopleVC = PeopleViewController()
        peopleVC!.peopleViewDelegate = self
        
        // Create the Back Button Item and Title View for the Tab View
        // These settings will be passed up to the assigned Navigation Controller for the Tab View Controller
        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        peopleVC!.navigationItem.setLeftBarButton(backButtonItem, animated: true)
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        ncTitleText.text = "People"
        ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        peopleVC!.navigationItem.titleView = ncTitle
        
        if let navController = self.navigationController
        {
            navController.pushViewController(peopleVC!, animated: true)
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    func tapMenuInterestsButton(_ gesture: UITapGestureRecognizer)
    {
        // Prepare both of the Table View Controllers and add Tab Bar Items to them
        interestsVC = InterestsViewController()
        //interestsVC!.peopleViewDelegate = self
        
        // Create the Back Button Item and Title View for the Tab View
        // These settings will be passed up to the assigned Navigation Controller for the Tab View Controller
        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        interestsVC!.navigationItem.setLeftBarButton(backButtonItem, animated: true)
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        ncTitleText.text = "Interests"
        ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        interestsVC!.navigationItem.titleView = ncTitle
        
        if let navController = self.navigationController
        {
            navController.pushViewController(interestsVC!, animated: true)
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
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
            
            buttonCancelAdd.isHidden = false
            buttonAddToggleType.isHidden = false
            selectorCircle.isHidden = false
            selectorSlider.isHidden = false
            
            // Adjust the Map Camera so that the map cannot be viewed at an angle while adding a new Blob
            // The circle remains a circle when the map is angled, which is not a true representation of the Blob
            // that will be added, so the mapView is kept unangled while a Blob is being added
            adjustMapViewCamera()
            
            // If the user's location is within camera view, default to Origin Blob
            if let userLocation = mapView.myLocation
            {
                let mapViewableArea = GMSCoordinateBounds(coordinate: mapView.projection.visibleRegion().farRight, coordinate: mapView.projection.visibleRegion().nearLeft)
                if mapViewableArea.contains(userLocation.coordinate)
                {
                    // The user's location is within view, so change the Blob type to Origin
                    selectorCircle.backgroundColor = Constants.Colors.blobPurpleMinorTransparent
                    selectorSlider.tintColor = Constants.Colors.blobPurpleDark
                    selectorSlider.thumbTintColor = Constants.Colors.blobPurpleDark
                    addBlobType = Constants.BlobType.origin
                    
                    // Move to the user's location and set the zoom to the minimum add Blob zoom level
                    mapView.animate(toLocation: userLocation.coordinate)
                    mapView.animate(toZoom: Constants.Settings.mapViewAddBlobMinZoom)
                    
                    self.showSelectorTypeMessageBox(Constants.Strings.addBlobSelectorTypeBoxOrigin)
                }
                else
                {
                    // The user's location is NOT within view, so ensure the Blob type is Location
                    selectorCircle.backgroundColor = Constants.Colors.blobYellowMinorTransparent
                    selectorSlider.tintColor = Constants.Colors.blobYellowDark
                    selectorSlider.thumbTintColor = Constants.Colors.blobYellowDark
                    addBlobType = Constants.BlobType.location
                    
                    self.showSelectorTypeMessageBox(Constants.Strings.addBlobSelectorTypeBoxLocation)
                }
            }
            else
            {
                // The user's location is NOT within view, so ensure the Blob type is Location
                selectorCircle.backgroundColor = Constants.Colors.blobYellowMinorTransparent
                selectorSlider.tintColor = Constants.Colors.blobYellowDark
                selectorSlider.thumbTintColor = Constants.Colors.blobYellowDark
                addBlobType = Constants.BlobType.location
                
                self.showSelectorTypeMessageBox(Constants.Strings.addBlobSelectorTypeBoxLocation)
            }
        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // If the Cancel Add Blob button is tapped, show the buttons that were hidden and hide the elements used in the add blob process
    func tapCancelAddView(_ gesture: UITapGestureRecognizer)
    {
        self.hideSelectorMessageBox()
        self.hideSelectorTypeMessageBox()
        
        buttonAddImage.image = UIImage(named: Constants.Strings.iconStringBlobAdd)
        
        buttonCancelAdd.isHidden = true
        buttonAddToggleType.isHidden = true
        selectorCircle.isHidden = true
        selectorSlider.isHidden = true
        
        // Change the add blob indicator back to false efore calling adjustMapViewCamera
        addingBlob = false
        
        // Adjust the Map Camera back to allow the map can be viewed at an angle
        adjustMapViewCamera()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // If the Toggle Type button is tapped, change the Blob Type of the added Blob
    func tapAddToggleTypeView(_ gesture: UITapGestureRecognizer)
    {
        // Toggle the BlobType and change the toggle button image
        if addBlobType == Constants.BlobType.origin
        {
            selectorCircle.backgroundColor = Constants.Colors.blobYellowMinorTransparent
            selectorSlider.tintColor = Constants.Colors.blobYellowDark
            selectorSlider.thumbTintColor = Constants.Colors.blobYellowDark
            addBlobType = Constants.BlobType.location
            
            self.showSelectorTypeMessageBox(Constants.Strings.addBlobSelectorTypeBoxLocation)
        }
        else
        {
            // Move the mapView to the user's location
            if let userLocation = mapView.myLocation
            {
                // Change the Blob type to Origin
                selectorCircle.backgroundColor = Constants.Colors.blobPurpleMinorTransparent
                selectorSlider.tintColor = Constants.Colors.blobPurpleDark
                selectorSlider.thumbTintColor = Constants.Colors.blobPurpleDark
                addBlobType = Constants.BlobType.origin
                
                self.showSelectorTypeMessageBox(Constants.Strings.addBlobSelectorTypeBoxOrigin)
                
                // Move to the user's location and set the zoom to the minimum add Blob zoom level
                mapView.animate(toLocation: userLocation.coordinate)
                mapView.animate(toZoom: Constants.Settings.mapViewAddBlobMinZoom)
            }
        }
    }
    
// *COMPLETE****** Decide how the user should be tracked without making the interface annoying
    // If the Track User button is tapped, the track functionality is toggled
    func tapToggleTrackUser(_ gesture: UITapGestureRecognizer)
    {
        // Close the Preview Box - the user is not interacting with the Preview Box anymore
        closePreview()
        
        // Set all map Circles back to default (no highlighting)
        unhighlightMapCircleForAllBlobs()
        
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
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        self.navigationController!.popViewController(animated: true)
    }
    
    // Dismiss the latest View Controller presented from this VC
    func popViewController()
    {
        self.navigationController!.popViewController(animated: true)
    }
    
    // If the List View Button is tapped, prepare a Navigation Controller and a Tab View Controller
    // Attach the needed Table Views to the Tab View Controller and load the Navigation Controller
    func prepPushView()
    {
        // Ensure that the Preview Screen is hidden
        self.closePreview()
        
        // Set all map Circles back to default (no highlighting)
        unhighlightMapCircleForAllBlobs()
        
//        self.loadTabViewController(false)
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: "prepPushView")
    }
    
    func menuShow()
    {
        // Reset features on the MVC
        prepPushView()
        
        if !menuOpen
        {
            // Add animations to show the menuContainer and shift the viewContainer to the left
            UIView.animate(withDuration: 0.5, animations:
                {
                    self.viewContainer.frame = CGRect(x: 0 - Constants.Dim.mapViewMenuWidth, y: self.vcOffsetY, width: self.screenSize.width, height: self.vcHeight)
            }, completion:
                {
                    (value: Bool) in
                    self.menuOpen = true
            })
        }
        
//        // Prepare both of the Table View Controllers and add Tab Bar Items to them
//        peopleVC = PeopleViewController()
//        peopleVC!.peopleViewDelegate = self
//        peopleVC!.tabBarUsed = true
//        let peopleTabBarItem = UITabBarItem()
//        peopleTabBarItem.tag = 1
//        peopleTabBarItem.image = UIImage(named: Constants.Strings.iconStringTabIconConnectionsGray)
//        peopleTabBarItem.selectedImage = UIImage(named: Constants.Strings.iconStringTabIconConnectionsWhite)
//        peopleTabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
//        peopleVC!.tabBarItem = peopleTabBarItem
//
//        accountVC = AccountViewController()
//        accountVC!.accountViewDelegate = self
//        let accountTabBarItem = UITabBarItem()
//        accountTabBarItem.tag = 2
//        accountTabBarItem.image = UIImage(named: Constants.Strings.iconStringTabIconAccountGray)
//        accountTabBarItem.selectedImage = UIImage(named: Constants.Strings.iconStringTabIconAccountWhite)
//        accountTabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
//        accountVC!.tabBarItem = accountTabBarItem
//        
//        // Create the Tab Bar Controller to hold the Table View Controllers
//        tabBarControllerCustom = UITabBarController()
//        tabBarControllerCustom!.delegate = self
//        tabBarControllerCustom!.tabBar.barTintColor = Constants.Colors.colorStatusBarLight
//        tabBarControllerCustom!.tabBar.tintColor = Constants.Colors.colorTextNavBar
//        tabBarControllerCustom!.viewControllers = [peopleVC!, accountVC!]
//        
//        // If the account tab should be loaded, set the last (1) index to load
//        if goToAccountTab
//        {
//            tabBarControllerCustom!.selectedIndex = 1
//        }
//        
//        // Create the Back Button Item and Title View for the Tab View
//        // These settings will be passed up to the assigned Navigation Controller for the Tab View Controller
//        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
//                                             style: UIBarButtonItemStyle.plain,
//                                             target: self,
//                                             action: #selector(MapViewController.popViewController(_:)))
//        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
//        
//        // Assign the created Nav Bar settings to the Tab Bar Controller
//        tabBarControllerCustom!.navigationItem.setLeftBarButton(backButtonItem, animated: true)
//        
//        print("MVC - LSTVC - NAV CONTROLLER: \(self.navigationController)")
//        if let navController = self.navigationController
//        {
//            navController.pushViewController(tabBarControllerCustom!, animated: true)
//        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    func menuHide()
    {
        // Ensure the menu is already open, then hide it
        if menuOpen
        {
            UIView.animate(withDuration: 0.5, animations:
                {
                    self.viewContainer.frame = CGRect(x: 0, y: self.vcOffsetY, width: self.screenSize.width, height: self.vcHeight)
            }, completion:
                {
                    (value: Bool) in
                    self.menuOpen = false
            })
        }
    }
    
    
    // MARK: KEY-VALUE OBSERVER HANDLERS
    
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
        print("MVC - refreshBlobs - CURRENT LOCATION: \(userLocationCurrent)")
        
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
            Constants.Data.locationBlobContent = [Constants.Data.defaultBlobContent]
            
            // Loop through the array of all Blobs to find which Blobs are in range of the user's current location
            for blob in Constants.Data.allBlobs
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
                    // Ensure that the Blob is one that should be displayed on the map
                    loopBlobIDs: for mBlobID in Constants.Data.mapBlobIDs
                    {
                        if mBlobID == blob.blobID
                        {
                            // The BlobID was found, so proceed with finding the BlobContent
                            for blobContent in Constants.Data.blobContent
                            {
                                if blobContent.blobID == blob.blobID
                                {
                                    print("MVC - RB - REQUESTING BLOB CONTENT FOR BLOBCONTENT: \(blobContent.blobContentID)")
                                    // Ensure that the BlobContent data has not already been requested
                                    // If so, append the BlobContent to the Location BlobContent Array
                                    if !blobContent.contentExtraRequested
                                    {
                                        blobContent.contentExtraRequested = true
                                        
                                        AWSPrepRequest(requestToCall: AWSGetBlobContent(blobContentID: blobContent.blobContentID, minimalOnly: false), delegate: self as AWSRequestDelegate).prepRequest()
                                        
                                        // When downloading BlobContent data, always request the user data if it does not already exist
                                        // Find the correct User Object in the global list
                                        var userExists = false
                                        loopUserObjectCheck: for userObject in Constants.Data.userObjects
                                        {
                                            if userObject.userID == blobContent.userID
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
                                            AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: blobContent.userID, forPreviewData: true), delegate: self as AWSRequestDelegate).prepRequest()
                                        }
                                    }
                                    else
                                    {
                                        Constants.Data.locationBlobContent.append(blobContent)
                                    }
                                    
                                    // If the Blob is invisible, change the circle to gray
                                    if blob.blobFeature == Constants.BlobFeature.invisible
                                    {
                                        loopMapCirclesCheck: for circle in Constants.Data.mapCircles
                                        {
                                            if circle.title == blob.blobID
                                            {
                                                // Indicate that it is "not used on the main map" to get the gray color returned
                                                circle.fillColor = Constants().blobColor(blob.blobType, blobFeature: blob.blobFeature, blobAccess: blob.blobAccess, blobAccount: blob.blobAccount, mainMap: false)
                                                
                                                break loopMapCirclesCheck
                                            }
                                        }
                                    }
                                }
                            }
                            
                            break loopBlobIDs
                        }
                    }
                }
                else
                {
                    // Blob is not within user radius
                    
                    // ONLY FOR LOCATION RESTRICTED BLOBS: Since the Blob is not within the current radius, remove the extra data from all 
                    // BlobContent associated with the Blob, and change the Blob color, if it is an invisible Blob
                    
                    // If the Blob is not in range of the user's current location, but the BlobContent's extra data has already been requested,
                    // delete the extra data and indicate that the BlobContent's extra data has not been requested
                    if blob.blobType == Constants.BlobType.location
                    {
                        for blobContent in Constants.Data.blobContent
                        {
                            if blobContent.blobID == blob.blobID
                            {
                                if blobContent.contentExtraRequested
                                {
                                    // Remove all of the extra data
                                    blobContent.contentText = nil
                                    blobContent.contentThumbnailID = nil
                                    blobContent.contentType = nil
                                    blobContent.contentMediaID = nil
                                    
                                    // Indicate that the extra data has not been requested
// *ISSUE ********** If the data has been requested, but not added to the Blob yet, it could be added again after this step, causing bugs
                                    blobContent.contentExtraRequested = false
                                }
                                
                                // If the Blob is invisible, change the circle back to clear
                                if blob.blobFeature == Constants.BlobFeature.invisible
                                {
                                    loopMapCirclesCheck: for circle in Constants.Data.mapCircles
                                    {
                                        if circle.title == blob.blobID
                                        {
                                            circle.fillColor = Constants().blobColor(blob.blobType, blobFeature: blob.blobFeature, blobAccess: blob.blobAccess, blobAccount: blob.blobAccount, mainMap: true)
                                            
                                            break loopMapCirclesCheck
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
            
            // Add Markers on top of the Blobs
            processBlobMarkers()
            
            // Reload the Collection View
            self.refreshLocationBlobsCollectionView()
            
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
        /*
         1 - Check to see if the tap is within a Blob on the map
                - If so, highlight the Blob on the map
         2 - Check to see if the tapped Blob is one of the locationBlobs
                - If so, show the full Preview AND highlight the userImage in the collection view
                - If not, show the short Preview
        */
        
        // Ensure the menu is hidden
        self.menuHide()
        
        // Reset - remove the added preview circle, if existing
        if previewBlobCircle != nil
        {
            previewBlobCircle.map = nil
        }
        
        // Clear the preview Blob list to prepare a new list of Blobs
        UtilityFunctions().resetPreviewData()
        
        // Find all Blobs that overlap the tapped point
        for mBlob in Constants.Data.allBlobs
        {
//            print("MVC - TB - CHECKING BLOB: \(mBlob.blobID)")
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
            var withinTappedBlob = false
            if let myLocation = mapView.myLocation
            {
                if myLocation.distance(from: CLLocation(latitude: mBlob.blobLat, longitude: mBlob.blobLong)) < mBlob.blobRadius
                {
                    withinTappedBlob = true
                }
            }
            
            if tapFromBlobCenterDistance <= mBlob.blobRadius && (mBlob.blobFeature != Constants.BlobFeature.invisible || withinTappedBlob)
            {
                print("MVC - TB - TAPPED BLOB: \(mBlob.blobID)")
                // Find all BlobContent for the tapped Blob
                for blobContent in Constants.Data.blobContent
                {
                    if blobContent.blobID == mBlob.blobID
                    {
                        // Add the BlobContent to the list of preview BlobContent
                        Constants.Data.previewBlobContent.append(blobContent)
                        
                        print("MVC - TB - APPENDED TO PREVIEW CONTENT: \(blobContent.blobID), \(blobContent.blobType), \(blobContent.contentType), \(blobContent.contentText)")
                    }
                }
                
//                // Reset the Preview Box
//                self.clearPreview()
                
                // Highlight the edge of the Blob
                loopMapCircles: for circle in Constants.Data.mapCircles
                {
                    if circle.title == mBlob.blobID
                    {
                        print("MVC - TB - HIGHLIGHTING CIRCLE FOR BLOB: \(mBlob.blobID)")
                        circle.strokeColor = Constants.Colors.blobHighlight
                        circle.strokeWidth = 3
                        
                        break loopMapCircles
                    }
                }
                
//                // Show the Preview Box with the selected Blob data
//                previewBlob(mBlob)
                
                // Loop through the Location BlobContent array to mark the top Blobs within tap range
                loopLocationBlobContentCheck: for lBlobContent in Constants.Data.locationBlobContent
                {
                    // Mark all BlobContent as not selected so that any map tap can deselect a currently selected Blob & BlobContent
                    lBlobContent.blobSelected = false
                    
                    // Check to see if the BlobContent is connected to the tapped Blob and
                    // if so, indicate that the Blob was tapped (this variable can be used to highlight the BlobContent within the Collection View)
                    if lBlobContent.blobID == mBlob.blobID
                    {
                        lBlobContent.blobSelected = true
                        
                        break loopLocationBlobContentCheck
                    }
                }
                
                // DO NOT STOP looping through Blobs after the first matched Blob - other Blobs may need to be unhighlighted
            }
        }
        
//        // If a Blob was not tapped on the map, close the Preview Box
//        if !tappedBlob
//        {
//            // Close the Preview Box - the user is not interacting with the Preview Box anymore
//            self.closePreview()
//        }
        
        // Show the preview box if the previewList contains data, otherwise close the Preview box
        if Constants.Data.previewBlobContent.count > 0
        {
            // Indicate that the preview index is on the first Blob
            Constants.Data.previewCurrentIndex = 0
            
            self.previewShow()
        }
        else
        {
            self.closePreview()
        }
        
//        // Refresh the Preview Collection View
//        self.refreshPreviewCollectionView()
        
        // Reload the Collection View to ensure that any deselections also correct the User Image placement in the collection view
        self.refreshLocationBlobsCollectionView()
    }
    
    // Called before the map is moved
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool)
    {
        // If the user is adding a Blob, do not allow them to zoom lower than mapViewAddBlobMinZoom (higher view)
        if addingBlob
        {
            if mapView.camera.zoom < Constants.Settings.mapViewAddBlobMinZoom
            {
                print("MVC - MAPVIEW WILL MOVE - ANIMATE TO ZOOM")
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
            
            // Ensure the user's location is not nil
            if let userLocation = mapView.myLocation
            {
                // If the current Add Blob type is Origin, don't let the map move away from the user's location
                if addBlobType == Constants.BlobType.origin
                {
                    mapView.animate(toLocation: userLocation.coordinate)
                }
            }
        }
    }
    
    // Called while the map is moved
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition)
    {
        print("MVC - MAPVIEW CHANGING POSITION")
        
//        // Adjust the Map Camera back to apply the correct camera angle
//        adjustMapViewCamera()
//        
//        // Check the markers again since the zoom may have changed
//        processBlobMarkers()
    }
    // Called after the map is moved
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition)
    {
        print("MVC - MAPVIEW CHANGED POSITION - ZOOM: \(mapView.camera.zoom)")
        
        // Adjust the Map Camera back to apply the correct camera angle
        adjustMapViewCamera()
        
        // Check the markers again since the zoom may have changed
        processBlobMarkers()
    }
    
    // Add markers for Blobs on the map if the zoom is high enough
    func processBlobMarkers()
    {
        // Ensure that the zoom is close enough
        if mapView.camera.zoom >= Constants.Settings.mapViewAngledZoom
        {
            // Nullify all current markers
            for marker in self.blobMarkers
            {
                marker.map = nil
            }
            self.blobMarkers = [GMSMarker]()
        }
        else if blobMarkers.count < 1
        {
            // Nullify all current markers
            for marker in self.blobMarkers
            {
                marker.map = nil
            }
            self.blobMarkers = [GMSMarker]()
            
            for mBlobID in Constants.Data.mapBlobIDs
            {
                blobLoop: for blob in Constants.Data.allBlobs
                {
                    if blob.blobID == mBlobID
                    {
                        addMarker(blob)
                        break blobLoop
                    }
                }
            }
        }
    }
    
    func addMarker(_ blob: Blob)
    {
        let dotDiameter: CGFloat = 6
        let dot = UIImage(color: Constants().blobColorOpaque(blob.blobType, blobFeature: blob.blobFeature, blobAccess: blob.blobAccess, blobAccount: blob.blobAccount, mainMap: true), size: CGSize(width: dotDiameter, height: dotDiameter))
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
    
    func tapZoomOut(_ gesture: UITapGestureRecognizer)
    {
        mapView.animate(toZoom: mapView.camera.zoom - 1.0)
    }
    func tapZoomIn(_ gesture: UITapGestureRecognizer)
    {
        mapView.animate(toZoom: mapView.camera.zoom + 1.0)
    }
    
    // Show the selectorMessageBox
    func showSelectorMessageBox()
    {
        self.selectorMessageBox.isHidden = false
        
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
            }, completion:
            {
                (value: Bool) in
                self.selectorMessageBox.isHidden = true
        })
    }
    
    // Show the selectorTypeMessageBox
    func showSelectorTypeMessageBox(_ withMessage: String)
    {
        self.selectorTypeMessageLabel.text = withMessage
        self.selectorTypeMessageBox.isHidden = false
        
        // Add an animation to show and then hide the selectorTypeMessageBox
        UIView.animate(withDuration: 0.5, animations:
            {
                self.selectorTypeMessageBox.frame = CGRect(x: (self.viewContainer.frame.width / 2) - (self.selectorTypeBoxWidth / 2), y: self.viewContainer.frame.height - 60 - self.selectorTypeBoxHeight, width: self.selectorTypeBoxWidth, height: self.selectorTypeBoxHeight)
        }, completion: nil)
    }
    // Hide the selectorTypeMessageBox
    func hideSelectorTypeMessageBox()
    {
        // Add an animation to show and then hide the selectorTypeMessageBox
        UIView.animate(withDuration: 0.5, animations:
            {
                self.selectorTypeMessageBox.frame = CGRect(x: (self.viewContainer.frame.width / 2) - (self.selectorTypeBoxWidth / 2), y: self.viewContainer.frame.height + self.selectorTypeBoxHeight, width: self.selectorTypeBoxWidth, height: self.selectorTypeBoxHeight)
        }, completion:
            {
                (value: Bool) in
                self.selectorTypeMessageBox.isHidden = true
        })
    }
    
    // Adjust the Map Camera settings to allow or disallow angling the camera view
    // If not in the add blob process, angle the map automatically if the zoom is high enough
    func adjustMapViewCamera()
    {
        print("MVC - ADJUSTING MAP CAMERA")
        
        if !addingBlob
        {
            print("MVC - MAP CAMERA CURRENT VEWING ANGLE: \(mapView.camera.viewingAngle)")
            print("MVC - MAP CAMERA DESIRED VEWING ANGLE: \(Constants.Settings.mapViewAngledDegrees)")
            // When not in the add blob process, if the map zoom is 16 or higher, automatically angle the camera
            // NOTE: Still firing, even if the view angles are the same - made adjustment by -1 to compensate
            if mapView.camera.zoom >= Constants.Settings.mapViewAngledZoom && mapView.camera.viewingAngle < Constants.Settings.mapViewAngledDegrees - 1
            {
                print("MVC - ADJUSTING MAP CAMERA - CHECK 2a")
                mapView.animate(toViewingAngle: Constants.Settings.mapViewAngledDegrees)
            }
            else if mapView.camera.zoom < Constants.Settings.mapViewAngledZoom && mapView.camera.viewingAngle > 0
            {
                print("MVC - ADJUSTING MAP CAMERA - CHECK 2b")
                // Keep the map from being angled if the zoom is too low
                mapView.animate(toViewingAngle: Double(0))
            }
        }
        else
        {
            // When in the add blob process, do not allow the map camera to angle
            mapView.animate(toViewingAngle: Double(0))
            
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
        print("MVC - ADJUSTED MAP CAMERA")
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
        if collectionView == locationBlobContentCollectionView
        {
            // Resize the Location Blobs Collection View so that it only is tall enough to show all the Blobs
            // Otherwise, the Map View would be blocked by the Collection View and not allow touch responses
            
            // Calculate the height of all the cells together (multiplied by the number of Blobs)
            let maxCVHeight = Constants.Dim.mapViewLocationBlobsCVCellSize * CGFloat(Constants.Data.locationBlobContent.count)
            // Determine the height of the viewContainer
            var cvHeight = viewContainer.frame.height
            // If the max height of all Blob cells together is less than the View Container height, then use the smaller height (the total cell(s) height)
            if maxCVHeight < cvHeight
            {
                cvHeight = maxCVHeight
            }
            locationBlobContentCollectionViewContainer.frame.size.height = cvHeight
            locationBlobContentCollectionView.frame.size.height = cvHeight
            
            return Constants.Data.locationBlobContent.count
        }
        else if collectionView == previewCollectionView
        {
            // Any selected preview list will be assigned to the previewBlobs array for use
            return Constants.Data.previewBlobContent.count
        }
        else
        {
            return Constants.Data.previewBlobContent.count
        }
    }
    
    // Create cells for CollectionView
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if collectionView == locationBlobContentCollectionView
        {
            // Create reference to CollectionView cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Strings.locationBlobsCellReuseIdentifier, for: indexPath) as! MapViewLocationBlobsCell
            
            // Reset the needed views and start the indicator animation
            cell.userImage.image = nil
            cell.userImageActivityIndicator.startAnimating()
            
            // When the Blob is indicated as selected (blobSelected), the User Image is moved 10dp to the right (see below)
            // Reset the User Image location for all Blobs in case the Blob is no longer selected
            cell.userImageContainer.frame = CGRect(x: 5, y: 5, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize)
            
            
            // If the cell is the first one, it is the default blob, so show the Blobjot logo
            if (indexPath as NSIndexPath).row > 0
            {
                // Add the associated User Image to the User Image View
                if let userID = Constants.Data.locationBlobContent[(indexPath as NSIndexPath).row].userID
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
                cell.userImage.image = UIImage(named: Constants.Strings.iconStringBlobjotLogo)
                cell.userImageActivityIndicator.stopAnimating()
            }
            
            // Check to see if the Blob for this BlobContent has been selected, and if so move the User Image to the right
            if Constants.Data.locationBlobContent[(indexPath as NSIndexPath).row].blobSelected
            {
                cell.userImageContainer.frame = CGRect(x: 5 + Constants.Dim.mapViewLocationBlobsCVHighlightAdjustSize, y: 5, width: Constants.Dim.mapViewLocationBlobsCVItemSize, height: Constants.Dim.mapViewLocationBlobsCVItemSize)
            }
            return cell
        }
        else if collectionView == previewCollectionView
        {
            // Create reference to CollectionView cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Strings.previewBlobsCellReuseIdentifier, for: indexPath) as! MapViewPreviewCell
            
            print("MVC - CV - CREATING PREVIEW CELL AT INDEX: \(indexPath.row)")
            
            // Reference the BlobContent in the selected BlobContent array
            let blobContent = Constants.Data.previewBlobContent[(indexPath as NSIndexPath).row]
            
            // Check if the user has already been downloaded
            // If a Blob outside the range of the user was clicked, the user may not have already been downloaded
            var userExists = false
            loopUserCheck: for user in Constants.Data.userObjects
            {
                if user.userID == blobContent.userID
                {
                    userExists = true
                    
//                    // Assign the user to the previewBlobUser
//                    self.previewBlobUser = user
                    
                    // Assign the user's image and username to the preview
                    if user.userName != nil
                    {
                        cell.previewUserNameLabel.text = user.userName
                        cell.previewUserNameActivityIndicator.stopAnimating()
                        
                        if user.userImage != nil
                        {
                            cell.previewUserImageView.image = user.userImage
                            cell.previewUserImageActivityIndicator.stopAnimating()
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
                AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: blobContent.userID, forPreviewData: true), delegate: self as AWSRequestDelegate).prepRequest()
            }
            
            // Set the Preview Time Label to show the age of the Blob
            if let datetime = blobContent.contentDatetime
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
                cell.previewTimeLabel.text = stringAge
            }
            
            // Check whether the BlobContent text has been added to the BlobContent, and if so, display the text
            // If not, check whether the extra data has already been requested
            // if not, this means the Blob for the BlobContent is not (or has not been) in range
            // If it has been requested, but no text exists, do nothing (leave the text area blank)
            if let bText = blobContent.contentText
            {
                cell.previewTextBox.textColor = Constants.Colors.colorPreviewTextNormal
                cell.previewTextBox.text = bText
            }
            else if !blobContent.contentExtraRequested
            {
                cell.previewTextBox.textColor = Constants.Colors.colorPreviewTextError
                cell.previewTextBox.text = Constants.Strings.mapViewLabelOutOfRange
            }
            
            print("MVC - BLOB CONTENT PREVIEW EXTRA REQUESTED: \(blobContent.contentExtraRequested)")
            // If BlobContent extra data has been requested, the Blob is in range, so download the Thumbnail,
            // otherwise, move the BlobContent age and text all the way to the right side of the Preview Box
            if blobContent.contentExtraRequested
            {
                print("MVC - BLOB CONTENT PREVIEW MEDIA TYPE: \(blobContent.contentType)")
                if let contentType = blobContent.contentType
                {
                    print("MVC - BLOB CONTENT PREVIEW THUMBNAIL - CHECK 1")
                    // Check whether the BlobContent has media - if not, do not show the Thumbnail box
                    if contentType == Constants.ContentType.image
                    {
                        print("MVC - BLOB CONTENT PREVIEW THUMBNAIL - CHECK 2: \(blobContent.blobContentID)")
                        print("MVC - BLOB CONTENT PREVIEW THUMBNAIL - CHECK 2: \(blobContent.contentDatetime)")
                        print("MVC - BLOB CONTENT PREVIEW THUMBNAIL - CHECK 2: \(blobContent.contentText)")
                        print("MVC - BLOB CONTENT PREVIEW THUMBNAIL - CHECK 2: \(blobContent.blobSelected)")
                        print("MVC - BLOB CONTENT PREVIEW THUMBNAIL - CHECK 2: \(blobContent.contentThumbnailID)")
                        // Check to see if the thumbnail was already downloaded
                        // If not, the return function from AWS will apply the thumbnail to the preview box
                        // Loop through the BlobThumbnailObjects array
                        var thumbnailExists = false
                        loopThumbnail: for tObject in Constants.Data.thumbnailObjects
                        {
                            // Check each thumbnail object to see if matches
                            if tObject.thumbnailID == blobContent.contentThumbnailID
                            {
                                // Check to make sure the thumbnail has already been downloaded
                                if let thumbnailImage = tObject.thumbnail
                                {
                                    // Set the Preview Thumbnail image
                                    cell.previewThumbnailView.image = thumbnailImage
                                    
                                    // Stop animating the activity indicator
                                    cell.previewThumbnailActivityIndicator.stopAnimating()
                                    
//                                    // Assign the thumbnail image to the previewBlob
//                                    self.previewBlob?.blobThumbnail = thumbnailImage
                                    
                                    // Add the thumbnail subview to the cell
                                    cell.previewContainer.addSubview(cell.previewThumbnailView)
                                    
                                    // Move the time label to the left of the thumbnail, since it exists
                                    cell.previewTimeLabel.frame = CGRect(x: cell.previewContainer.frame.width - 10 - cell.previewContainer.frame.height / 2 - cell.previewTimeLabelWidth - cell.previewThumbnailView.frame.width, y: 5, width: cell.previewTimeLabelWidth, height: 15)
                                    
                                    // Adjust the other preview features to not overlap with the moved time label
                                    cell.previewUserNameLabel.frame = CGRect(x: cell.postUserImageOffset, y: 5, width: cell.previewContainer.frame.width - 15 - cell.postUserImageOffset - cell.previewTimeLabelWidth - cell.previewThumbnailView.frame.width, height: 15)
                                    cell.previewTextBox.frame = CGRect(x: cell.postUserImageOffset, y: 10 + cell.previewUserNameLabel.frame.height, width: cell.previewContainer.frame.width - 15 - cell.postUserImageOffset - cell.previewTimeLabelWidth - cell.previewThumbnailView.frame.width, height: CGFloat(15))
                                    
                                    thumbnailExists = true
                                    
                                    break loopThumbnail
                                }
                            }
                        }
                        if !thumbnailExists
                        {
                            print("MVC - BLOB CONTENT PREVIEW THUMBNAIL - CHECK 6")
                            // Request the thumbnail image if the thumbnailID exists
                            if let thumbnailID = blobContent.contentThumbnailID
                            {
                                print("MVC - BLOB CONTENT PREVIEW THUMBNAIL - CHECK 7")
                                AWSPrepRequest(requestToCall: AWSGetThumbnailImage(contentThumbnailID: thumbnailID), delegate: self as AWSRequestDelegate).prepRequest()
                            }
                        }
                    }
                }
            }
            return cell
        }
        else
        {
            print("MVC - CV - USING WRONG CELL TYPE")
            // Create reference to CollectionView cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Strings.previewBlobsCellReuseIdentifier, for: indexPath) as! MapViewPreviewCell
            return cell
        }
    }
    
    
    // MARK: UI COLLECTION VIEW DELEGATE PROTOCOL
    
    // Cell Selection Blob
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
//        // Clear the Preview Box for new Blob data
//        self.clearPreview()
        
        if collectionView == locationBlobContentCollectionView
        {
            // If the cell is the first one, it is the default blob, so show the Blobjot Blob message
            if (indexPath as NSIndexPath).row == 0
            {
                self.createAlertOkView("Blobjot", message: Constants.Strings.mapViewMessageDefaultBlob)
            }
            else
            {
                // Loop through the Map Blob IDs, find the associated Blob, reset the Map Circles' borders, find the matching Location Blob and highlight its border
                // Do NOT break the Map Blobs loop early.  All Map Blobs should be checked and corresponding Map Circle's border reset
                loopMapBlobs: for mBlobID in Constants.Data.mapBlobIDs
                {
                    // Find the actual Blob object
                    for mBlob in Constants.Data.allBlobs
                    {
                        if mBlob.blobID == mBlobID
                        {
                            mBlob.blobSelected = false
                            
                            // Reset the border for the Map Circle that matches the Map Blob
                            unhighlightMapCircleForBlob(mBlob)
                            
                            if let associatedBlobID = Constants.Data.locationBlobContent[(indexPath as NSIndexPath).row].blobID
                            {
                                // Call the function to prepare and show the Preview Box using the data from the Location BlobContent at the selected index
                                previewBlobContentForBlobID(associatedBlobID)
                                
                                // Check whether the current Map Blob matches the Location BlobContent BlobID at the selected index
                                // If so, find the Map Circle that matches the current Map Blob and highlight that Map Circle's border
                                if mBlob.blobID == associatedBlobID
                                {
                                    mBlob.blobSelected = true
                                    
                                    // Reload the Collection View
                                    self.refreshLocationBlobsCollectionView()
                                    
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
                            break loopMapBlobs
                        }
                    }
                }
            }
        }
        else
        {
            // ELSE should be the previewBlobCollectionView
            
            // Ensure that the preview BlobContent array is not empty
            // Then show the detailed BlobContent list view
            if Constants.Data.previewBlobContent.count > 0
            {
                // Close the Preview Box - the user is not interacting with the Preview Box anymore
                closePreview()
                
                unhighlightMapCircleForAllBlobs()
                
                // Create a back button and title for the Nav Bar
                let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                                     style: UIBarButtonItemStyle.plain,
                                                     target: self,
                                                     action: #selector(MapViewController.popViewController(_:)))
                backButtonItem.tintColor = Constants.Colors.colorTextNavBar
                
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 75, y: 10, width: 150, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
                ncTitleText.text = "Selected Blobs"
                
                ncTitleText.textColor = Constants.Colors.colorTextNavBar
                ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
                ncTitleText.textAlignment = .center
                ncTitle.addSubview(ncTitleText)
                
                // Instantiate the BlobViewController and pass the Preview Blob to the VC
                blobVC = BlobTableViewController()
                blobVC.blobContentArray = Constants.Data.previewBlobContent
                
                // Assign the created Nav Bar settings to the Tab Bar Controller
                blobVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
                blobVC.navigationItem.titleView = ncTitle
                
                print("MVC - NAV CONTROLLER: \(self.navigationController)")
                if let navController = self.navigationController
                {
                    navController.pushViewController(blobVC, animated: true)
                }
                
                // Reload the collectionView so that the previously selected Blob is no longer sticking out
                self.refreshLocationBlobsCollectionView()
            }
        }
        
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
    
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        print("MVC - SCROLL VIEW: \(scrollView) WILL DECELERATE: \(decelerate)")
        // Snap the cells to each cell to only show one at a time
        // Only fire if the scrollView is not decelerating, otherwise it will fire immediately from scrollViewWillBeginDecelerating
        if !decelerate
        {
            snapToNearestPreviewCell()
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    {
        print("MVC - SCROLL VIEW: \(scrollView) WILL BEGIN DECELERATING")
        // Snap the cells to each cell to only show one at a time
//        scrollView.setContentOffset(scrollView.contentOffset, animated: true)
        snapToNearestPreviewCell()
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
//                    self.clearPreview()
            })
        }
    }
    
    // Reset all Preview Box settings and values
    func clearPreview()
    {
        Constants.Data.previewBlobContent = [BlobContent]()
        
        refreshPreviewCollectionView()
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
            addBlobVC!.blobCoords = mapView.camera.target
            addBlobVC!.blobType = self.addBlobType
//            addBlobVC!.mapZoom = mapView.camera.zoom
            
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
            let blobRadius = mapCenterLocation.distance(from: sliderLocation)
            addBlobVC!.blobRadius = blobRadius
            addBlobVC.mapZoom = UtilityFunctions().mapZoomForBlobSize(Float(blobRadius))
            addBlobVC!.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            addBlobVC!.navigationItem.titleView = ncTitle
        }
        
        if let navController = self.navigationController
        {
            navController.pushViewController(addBlobVC!, animated: true)
        }
        
        // Reset the button settings and remove the elements used in the Add Blob Process
        buttonAddImage.image = UIImage(named: Constants.Strings.iconStringBlobAdd)
        
        hideSelectorMessageBox()
        hideSelectorTypeMessageBox()
        
        buttonCancelAdd.isHidden = true
        buttonAddToggleType.isHidden = true
        selectorCircle.isHidden = true
        selectorSlider.isHidden = true
        
        // Change the add blob indicator back to false efore calling adjustMapViewCamera
        addingBlob = false
        
        // Adjust the Map Camera back to allow the map can be viewed at an angle
        adjustMapViewCamera()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // The function to lower the previewBox
    func previewShow()
    {
        print("MVC - PV - SHOW PREVIEW")
        refreshPreviewCollectionView()
        
        // Add an animation to lower the preview container into view
        UIView.animate(withDuration: 0.2, animations:
            {
                self.previewContainer.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.width, height: Constants.Dim.mapViewPreviewContainerHeight)
        }, completion: nil)
    }
    
    // Add BlobContent data to the Preview Box elements and animate the Preview Box lowering into view
    func previewBlobContentForBlobID(_ blobID: String)
    {
        // Clear the previewBlobContent array
        Constants.Data.previewBlobContent = [BlobContent]()
        
        // Assign the global previewBlobContent to all BlobContent that matches the passed BlobID
        for blobContent in Constants.Data.blobContent
        {
            if blobContent.blobID == blobID
            {
                Constants.Data.previewBlobContent.append(blobContent)
            }
        }
        
        self.previewShow()
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    // Loop through the Map Blobs, check if they have already been added as Map Circles, and create a Map Circle if needed
    func addMapBlobsToMap()
    {
        // The mapBlobIDs list has been updated AND WILL BE SORTED CORRECTLY IMMEDIATELY AFTER DOWNLOADING
        // and all Blobs are in the allBlobs array
        // Loop through Map Blobs and check for corresponding Map Circles
        for mBlobID in Constants.Data.mapBlobIDs
        {
            blobLoop: for blob in Constants.Data.allBlobs
            {
                if blob.blobID == mBlobID
                {
                    var blobExists = false
                    loopCircleCheck: for circle in Constants.Data.mapCircles
                    {
                        if circle.title == blob.blobID
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
                        self.createBlobOnMap(blob)
                    }
                    
                    break blobLoop
                }
            }
        }
        
        // Now add the markers to the Blobs
        self.processBlobMarkers()

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
        addCircle.fillColor = Constants().blobColor(blob.blobType, blobFeature: blob.blobFeature, blobAccess: blob.blobAccess, blobAccount: blob.blobAccount, mainMap: true)
        addCircle.strokeColor = Constants().blobColor(blob.blobType, blobFeature: blob.blobFeature, blobAccess: blob.blobAccess, blobAccount: blob.blobAccount, mainMap: true)
        addCircle.strokeWidth = 1
        addCircle.map = self.mapView
        Constants.Data.mapCircles.append(addCircle)
        print("MVC-AMBM - ADDED CIRCLE")
//        let path = UtilityFunctions().pathForCoordinate(blobCenter, withMeterRadius: blobRadius)
//        let blob = GMSPolyline(path: path)
//        blob.map = self.mapView
    }
    
    // The AWS Delegate return methods will call this function when the logged in user has been added to the global user list
    func refreshCurrentUserElements()
    {
        print("MVC-RCUE - REFRESH CURRENT USER DATA")
        
        // The Current User Data has already been loaded into the global current User object, and possibly updated
        // from a fresh download of user data when this viewController was loaded
        
        // Show the logged in user's username in the display user label
        if let username = Constants.Data.currentUser.userName
        {
            Constants.Data.currentUser.userName  = username
            displayUserLabel.text = username
            displayUserLabelActivityIndicator.stopAnimating()
        }
        
        // Refresh the user image if it exists
        if let userImage = Constants.Data.currentUser.userImage
        {
            self.displayUserImage.image = userImage
            self.displayUserImageActivityIndicator.stopAnimating()
            
            // Store the new image in Core Data for immediate access in next VC loading
            CoreDataFunctions().currentUserSave(user: Constants.Data.currentUser)
        }
    }
    
    func snapToNearestPreviewCell()
    {
        print("MVC - PV - SNAP TO CELL")
        
        // Calculate the scroll position relative to the cells
        let cellWidth = self.previewContainer.frame.width
        let positionByCell = previewCollectionView.contentOffset.x / cellWidth
        print("MVC - PV - positionByCell: \(positionByCell)")
        
        // Find the nearest cell - use the previous scroll position to deterime whether the 
        // user is scrolling up or down in order to snap in the direction of the scroll
        var nearestCell = positionByCell.rounded(FloatingPointRoundingRule.up)
        if previewCollectionView.contentOffset.x - previewStartingScrollPosition < 0
        {
            nearestCell = positionByCell.rounded(FloatingPointRoundingRule.down)
        }
        print("MVC - PV - nearestCell: \(nearestCell)")
        
        // Ensure that the nearestCell is not greater than or equal to the array length (array is 0-indexed)
        var nearestCellInt = Int(nearestCell)
        if nearestCellInt >= Constants.Data.previewBlobContent.count
        {
            nearestCellInt = Constants.Data.previewBlobContent.count - 1
        }
        // Ensure that nearestCellInt will not be less than 0
        if nearestCellInt < 0
        {
            nearestCellInt = 0
        }
        
        // Save the current cell
        Constants.Data.previewCurrentIndex = nearestCellInt
        
        // Create an indexPath and animate the scroll to the proper cell
        let indexPath = NSIndexPath(item: nearestCellInt, section: 0)
        print("MVC - PV - SCROLLING TO CELL: \(indexPath.row)")
        print("MVC - PV - numberOfItems: \(previewCollectionView.numberOfItems(inSection: 0))")
        if previewCollectionView.numberOfItems(inSection: 0) - 1 >= nearestCellInt
        {
            previewCollectionView.scrollToItem(at: indexPath as IndexPath, at: .centeredHorizontally, animated: true)
            
            // Save the current scroll position for the next scroll calculation
            previewStartingScrollPosition = nearestCell * cellWidth
            print("MVC - PV - NEW STARTING SCROLL POSITION: \(previewStartingScrollPosition)")
            
            // Set the new preview count label text but leave blank if equal to "0"
            if nearestCellInt > 0
            {
                previewCountLabelLeft.text = String(nearestCellInt)
            }
            else
            {
                previewCountLabelLeft.text = ""
            }
            
            if Constants.Data.previewBlobContent.count - nearestCellInt - 1 > 0
            {
                previewCountLabelRight.text = String(Constants.Data.previewBlobContent.count - nearestCellInt - 1)
            }
            else
            {
                previewCountLabelRight.text = ""
            }
            
            // Process the preview Circle and adjust the map camera
            processPreviewCircleForCell(cell: nearestCellInt)
        }
    }
    
    func processPreviewCircleForCell(cell: Int)
    {
        print("MVC - PV - PROCESS PREVIEW CIRCLE FOR CELL: \(cell)")
        
        // Reset - remove circle highlights
        unhighlightMapCircleForAllBlobs()
        
        // Reset - remove the added preview circle
        if previewBlobCircle != nil
        {
            previewBlobCircle.map = nil
        }
        
        if cell <= Constants.Data.previewBlobContent.count - 1 && cell >= 0
        {
            // Recall the currently viewed Blob in the preview
            let pBlobContent = Constants.Data.previewBlobContent[cell]
            
            // Add the current Blob to the map, if it does not already exist
            var mBlobExists = false
            mapBlobLoop: for mBlobID in Constants.Data.mapBlobIDs
            {
                if mBlobID == pBlobContent.blobID
                {
                    mBlobExists = true
                    
                    // Highlight the edge of the Blob
                    loopMapCircles: for circle in Constants.Data.mapCircles
                    {
                        if circle.title == mBlobID
                        {
                            circle.strokeColor = Constants.Colors.blobHighlight
                            circle.strokeWidth = 3
                            
                            break loopMapCircles
                        }
                    }
                    
                    print("MVC - PV - MAP ANIMATE TO PREVIEW CIRCLE 1")
                    // Find the actual Blob object
                    blobLoop: for blob in Constants.Data.allBlobs
                    {
                        if blob.blobID == mBlobID
                        {
                            // Move the map to the Blob
                            mapCameraMoveToBlob(blob)
                            break blobLoop
                        }
                    }
                    
                    break mapBlobLoop
                }
            }
            
            // If the Blob doesn't already exist on the map, add the circle and move the map to it
            if !mBlobExists
            {
                // Find the actual Blob object
                blobLoop: for blob in Constants.Data.allBlobs
                {
                    if blob.blobID == pBlobContent.blobID
                    {
                        // Add the Blob to the map
                        previewBlobCircle = GMSCircle()
                        previewBlobCircle.position = CLLocationCoordinate2DMake(blob.blobLat, blob.blobLong)
                        previewBlobCircle.radius = blob.blobRadius
                        previewBlobCircle.title = blob.blobID
                        previewBlobCircle.fillColor = Constants().blobColor(blob.blobType, blobFeature: blob.blobFeature, blobAccess: blob.blobAccess, blobAccount: blob.blobAccount, mainMap: true)
                        previewBlobCircle.strokeColor = Constants.Colors.blobHighlight
                        previewBlobCircle.strokeWidth = 3
                        previewBlobCircle.map = self.mapView
                        
                        print("MVC - PV - MAP ANIMATE TO PREVIEW CIRCLE 2")
                        // Move the map to the Blob
                        mapCameraMoveToBlob(blob)
                        
                        break blobLoop
                    }
                }
            }
        }
    }
    
    // Move the map to focus on a Blob
    func mapCameraMoveToBlob(_ blob: Blob)
    {
        let blobCenter = CLLocationCoordinate2DMake(blob.blobLat, blob.blobLong)
//        let blobEdgeEast = UtilityFunctions().blobEdgeCoordinates(blobCenter, radius: pBlob.blobRadius, east: true)
//        let blobEdgeWest = UtilityFunctions().blobEdgeCoordinates(blobCenter, radius: pBlob.blobRadius, east: false)
//        let coordBounds = GMSCoordinateBounds(coordinate: blobEdgeEast, coordinate: blobEdgeWest)
//        let cameraUpdate = GMSCameraUpdate.fit(coordBounds)
//        self.mapView.animate(with: cameraUpdate)
        let cameraPosition = GMSCameraPosition(target: blobCenter, zoom: UtilityFunctions().mapZoomForBlobSize(Float(blob.blobRadius)), bearing: 0.0, viewingAngle: mapView.camera.viewingAngle)
        self.mapView.animate(to: cameraPosition)
    }
    
//    func snapToNearestCell(scrollView: UIScrollView)
//    {
//        // ONLY USE FOR THE PREVIEW COLLECTION VIEW (only uses y-offset, so only for horizontal collection views)
//        if scrollView == previewCollectionView
//        {
//            //pick first cell to get width
//            let indexPath = NSIndexPath(item: 0, section: 0)
//            if let cell = previewCollectionView.cellForItem(at: indexPath as IndexPath) as UICollectionViewCell?
//            {
//                let cellWidth = cell.frame.size.width
//                
//                cellLoop: for i in 0..<previewCollectionView.numberOfItems(inSection: 0)
//                {
//                    if scrollView.contentOffset.y <= CGFloat(i) * cellWidth + cellWidth / 2
//                    {
//                        let indexPath = NSIndexPath(item: i, section: 0)
//                        print("MVC - SV - SCROLLING TO CELL: \(indexPath.row)")
//                        previewCollectionView.scrollToItem(at: indexPath as IndexPath, at: .centeredHorizontally, animated: true)
//                        break cellLoop
//                    }
//                }
//            }
//        }
//    }
    
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
    func unhighlightMapCircleForAllBlobs()
    {
        // Set all map Circles back to default (no highlighting)
        for mBlobID in Constants.Data.mapBlobIDs
        {
            loopAllBlobs: for blob in Constants.Data.allBlobs
            {
                if blob.blobID == mBlobID
                {
                    unhighlightMapCircleForBlob(blob)
                    
                    // Deselect all mapBlobs (so they don't stick out from the Collection View)
                    blob.blobSelected = false
                    
                    break loopAllBlobs
                }
            }
        }
    }
    // Remove highlighting for the passed Blob
    func unhighlightMapCircleForBlob(_ blob: Blob)
    {
        loopMapCircles: for circle in Constants.Data.mapCircles
        {
            if circle.title == blob.blobID
            {
                circle.strokeColor = Constants().blobColor(blob.blobType, blobFeature: blob.blobFeature, blobAccess: blob.blobAccess, blobAccount: blob.blobAccount, mainMap: true)
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
    
    
    func displayNotification(_ blobContentID: String)
    {
    }
    
    func refreshLocationBlobsCollectionView()
    {
        // Reload the Collection View
        self.locationBlobContentCollectionView.performSelector(onMainThread: #selector(UICollectionView.reloadData), with: nil, waitUntilDone: true)
    }
    
    func refreshPreviewCollectionView()
    {
        print("MVC - PV - REFRESH PREVIEW - PREVIEW COUNT: \(Constants.Data.previewBlobContent.count)")
        
        // Reset the count labels
        previewCountLabelLeft.text = ""
        previewCountLabelRight.text = ""
        
        if let previewCurrentCell = Constants.Data.previewCurrentIndex
        {
            print("MVC - PV - REFRESH PREVIEW - PREVIEW CURRENT CELL: \(previewCurrentCell)")
            
            // Recall the current cell and calculate the labels (but don't populate them if they will show "0"
            if previewCurrentCell > 0
            {
                previewCountLabelLeft.text = String(previewCurrentCell)
            }
            if Constants.Data.previewBlobContent.count - previewCurrentCell - 1 > 0
            {
                previewCountLabelRight.text = String(Constants.Data.previewBlobContent.count - previewCurrentCell - 1)
            }
            
            // Process the first circle for the first Blob
            processPreviewCircleForCell(cell: previewCurrentCell)
        }
        
//        // Reload the Collection View
//        self.previewCollectionView.reloadData()
        
        // Reload the Collection View
        self.previewCollectionView.performSelector(onMainThread: #selector(UICollectionView.reloadData), with: nil, waitUntilDone: true)
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
                        
                        print("MVC - CURRENT USER 2: \(Constants.Data.currentUser.userID)")
                        // Request the user data from AWS to display on the menu screen
                        if let currentUserID = Constants.Data.currentUser.userID
                        {
                            print("MVC - CALLING AWSGetSingleUserData FOR: \(currentUserID)")
                            AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: currentUserID, forPreviewData: false), delegate: self as AWSRequestDelegate).prepRequest()
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
                case _ as AWSGetBlobContent:
                    if success
                    {
                        // Refresh the location collection view and show the blob notification if needed
                        self.refreshLocationBlobsCollectionView()
//                        self.displayNotification(awsGetBlobContent.blobContentID)
                        
                        // Update the previewData array for any new thumbnails
                        self.refreshPreviewCollectionView()
                        
                        // Refresh child VCs
                        if self.blobVC != nil
                        {
                            self.blobVC.refreshDataManually()
                        }
                    }
                    else
                    {
                        // Show the error message
                        self.createAlertOkView("AWSGetBlobContent Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    }
                case _ as AWSGetThumbnailImage:
                    if success
                    {
                        // Update the previewData array for any new thumbnails
                        self.refreshPreviewCollectionView()
                    }
                    else
                    {
                        print("AVC-awsGetThumbnailImage: ERROR")
                    }
                case let awsGetSingleUserData as AWSGetSingleUserData:
                    if success
                    {
                        print("MVC-RCUE - GOT USER DATA")
                        // Refresh the user elements
                        self.refreshCurrentUserElements()
                        
                        // Refresh the collection view
                        self.refreshLocationBlobsCollectionView()
                        
                        // If the MapView called this method to update the Preview Box, send the needed data to the PreviewBox
                        if awsGetSingleUserData.forPreviewData!
                        {
                            self.refreshPreviewCollectionView()
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
                case _ as AWSGetUserBlobContent:
                    if success
                    {
                        print("MVC - PV - AWSGetUserBlobContent RETURN")
                        
                        // Reset the local userBlobContent array and find all BlobContent for the current user
                        self.userBlobContent = [BlobContent]()
                        if Constants.Data.userBlobContentIDs.count > 0
                        {
                            // Assign the global BlobContent that are assigned to the current user to the local array
                            for userBCID in Constants.Data.userBlobContentIDs
                            {
                                blobContentLoop: for blobContent in Constants.Data.blobContent
                                {
                                    if blobContent.blobContentID == userBCID
                                    {
                                        self.userBlobContent.append(blobContent)
                                        break blobContentLoop
                                    }
                                }
                            }
                            
                            // Sort the User Blobs from newest to oldest
                            self.userBlobContent.sort(by: {$0.contentDatetime.timeIntervalSince1970 > $1.contentDatetime.timeIntervalSince1970})
                            
                            // Ensure that the UserBlobs filter is still applied to prevent overwriting another filter
                            if self.previewSelection == "UserBlobs"
                            {
                                // Reset the global preview BlobContent list to ensure all associated variables are also reset
                                UtilityFunctions().resetPreviewData()
                                
                                // Set the previewBlobContent array to the userBlobContent array since the preview CollectionView will use the global previewBlobContent
                                Constants.Data.previewBlobContent = self.userBlobContent
                                
                                // If the previewBlobContent array is populated, indicate that the preview index is on the first Blob
                                if Constants.Data.previewBlobContent.count > 0
                                {
                                    Constants.Data.previewCurrentIndex = 0
                                }
                                
                                // Refresh the Preview Collection View
                                self.refreshPreviewCollectionView()
                            }
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as FBGetUserProfileData:
                    // Do not distinguish between success and failure for this class - both need to have the userList updated
                    // Refresh the collection view
                    self.refreshLocationBlobsCollectionView()
                    
                    // This method is called from within AWSGetSingleUserData
                    // Refresh the user elements
                    self.refreshCurrentUserElements()
                    
                    // Update the preview data
                    self.refreshPreviewCollectionView()
                    
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
