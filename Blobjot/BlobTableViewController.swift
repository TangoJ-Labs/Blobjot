//
//  BlobViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 7/28/16.
//  Copyright © 2016 tangojlabs. All rights reserved.
//

import AWSLambda
import AWSS3
import GoogleMaps
import UIKit

class BlobTableViewController: UIViewController, GMSMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Add the view components
    var viewContainer: UIView!
    var blobContentTableView: UITableView!
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    
    // Properties to hold local information
    var viewContainerHeight: CGFloat!
    var blobCellWidth: CGFloat!
//    var blobCellContentHeight: CGFloat!
    var blobMediaSize: CGFloat!
    var blobTextViewWidth: CGFloat!
//    var blobTextViewHeight: CGFloat = 0
    var blobTextViewOffsetY: CGFloat = 50
    
    // This data should be initialized when the ViewController is initialized
    var blobContentArray = [BlobContent]()
    
    // Dimension properties
    let addContentViewOffsetX = 10 + Constants.Dim.blobViewContentUserImageSize

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        let viewContainerOffset = statusBarHeight + navBarHeight - viewFrameY
        self.viewContainerHeight = self.view.bounds.height - viewContainerOffset
        viewContainer = UIView(frame: CGRect(x: 0, y: viewContainerOffset, width: self.view.bounds.width, height: self.viewContainerHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        self.view.addSubview(viewContainer)
        
        // Set the main cell standard dimensions
        blobCellWidth = viewContainer.frame.width
        blobTextViewWidth = viewContainer.frame.width - 15 - Constants.Dim.blobViewUserImageSize
        blobMediaSize = viewContainer.frame.width
        
        // A tableview will hold all comments
        blobContentTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        blobContentTableView.dataSource = self
        blobContentTableView.delegate = self
        blobContentTableView.register(BlobTableViewCell.self, forCellReuseIdentifier: Constants.Strings.blobTableViewCellReuseIdentifier)
        blobContentTableView.separatorStyle = .none
        blobContentTableView.backgroundColor = Constants.Colors.standardBackground
        blobContentTableView.isScrollEnabled = true
        blobContentTableView.bounces = true
        blobContentTableView.alwaysBounceVertical = true
        blobContentTableView.showsVerticalScrollIndicator = false
//        blobContentTableView.isUserInteractionEnabled = true
//        blobContentTableView.allowsSelection = true
        blobContentTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(blobContentTableView)
        
        // Create a refresh control for the CollectionView and add a subview to move the refresh control where needed
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(BlobTableViewController.refreshDataManually), for: UIControlEvents.valueChanged)
        blobContentTableView.addSubview(refreshControl)
//        blobTableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
        
        // Request all needed data and prep the cells
        self.refreshDataManually()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let cellCount = self.blobContentArray.count
        
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        var cellHeight: CGFloat = 0
        if let height = self.blobContentArray[indexPath.row].contentHeight
        {
            cellHeight = height
        }
        
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobTableViewCellReuseIdentifier, for: indexPath) as! BlobTableViewCell
        
        // Store the blobContent for this cell for reference
        let cellBlobContent = self.blobContentArray[indexPath.row]
        
        var cellHeight: CGFloat = 0
        if let height = cellBlobContent.contentHeight
        {
            cellHeight = height
        }
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        var cellContainer: UIView!
        var userImageContainer: UIView!
        var userImageView: UIImageView!
        var blobTypeIndicatorView: UIView!
        var textContainer: UIView!
        var userNameLabel: UILabel!
        var datetimeLabel: UILabel!
        var textViewContainer: UIView!
        var textView: UITextView!
        var imageView: UIImageView!
        var mediaActivityIndicator: UIActivityIndicatorView!
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cellHeight))
        cell.addSubview(cellContainer)
        
        if indexPath.row > 0
        {
            let border1 = CALayer()
            border1.frame = CGRect(x: 0, y: 0, width: cellContainer.frame.width, height: 1)
            border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
            cellContainer.layer.addSublayer(border1)
        }
        
        // The Blob Type Indicator should be a small vertical bar on the far left edge
        blobTypeIndicatorView = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Dim.blobViewTypeIndicatorWidth, height: cellHeight))
        
        // Assign the Blob Type color to the Blob Indicator
        if let blobType = cellBlobContent.blobType
        {
            blobTypeIndicatorView.backgroundColor = Constants().blobColorOpaque(blobType, blobFeature: cellBlobContent.blobFeature, blobAccess: cellBlobContent.blobAccess, blobAccount: cellBlobContent.blobAccount, mainMap: false)
            cellContainer.addSubview(blobTypeIndicatorView)
        }
        
        // The User Image should be in the upper right quadrant
        userImageContainer = UIImageView(frame: CGRect(x: 7, y: 2, width: Constants.Dim.blobViewUserImageSize, height: Constants.Dim.blobViewUserImageSize))
        userImageContainer.layer.cornerRadius = Constants.Dim.blobViewUserImageSize / 2
        cellContainer.addSubview(userImageContainer)
        
        userImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: userImageContainer.frame.width, height: userImageContainer.frame.height))
        userImageView.layer.cornerRadius = Constants.Dim.blobViewUserImageSize / 2
        userImageView.contentMode = UIViewContentMode.scaleAspectFill
        userImageView.clipsToBounds = true
        userImageContainer.addSubview(userImageView)
        
        // Add a container to hold the date labels - should be to the right of the user image at the top of the cell
        textContainer = UIView(frame: CGRect(x: 10 + Constants.Dim.blobViewUserImageSize, y: 2, width: cell.frame.width - 2 - (10 + Constants.Dim.blobViewUserImageSize), height: Constants.Dim.blobViewUserImageSize))
        cellContainer.addSubview(textContainer)
        
        // The Date Age Label should be in small font just below the Navigation Bar at the right of the screen (right aligned text)
        userNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: textContainer.frame.width / 2, height: textContainer.frame.height))
        userNameLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
        userNameLabel.textColor = Constants.Colors.colorTextGray
        userNameLabel.textAlignment = .left
        textContainer.addSubview(userNameLabel)
        
        // The Datetime Label should be in small font just below the Navigation Bar starting at the left of the screen (left aligned text)
        datetimeLabel = UILabel(frame: CGRect(x: textContainer.frame.width / 2, y: 0, width: textContainer.frame.width / 2, height: textContainer.frame.height))
        datetimeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
        datetimeLabel.textColor = Constants.Colors.colorTextGray
        datetimeLabel.textAlignment = .right
        textContainer.addSubview(datetimeLabel)
        
        // Try to find the globally stored user data
        loopUserCheck: for user in Constants.Data.userObjects
        {
            if user.userID == cellBlobContent.userID
            {
                // If the user image has been downloaded, use the image
                // Otherwise, the image should be downloading currently (requested from the preview box in the Map View)
                // and should be passed to this controller when downloaded
                if let userImage = user.userImage
                {
                    userImageView.image = userImage
                }
                if let userName = user.userName
                {
                    // Assign the userName
                    userNameLabel.text = userName
                }
                
                break loopUserCheck
            }
        }
        
        if let datetime = cellBlobContent.contentDatetime
        {
            // Capture the number of hours it has been since the Blob was created (as a positive integer)
            let dateAgeHrs: Int = -1 * Int(datetime.timeIntervalSinceNow / 3600)
            
            // Set the datetime label.  If the Blob's recency is less than 5 days (120 hours), just show the day and time.
            // If the Blob's recency is more than 5 days, include the date
            let formatter = DateFormatter()
            formatter.amSymbol = "am"
            formatter.pmSymbol = "pm"
            
            // Set the date age label.  If the age is less than 24 hours, just show it in hours.  Otherwise, show the number of days and hours.
            var stringDate = String(dateAgeHrs / Int(24)) + " days" //+ String(dateAgeHrs % 24) + " hrs"
            if dateAgeHrs < 24
            {
                stringDate = String(dateAgeHrs) + " hrs"
            }
            else if dateAgeHrs < 48
            {
                stringDate = "1 day"
            }
            else if dateAgeHrs < 120
            {
                formatter.dateFormat = "E, H:mma"
                stringDate = formatter.string(from: datetime as Date)
            }
            else
            {
                formatter.dateFormat = "E, MMM d" // "E, MMM d, H:mma"
                stringDate = formatter.string(from: datetime as Date)
            }
            datetimeLabel.text = stringDate
        }
        
        // Only add the Blob Text View if the Blob has text
        if cellBlobContent.contentType == Constants.ContentType.text
        {
            if cellBlobContent.contentExtraRequested
            {
                // The Text View should be below the User Image, the width of the cell (minus the indicator on the left side)
                textViewContainer = UIView(frame: CGRect(x: 7, y: 2 + Constants.Dim.blobViewUserImageSize, width: cell.frame.width - 10, height: cellHeight - 2 - (5 + Constants.Dim.blobViewUserImageSize)))
                textViewContainer.backgroundColor = UIColor.clear
                cellContainer.addSubview(textViewContainer)
                
                textView = UITextView(frame: CGRect(x: 0, y: 0, width: textViewContainer.frame.width, height: textViewContainer.frame.height))
                textView.backgroundColor = UIColor.clear
                textView.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
                textView.isScrollEnabled = false
                textView.isEditable = false
                textView.isSelectable = false
                textView.isUserInteractionEnabled = false
                if let contentText = cellBlobContent.contentText
                {
                    textView.text = contentText
                }
                textViewContainer.addSubview(textView)
            }
            else
            {
                // The Blob is out of range of the user's current location, so change the username to text indicating that the Blob is out of range
                userNameLabel.textColor = Constants.Colors.colorRedOpaque
                if cellBlobContent.blobType == Constants.BlobType.location
                {
                    userNameLabel.text = "Blob is out of range"
                }
                else
                {
                    userNameLabel.text = "Blob still downloading..."
                }
            }
        }
        
        // The Media Content View should be in the lower portion of the screen
        // Only show the media section if the blob has media
        print("BVC - CONTENT TYPE: \(cellBlobContent.contentType)")
        if cellBlobContent.contentType == Constants.ContentType.image
        {
            print("BVC - CONTENT TYPE IMAGE")
            if cellBlobContent.contentExtraRequested
            {
                imageView = UIImageView(frame: CGRect(x: 5, y: 4 + Constants.Dim.blobViewUserImageSize, width: cell.frame.width - 5, height: cellHeight - (4 + Constants.Dim.blobViewUserImageSize)))
                imageView.contentMode = UIViewContentMode.scaleAspectFill
                imageView.clipsToBounds = true
                
                // Add a loading indicator until the Media has downloaded
                // Give it the same size and location as the blobImageView
                mediaActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height))
                mediaActivityIndicator.color = UIColor.black
                
                // Start animating the activity indicator
                mediaActivityIndicator.startAnimating()
                print("BVC - IMAGE ID: \(cellBlobContent.contentMediaID)")
                // Assign the blob image to the image if available - if not, assign the thumbnail until the real image downloads
                if let contentImage = cellBlobContent.contentImage
                {
                    imageView.image = contentImage
                    
                    // Stop animating the activity indicator
                    mediaActivityIndicator.stopAnimating()
                }
                else if let thumbnailImage = cellBlobContent.contentThumbnail
                {
                    imageView.image = thumbnailImage
                    print("BVC - IMAGE CONTENT VIEWED: \(cellBlobContent.contentViewed)")
                    // If the content has not already been viewed, recall the contentImage (otherwise it has already been requested)
                    if !cellBlobContent.contentViewed
                    {
                        AWSPrepRequest(requestToCall: AWSGetMediaImage(blobContent: cellBlobContent), delegate: self as AWSRequestDelegate).prepRequest()
                        
                        cellBlobContent.contentViewed = true
                    }
                }
                cellContainer.addSubview(imageView)
                cellContainer.addSubview(mediaActivityIndicator)
            }
            else
            {
                // The Blob is out of range of the user's current location, so change the username to text indicating that the Blob is out of range
                userNameLabel.textColor = Constants.Colors.colorRedOpaque
                if cellBlobContent.blobType == Constants.BlobType.location
                {
                    userNameLabel.text = "Blob is out of range"
                }
                else
                {
                    userNameLabel.text = "Blob still downloading..."
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Ensure that a comment was selected (not the Blob content in cell 0)
        if indexPath.row > 0
        {
            // Create a back button and title for the Nav Bar
            let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                                 style: UIBarButtonItemStyle.plain,
                                                 target: self,
                                                 action: #selector(BlobTableViewController.popViewController(_:)))
            backButtonItem.tintColor = Constants.Colors.colorTextNavBar
            
            let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
            let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
            ncTitleText.text = "All People"
            ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
            ncTitleText.textColor = Constants.Colors.colorTextNavBar
            ncTitleText.textAlignment = .center
            ncTitle.addSubview(ncTitleText)
            
//            // Instantiate the PeopleViewController and pass the Preview Blob UserID to the VC
//            let peopleVC = PeopleViewController()
//            peopleVC.peopleListTopPerson = self.blobContentArray[indexPath.row].userID
//            
//            // Assign the created Nav Bar settings to the Tab Bar Controller
//            peopleVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
//            peopleVC.navigationItem.titleView = ncTitle
//            
//            if let navController = self.navigationController
//            {
//                navController.pushViewController(peopleVC, animated: true)
//            }
            
            // Save an action in Core Data
            CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
    {
    }
    
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        
    }
    
    
    // MARK: MAPVIEW DELEGATE METHODS
    
    // Called after the map is moved
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition)
    {
        // Adjust the Map Camera back to apply the correct camera angle
        adjustMapViewCamera(mapView)
    }
    
    // Angle the map automatically if the zoom is high enough
    func adjustMapViewCamera(_ mapView: GMSMapView)
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
    
    
    // MARK: CUSTOM METHODS
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        self.navigationController!.popViewController(animated: true)
    }
    func popViewController()
    {
        self.navigationController!.popViewController(animated: true)
    }
    
    func refreshBlobViewTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.blobContentTableView != nil
                {
                    // Reload the TableView
                    self.blobContentTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                }
        })
    }
    
    func refreshDataManually()
    {
        // The global PreviewBlobContent array might be updated
        blobContentArray = Constants.Data.previewBlobContent
        
        // Prep the cell content to ensure the images are downloaded and the cell heights are calculated
        prepCells()
    }

//    func bringAddBlobViewControllerTopOfStack(_ newVC: Bool)
//    {
//        if newVC || addBlobVC == nil
//        {
//            addBlobVC = BlobAddViewController()
//            addBlobVC!.blobAddViewDelegate = self
//            
//            // Pass the Blob type, coordinates, and the current map zoom to the new View Controller (from the currently viewed blob)
//            addBlobVC!.blobType = blob.blobType
//            addBlobVC!.blobCoords = CLLocationCoordinate2DMake(blob.blobLat, blob.blobLong)
//            addBlobVC!.mapZoom = UtilityFunctions().mapZoomForBlobSize(Float(blob.blobRadius))
//            
//            // Create a Nav Bar Back Button and Title
//            let backButtonItem = UIBarButtonItem(title: "CANCEL",
//                                                 style: UIBarButtonItemStyle.plain,
//                                                 target: self,
//                                                 action: #selector(self.popViewController(_:)))
//            backButtonItem.tintColor = Constants.Colors.colorTextNavBar
//            
//            let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
//            let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
//            ncTitleText.text = "Add Content"
//            ncTitleText.textColor = Constants.Colors.colorTextNavBar
//            ncTitleText.textAlignment = .center
//            ncTitle.addSubview(ncTitleText)
//            
//            // Pass the Blob Radius to the View Controller
//            addBlobVC!.blobRadius = blob.blobRadius
//            addBlobVC!.navigationItem.setLeftBarButton(backButtonItem, animated: true)
//            addBlobVC!.navigationItem.titleView = ncTitle
//        }
//        
//        // Add the View Controller to the Nav Controller and present the Nav Controller
//        if let navController = self.navigationController
//        {
//            navController.pushViewController(addBlobVC!, animated: true)
//        }
//        
//        // Save an action in Core Data
//        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
//    }
    
    // The parent VC will hide any activity indicators showing background activity
    func hideBackgroundActivityView(_ refreshBlobs: Bool)
    {
        // Required for the Blob Add View Delegate
    }
    
    // Used to add the new Blob to the map
    func createBlobOnMap(_ blob: Blob)
    {
        // Required for the Blob Add View Delegate
    }
    
    func tableViewHeight() -> CGFloat
    {
        self.blobContentTableView.layoutIfNeeded()
        
        return self.blobContentTableView.contentSize.height
    }
    
    func textHeightForAttributedText(text: NSAttributedString, width: CGFloat) -> CGFloat
    {
        let calculationView = UITextView()
        calculationView.attributedText = text
        let size = calculationView.sizeThatFits(CGSize(width: width, height: CGFloat(FLT_MAX)))
        return size.height
    }
    
    func prepCells()
    {
        // Process each downloaded BlobContent
        for blobContentObject in blobContentArray
        {
            // Find the associated Blob Object and store the needed properties in the BlobContent Object
            blobLoop: for blob in Constants.Data.allBlobs
            {
                if blob.blobID == blobContentObject.blobID
                {
                    blobContentObject.blobType = blob.blobType
                    blobContentObject.blobAccount = blob.blobAccount
                    blobContentObject.blobFeature = blob.blobFeature
                    blobContentObject.blobAccess = blob.blobAccess
                    break blobLoop
                }
            }
            print("BVC-PC - BC ARRAY: \(blobContentObject.blobContentID), \(blobContentObject.blobType), \(blobContentObject.contentType), \(blobContentObject.contentText)")
            
            // Calculate the needed height for each cell
            var cellHeight: CGFloat = 4 + Constants.Dim.blobViewUserImageSize
            if blobContentObject.contentType == Constants.ContentType.image && blobContentObject.contentMediaID != nil
            {
                cellHeight = cellHeight + self.viewContainer.frame.width - Constants.Dim.blobViewTypeIndicatorWidth
                
                // DON'T RECALL THE CONTENT IMAGE UNTIL IT IS LOADED IN VIEW
            }
            else if blobContentObject.contentType == Constants.ContentType.text && blobContentObject.contentText != nil
            {
                var contentSize: CGFloat = 0
                if let text = blobContentObject.contentText
                {
                    contentSize = 10 + self.textHeightForAttributedText(text: NSAttributedString(string: text), width: self.viewContainer.frame.width - Constants.Dim.blobViewTypeIndicatorWidth)
                }
                cellHeight = cellHeight + contentSize
            }
            // Add the calculated cell height to the contentObject
            blobContentObject.contentHeight = cellHeight
            
            // Check to ensure that the user data has been downloaded for each content's user
            // If not, download the user data (AWSGetUserImage will be called after AWSGetSingleUserData - so listen for AWSGetUserImage's return)
            userLoop: for user in Constants.Data.userObjects
            {
                var userExists = false
                if user.userID == blobContentObject.userID
                {
                    userExists = true
                    break userLoop
                }
                if !userExists
                {
                    AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: blobContentObject.userID, forPreviewData: false), delegate: self as AWSRequestDelegate).prepRequest()
                }
            }
            
            // Stop the refresher spinner
            self.refreshControl.endRefreshing()
            
// ******** COMPLETE: ADD BLOBCONTENT VIEW
//            if let currentUserID = Constants.Data.currentUser.userID
//            {
//                // Add a BlobContent view in AWS
//                AWSPrepRequest(requestToCall: AWSAddBlobView(blobID: self.blob.blobID, userID: currentUserID), delegate: self as AWSRequestDelegate).prepRequest()
//            }
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
                case _ as AWSBlobContentAction:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSAddBlobView - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetMediaImage as AWSGetMediaImage:
                    if success
                    {
                        if let contentImage = awsGetMediaImage.contentImage
                        {
                            // Find the blobContent Object in the local array and add the downloaded image to the object variable
                            findBlobContentLoop: for contentObject in self.blobContentArray
                            {
                                if contentObject.blobContentID == awsGetMediaImage.blobContent.blobContentID
                                {
                                    // Set the local image property to the downloaded image
                                    contentObject.contentImage = contentImage
                                    
                                    break findBlobContentLoop
                                }
                            }
                            
                            // Reload the TableView
                            self.refreshBlobViewTable()
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("awsGetBlobContentImage - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
//                case let awsGetBlobContent as AWSGetBlobContent:
//                    if success
//                    {
//                        // Clear the local array
//                        self.blobContentArray = [BlobContent]()
//                        
//                        // Stop the refresh controller and reload the table
//                        self.refreshControl.endRefreshing()
//                        self.refreshBlobViewTable()
//                    }
//                    else
//                    {
//                        // Show the error message
//                        let alertController = UtilityFunctions().createAlertOkView("AWSGetBlobComments - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
//                        self.present(alertController, animated: true, completion: nil)
//                    }
                case _ as AWSGetSingleUserData:
                    if success
                    {
                        // Reload the TableView
                        self.refreshBlobViewTable()
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetUserImage - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("BVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("DEFAULT - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }

}
