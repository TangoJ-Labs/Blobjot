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

class BlobViewController: UIViewController, GMSMapViewDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Add the view components
    var viewContainer: UIView!
    var blobTableView: UITableView!
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    
    var blobCommentsButton: UIView!
    var blobCommentsButtonIcon: UIImageView!
    var blobCommentsContainer: UIView!
    var blobCommentAddContainer: UIView!
    var blobCommentAddCancelLabel: UILabel!
    var blobCommentAddSendLabel: UILabel!
    var blobCommentAddTextView: UITextView!
    var blobCommentAddTextViewDefaultText: UILabel!
    
    var blobCommentButtonTapGesture: UITapGestureRecognizer!
    var blobCommentAddCancelLabelTapGesture: UITapGestureRecognizer!
    var blobCommentAddSendLabelTapGesture: UITapGestureRecognizer!
    
    // Properties to hold local information
    var blobCommentBoxDefaultHeight: CGFloat!
    var commentBoxWidth: CGFloat!
    
    var viewContainerHeight: CGFloat!
    var blobCellHeight: CGFloat!
    var tableViewHeightArray = [CGFloat]()
    
    // This blob should be initialized when the ViewController is initialized
    var blob: Blob!
    var blobImage: UIImage?
    
    // A property to indicate whether the Blob being viewed was created by the current user
    var userBlob: Bool = false
    
    // A property to indicate whether the Blob has media (whether the comments should automatically be shown or not)
    var blobHasMedia: Bool = false
    
    // An array to hold the comments
    var blobCommentArray = [BlobComment]()
    
    // Dimension properties
    let addCommentViewOffsetX = 10 + Constants.Dim.blobViewCommentUserImageSize

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if blob.blobThumbnailID != nil
        {
            self.blobHasMedia = true
        }
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        print("BVC - UI SCREEN BOUNDS: \(UIScreen.main.bounds)")
        print("BVC - SCREEN BOUNDS: \(self.view.bounds)")
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        let viewContainerOffset = statusBarHeight + navBarHeight - viewFrameY
        self.viewContainerHeight = self.view.bounds.height - viewContainerOffset
        viewContainer = UIView(frame: CGRect(x: 0, y: viewContainerOffset, width: self.view.bounds.width, height: self.viewContainerHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        self.view.addSubview(viewContainer)
        
        // Define the comment box height now that the viewContainer is set
        blobCommentBoxDefaultHeight = viewContainer.frame.height - 250
        commentBoxWidth = viewContainer.frame.width - 30 - Constants.Dim.blobViewCommentUserImageSize
        
        blobCellHeight = self.viewContainerHeight
        if !self.blobHasMedia && !self.userBlob
        {
            blobCellHeight = viewContainer.frame.height - viewContainer.frame.width
        }
        
        // A tableview will hold all comments
        blobTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        blobTableView.dataSource = self
        blobTableView.delegate = self
        blobTableView.register(BlobTableViewCellBlob.self, forCellReuseIdentifier: Constants.Strings.blobTableViewCellBlobWithLabelReuseIdentifier)
        blobTableView.register(BlobTableViewCellBlob.self, forCellReuseIdentifier: Constants.Strings.blobTableViewCellBlobNoLabelReuseIdentifier)
        blobTableView.register(BlobTableViewCellComment.self, forCellReuseIdentifier: Constants.Strings.blobTableViewCellCommentReuseIdentifier)
        blobTableView.separatorStyle = .none
        blobTableView.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        blobTableView.isScrollEnabled = true
        blobTableView.bounces = true
        blobTableView.alwaysBounceVertical = true
        blobTableView.showsVerticalScrollIndicator = false
//        blobTableView.isUserInteractionEnabled = true
//        blobTableView.allowsSelection = true
        blobTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        viewContainer.addSubview(blobTableView)
        
        // Create a refresh control for the CollectionView and add a subview to move the refresh control where needed
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(BlobViewController.refreshDataManually), for: UIControlEvents.valueChanged)
        blobTableView.addSubview(refreshControl)
//        blobTableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
        
        // Add the Add Button in the bottom right corner (hidden if the Blob has media, unhidden if not)
        if self.blobHasMedia || self.userBlob
        {
            blobCommentsButton = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.blobViewButtonSize, y: viewContainer.frame.height + 5 + Constants.Dim.blobViewButtonSize, width: Constants.Dim.blobViewButtonSize, height: Constants.Dim.blobViewButtonSize))
        }
        else
        {
            blobCommentsButton = UIView(frame: CGRect(x: viewContainer.frame.width - 5 - Constants.Dim.blobViewButtonSize, y: viewContainer.frame.height - 5 - Constants.Dim.blobViewButtonSize, width: Constants.Dim.blobViewButtonSize, height: Constants.Dim.blobViewButtonSize))
        }
        blobCommentsButton.layer.cornerRadius = Constants.Dim.blobViewButtonSize / 2
        blobCommentsButton.backgroundColor = Constants.Colors.colorMapViewButton
        blobCommentsButton.layer.shadowOffset = Constants.Dim.mapViewShadowOffset
        blobCommentsButton.layer.shadowOpacity = Constants.Dim.mapViewShadowOpacity
        blobCommentsButton.layer.shadowRadius = Constants.Dim.mapViewShadowRadius
        viewContainer.addSubview(blobCommentsButton)
        
        // The Comment Container should start below the screen and not be visible until called
        blobCommentsContainer = UIView(frame: CGRect(x: 0, y: viewContainer.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height))
        blobCommentsContainer.backgroundColor = UIColor.white
        viewContainer.addSubview(blobCommentsContainer)
        
        // The Text View to add a new comment - should be at the top of the comment container
        blobCommentAddContainer = UIView(frame: CGRect(x: 0, y: 0, width: blobCommentsContainer.bounds.width, height: blobCommentBoxDefaultHeight))
        blobCommentAddContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        blobCommentsContainer.addSubview(blobCommentAddContainer)
        
        blobCommentAddCancelLabel = UILabel(frame: CGRect(x: 5, y: 0, width: (viewContainer.frame.width / 2) - 5, height: 50))
        blobCommentAddCancelLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        blobCommentAddCancelLabel.textColor = Constants.Colors.standardBackgroundGrayUltraLight
        blobCommentAddCancelLabel.textAlignment = .left
        blobCommentAddCancelLabel.numberOfLines = 1
        blobCommentAddCancelLabel.text = "CANCEL"
        blobCommentAddCancelLabel.isUserInteractionEnabled = true
        blobCommentAddContainer.addSubview(blobCommentAddCancelLabel)
        
        blobCommentAddSendLabel = UILabel(frame: CGRect(x: viewContainer.frame.width / 2, y: 0, width: (viewContainer.frame.width / 2) - 5, height: 50))
        blobCommentAddSendLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        blobCommentAddSendLabel.textColor = Constants.Colors.standardBackgroundGrayUltraLight
        blobCommentAddSendLabel.textAlignment = .right
        blobCommentAddSendLabel.numberOfLines = 1
        blobCommentAddSendLabel.text = "SEND"
        blobCommentAddSendLabel.isUserInteractionEnabled = true
        blobCommentAddContainer.addSubview(blobCommentAddSendLabel)
        
        blobCommentAddTextView = UITextView(frame: CGRect(x: 5, y: 50, width: blobCommentAddContainer.bounds.width - 10, height: blobCommentAddContainer.bounds.height - 35))
        blobCommentAddTextView.backgroundColor = UIColor.white
        blobCommentAddTextView.delegate = self
        blobCommentAddTextView.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        blobCommentAddTextView.isScrollEnabled = true
        blobCommentAddTextView.isEditable = true
        blobCommentAddTextView.isSelectable = true
        blobCommentAddContainer.addSubview(blobCommentAddTextView)
        
        blobCommentAddTextViewDefaultText = UILabel(frame: CGRect(x: 0, y: 0, width: blobCommentAddTextView.frame.width, height: 20))
        blobCommentAddTextViewDefaultText.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
        blobCommentAddTextViewDefaultText.textColor = Constants.Colors.colorTextGray
        blobCommentAddTextViewDefaultText.textAlignment = .left
        blobCommentAddTextViewDefaultText.numberOfLines = 1
        blobCommentAddTextViewDefaultText.text = "Add a comment."
        blobCommentAddTextView.addSubview(blobCommentAddTextViewDefaultText)
        
        // Add the Tap Gesture Recognizers for the comment features
        blobCommentButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobViewController.blobCommentButtonTap(_:)))
        blobCommentButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        blobCommentsButton.addGestureRecognizer(blobCommentButtonTapGesture)
        
        blobCommentAddCancelLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobViewController.blobCommentAddCancelLabelTap(_:)))
        blobCommentAddCancelLabelTapGesture.numberOfTapsRequired = 1  // add single tap
        blobCommentAddCancelLabel.addGestureRecognizer(blobCommentAddCancelLabelTapGesture)
        
        blobCommentAddSendLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(BlobViewController.blobCommentAddSendLabelTap(_:)))
        blobCommentAddSendLabelTapGesture.numberOfTapsRequired = 1  // add single tap
        blobCommentAddSendLabel.addGestureRecognizer(blobCommentAddSendLabelTapGesture)
        
        // Request all needed data
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // Add one (for the blob view cell) to the count of comments
        let cellCount = 1 + self.blobCommentArray.count
        
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        print("BVC - CELL HEIGHT - BLOB HEIGHT FOR CELL: \(indexPath.row)")
        
        if indexPath.row == 0
        {
            if self.blobCommentArray.count == 0
            {
                return self.blobCellHeight + 30
            }
            else
            {
                return self.blobCellHeight + 20
            }
        }
        else
        {
            var cellHeight: CGFloat = Constants.Dim.blobViewCommentCellHeight
            var contentSize: CGFloat = Constants.Dim.blobViewCommentCellHeight - 4
            if let text = self.blobCommentArray[indexPath.row - 1].comment
            {
                contentSize = textHeightForAttributedText(text: NSAttributedString(string: text), width: commentBoxWidth)
            }
            print("BVC - CONTENT SIZE FOR CELL: \(indexPath.row): \(contentSize)")
            if contentSize > Constants.Dim.blobViewCommentCellHeight - 4
            {
                cellHeight = contentSize + 4
            }
            
            return cellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if indexPath.row == 0
        {
            let cell: BlobTableViewCellBlob!
            
            if self.blobCommentArray.count == 0
            {
                cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobTableViewCellBlobWithLabelReuseIdentifier, for: indexPath) as! BlobTableViewCellBlob
            }
            else
            {
                cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobTableViewCellBlobNoLabelReuseIdentifier, for: indexPath) as! BlobTableViewCellBlob
            }
            
            // Remove all subviews
            for subview in cell.subviews
            {
                subview.removeFromSuperview()
            }
            
            print("BVC - CELL HEIGHT: \(cell.frame.height)")
            
            var userImageContainer: UIView!
            var userImageView: UIImageView!
            var blobTypeIndicatorView: UIView!
            var blobDatetimeLabel: UILabel!
            var blobDateAgeLabel: UILabel!
            var blobTextViewContainer: UIView!
            var blobTextView: UITextView!
            var blobImageView: UIImageView!
            var mapView: GMSMapView!
            var blobMediaActivityIndicator: UIActivityIndicatorView!
            
            // The User Image should be in the upper right quadrant
            userImageContainer = UIImageView(frame: CGRect(x: 5, y: self.blobCellHeight - 10 - Constants.Dim.blobViewUserImageSize - cell.frame.width, width: Constants.Dim.blobViewUserImageSize, height: Constants.Dim.blobViewUserImageSize))
            userImageContainer.layer.cornerRadius = Constants.Dim.blobViewUserImageSize / 2
            cell.addSubview(userImageContainer)
            
            userImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: userImageContainer.frame.width, height: userImageContainer.frame.height))
            userImageView.layer.cornerRadius = Constants.Dim.blobViewUserImageSize / 2
            userImageView.contentMode = UIViewContentMode.scaleAspectFill
            userImageView.clipsToBounds = true
            userImageContainer.addSubview(userImageView)
            
            // Try to find the globally stored user data
            loopUserCheck: for user in Constants.Data.userObjects
            {
                if user.userID == blob.blobUserID
                {
                    // If the user image has been downloaded, use the image
                    // Otherwise, the image should be downloading currently (requested from the preview box in the Map View)
                    // and should be passed to this controller when downloaded
                    if let userImage = user.userImage
                    {
                        userImageView.image = userImage
                    }
// *COMPLETE******** RECEIVE A NOTIFICATION FROM THE MAP VIEW WHEN THE USER IMAGE HAS BEEN DOWNLOADED (IF NOT ALREADY)
                    
                    break loopUserCheck
                }
            }
            
            // The Blob Type Indicator should be to the top right of the the User Image
            blobTypeIndicatorView = UIView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.blobViewIndicatorSize, height: Constants.Dim.blobViewIndicatorSize))
            blobTypeIndicatorView.layer.cornerRadius = Constants.Dim.blobViewIndicatorSize / 2
            blobTypeIndicatorView.layer.shadowOffset = CGSize(width: 0, height: 0.2)
            blobTypeIndicatorView.layer.shadowOpacity = 0.2
            blobTypeIndicatorView.layer.shadowRadius = 1.0
            // Ensure blobType is not null
            if let blobType = blob.blobType
            {
                // Assign the Blob Type color to the Blob Indicator
                blobTypeIndicatorView.backgroundColor = Constants().blobColorOpaque(blobType)
            }
            cell.addSubview(blobTypeIndicatorView)
            
            // The Date Age Label should be in small font just below the Navigation Bar at the right of the screen (right aligned text)
            blobDateAgeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: blobTypeIndicatorView.frame.width, height: blobTypeIndicatorView.frame.height))
            blobDateAgeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
            blobDateAgeLabel.textColor = Constants.Colors.colorTextGray
            blobDateAgeLabel.textAlignment = .center
            blobTypeIndicatorView.addSubview(blobDateAgeLabel)
            
            // The Datetime Label should be in small font just below the Navigation Bar starting at the left of the screen (left aligned text)
            blobDatetimeLabel = UILabel(frame: CGRect(x: cell.frame.width / 2 - 2, y: 2, width: cell.frame.width / 2 - 2, height: 15))
            blobDatetimeLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 10)
            blobDatetimeLabel.textColor = Constants.Colors.colorTextGray
            blobDatetimeLabel.textAlignment = .right
            cell.addSubview(blobDatetimeLabel)
            
            if let datetime = blob.blobDatetime
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "E, H:mm" //"E, MMM d HH:mm"
                let stringDate: String = formatter.string(from: datetime as Date)
                blobDatetimeLabel.text = stringDate
                let stringAge = String(-1 * Int(datetime.timeIntervalSinceNow / 3600)) + " hrs"
                blobDateAgeLabel.text = stringAge
            }
            
            // The Text View should be in the upper left quadrant of the screen (to the left of the User Image), and should extend into the upper right quadrant nearing the User Image
            if self.blobHasMedia || self.userBlob
            {
                blobTextViewContainer = UIView(frame: CGRect(x: 10 + Constants.Dim.blobViewUserImageSize, y: 50, width: cell.frame.width - 15 - Constants.Dim.blobViewUserImageSize, height: self.blobCellHeight - 60 - cell.frame.width))
            }
            else
            {
                blobTextViewContainer = UIView(frame: CGRect(x: 10 + Constants.Dim.blobViewUserImageSize, y: 50, width: cell.frame.width - 15 - Constants.Dim.blobViewUserImageSize, height: self.blobCellHeight - 50))
            }
            blobTextViewContainer.backgroundColor = UIColor.white
            blobTextViewContainer.layer.cornerRadius = 10
            blobTextViewContainer.layer.shadowOffset = CGSize(width: 0, height: 0.2)
            blobTextViewContainer.layer.shadowOpacity = 0.5
            blobTextViewContainer.layer.shadowRadius = 2.0
            cell.addSubview(blobTextViewContainer)
            
            blobTextView = UITextView(frame: CGRect(x: 0, y: 0, width: blobTextViewContainer.frame.width, height: blobTextViewContainer.frame.height))
            blobTextView.backgroundColor = UIColor.white
            blobTextView.layer.cornerRadius = 10
            blobTextView.font = UIFont(name: Constants.Strings.fontRegular, size: 16)
            blobTextView.isScrollEnabled = true
            blobTextView.isEditable = false
            blobTextView.isSelectable = false
            blobTextView.isUserInteractionEnabled = false
            if let text = blob.blobText
            {
                blobTextView.text = text
            }
            blobTextViewContainer.addSubview(blobTextView)
            
            // The Media Content View should be in the lower half of the screen (partially extending into the upper half)
            // It should span the width of the screen
            // The Image View or the Video Player will be used based on the content (both are the same size, in the same position)
            let blobImageSize = viewContainer.frame.width
            
            // Only show the media section if the blob has media
            if self.blobHasMedia
            {
                blobImageView = UIImageView(frame: CGRect(x: 0, y: self.blobCellHeight - blobImageSize, width: blobImageSize, height: blobImageSize))
                blobImageView.contentMode = UIViewContentMode.scaleAspectFill
                blobImageView.clipsToBounds = true
                
                // Add a loading indicator until the Media has downloaded
                // Give it the same size and location as the blobImageView
                blobMediaActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: self.blobCellHeight - cell.frame.width, width: cell.frame.width, height: cell.frame.width))
                blobMediaActivityIndicator.color = UIColor.black
                
                // Start animating the activity indicator
                blobMediaActivityIndicator.startAnimating()
                print("BVC - MEDIA INDICATOR START")
                
                // Assign the blob image to the image if available - if not, assign the thumbnail until the real image downloads
                if blobImage != nil
                {
                    print("BVC - ADDED BLOB IMAGE")
                    blobImageView.image = blobImage
                    
                    // Stop animating the activity indicator
                    blobMediaActivityIndicator.stopAnimating()
                    print("BVC - MEDIA INDICATOR STOP")
                }
                else if let thumbnailImage = blob.blobThumbnail
                {
                    blobImageView.image = thumbnailImage
                }
                else
                {
                    // Stop animating the activity indicator
                    blobMediaActivityIndicator.stopAnimating()
                    print("BVC - MEDIA INDICATOR STOP")
                }
                cell.addSubview(blobImageView)
                cell.addSubview(blobMediaActivityIndicator)
            }
            
            // Add the Map View only if the Blob being viewed was created by the current user
            if userBlob
            {
                var mapFrame = CGRect(x: 0, y: self.blobCellHeight - 150, width: 150, height: 150)
                var mapZoom: Float = UtilityFunctions().mapZoomForBlobSize(Float(blob.blobRadius)) - 2.0
                
                // If the Blob has media, show the small mapView - If no media exists, show the large mapView
                if !self.blobHasMedia
                {
                    mapFrame = CGRect(x: 0, y: self.blobCellHeight - blobImageSize, width: blobImageSize, height: blobImageSize)
                    mapZoom = mapZoom + 2.0
                }
                let camera = GMSCameraPosition.camera(withLatitude: blob.blobLat, longitude: blob.blobLong, zoom: mapZoom)
                mapView = GMSMapView.map(withFrame: mapFrame, camera: camera)
                mapView.delegate = self
                mapView.mapType = kGMSTypeNormal
                mapView.isIndoorEnabled = true
                mapView.isMyLocationEnabled = false
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
                cell.addSubview(mapView)
                
                self.adjustMapViewCamera(mapView)
            }
            
            // Using the data passed from the parent VC to create a circle on the map to represent the Blob
            let blobCircle = GMSCircle(position: CLLocationCoordinate2DMake(blob.blobLat, blob.blobLong), radius: blob.blobRadius)
            blobCircle.fillColor = Constants().blobColor(blob.blobType)
            blobCircle.strokeColor = Constants().blobColor(blob.blobType)
            blobCircle.strokeWidth = 1
            blobCircle.map = mapView
            
            // Add a comment label to the end of the first cell
            let commentLabel: UILabel!
            if self.blobCommentArray.count == 0
            {
                commentLabel = UILabel(frame: CGRect(x: 0, y: cell.frame.height - 30, width: cell.frame.width, height: 30))
                commentLabel.text = "NO COMMENTS YET"
            }
            else
            {
                commentLabel = UILabel(frame: CGRect(x: 0, y: cell.frame.height - 20, width: cell.frame.width, height: 20))
                commentLabel.text = ""
            }
//            commentLabel.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
            commentLabel.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
            commentLabel.textColor = Constants.Colors.colorTextGray
            commentLabel.textAlignment = .center
            cell.addSubview(commentLabel)
            
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.blobTableViewCellCommentReuseIdentifier, for: indexPath) as! BlobTableViewCellComment
            
            // Remove all subviews
            for subview in cell.subviews
            {
                subview.removeFromSuperview()
            }
            
            print("BTC - CELL HEIGHT: \(cell.frame.height)")
            
            let addCommentView: UITextView!
            
            // If the comment's user is the logged in user, format the comment differently
            if self.blobCommentArray[indexPath.row - 1].userID == Constants.Data.currentUser
            {
                addCommentView = UITextView(frame: CGRect(x: cell.frame.width - 5 - self.commentBoxWidth, y: 2, width: self.commentBoxWidth, height: Constants.Dim.blobViewCommentCellHeight - 4))
                addCommentView.backgroundColor = Constants.Colors.standardBackground
                cell.addSubview(addCommentView)
            }
            else
            {
                addCommentView = UITextView(frame: CGRect(x: self.addCommentViewOffsetX, y: 2, width: self.commentBoxWidth, height: Constants.Dim.blobViewCommentCellHeight - 4))
                addCommentView.backgroundColor = Constants.Colors.colorPurpleLight
                cell.addSubview(addCommentView)
                
                // Add an imageview for the user image for the comment (ONLY IF THE USER IS NOT THE CURRENT USER)
                let userImageView = UIImageView(frame: CGRect(x: 5, y: 5, width: Constants.Dim.blobViewCommentUserImageSize, height: Constants.Dim.blobViewCommentUserImageSize))
                userImageView.layer.cornerRadius = Constants.Dim.blobViewCommentUserImageSize / 2
                userImageView.contentMode = UIViewContentMode.scaleAspectFill
                userImageView.clipsToBounds = true
                userImageView.isUserInteractionEnabled = false
                cell.addSubview(userImageView)
                
                // Modify the user image with the comment user image
                userLoop: for user in Constants.Data.userObjects
                {
                    if user.userID == self.blobCommentArray[indexPath.row - 1].userID
                    {
                        if let commentUserImage = user.userImage
                        {
                            userImageView.image = commentUserImage
                        }
                        break userLoop
                    }
                }
            }
            
            // Add the standard comment view settings
            addCommentView.layer.cornerRadius = 5
            addCommentView.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
            addCommentView.text = self.blobCommentArray[indexPath.row - 1].comment
            addCommentView.isScrollEnabled = false
            addCommentView.isEditable = false
            addCommentView.isSelectable = true
            addCommentView.isUserInteractionEnabled = false
            
            // Check the content size, if it is more than the normal height, resize the textview and cell to match the height
            var contentSize: CGFloat = Constants.Dim.blobViewCommentCellHeight - 4
            if let text = self.blobCommentArray[indexPath.row - 1].comment
            {
                contentSize = textHeightForAttributedText(text: NSAttributedString(string: text), width: commentBoxWidth)
            }
            print("BVC - CONTENT SIZE FOR CELL: \(indexPath.row): \(contentSize)")
            if contentSize > Constants.Dim.blobViewCommentCellHeight - 4
            {
                addCommentView.frame.size.height = contentSize
                cell.frame.size.height = contentSize + 4
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("DID SELECT ROW #\((indexPath as NSIndexPath).item)!")
        
        // Create a back button and title for the Nav Bar
        let backButtonItem = UIBarButtonItem(title: "BLOB \u{2193}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(BlobViewController.popViewController(_:)))
        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        ncTitleText.text = "All People"
        ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 12)
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        // Instantiate the PeopleViewController and pass the Preview Blob UserID to the VC
        let peopleVC = PeopleViewController()
        peopleVC.peopleListTopPerson = self.blobCommentArray[indexPath.row - 1].userID
        
        // Instantiate the Nav Controller and attach the Nav Bar items to the view controller settings
        let navController = UINavigationController(rootViewController: peopleVC)
        peopleVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
        peopleVC.navigationItem.titleView = ncTitle
        
        // Change the Nav Bar color and present the view
        navController.navigationBar.barTintColor = Constants.Colors.colorStatusBar
        self.present(navController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        print("DID DESELECT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
    {
        print("DID HIGHLIGHT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
    {
        print("DID UNHIGHLIGHT ROW: \((indexPath as NSIndexPath).row)")
    }
    
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        print("BVC - SCROLL VIEW POSITION: \(scrollView.contentOffset.y)")
        
        // Ensure the Blob has media - otherwise the comment button is alreay in view
        if self.blobHasMedia || self.userBlob
        {
            if scrollView.contentOffset.y > 0
            {
                // Animate the comment button into view
                UIView.animate(withDuration: 0.2, animations:
                    {
                        self.blobCommentsButton.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.blobViewButtonSize, y: self.viewContainer.frame.height - 5 - Constants.Dim.blobViewButtonSize, width: Constants.Dim.blobViewButtonSize, height: Constants.Dim.blobViewButtonSize)
                    }, completion: nil)
            }
            else
            {
                // Animate the comment button out of view
                UIView.animate(withDuration: 0.2, animations:
                    {
                        self.blobCommentsButton.frame = CGRect(x: self.viewContainer.frame.width - 5 - Constants.Dim.blobViewButtonSize, y: self.viewContainer.frame.height + 5 + Constants.Dim.blobViewButtonSize, width: Constants.Dim.blobViewButtonSize, height: Constants.Dim.blobViewButtonSize)
                    }, completion: nil)
            }
        }
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
    
    
    // MARK: TEXT VIEW DELEGATE METHODS
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        print("BVC - TEXT VIEW SHOULD BEGIN EDITING")
        
        self.blobCommentAddTextViewDefaultText.removeFromSuperview()
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        print("BVC - TEXT VIEW DID BEGIN EDITING")
        
        // Show the add comment labels
        self.blobCommentAddCancelLabel.textColor = Constants.Colors.colorTextGray
        self.blobCommentAddSendLabel.textColor = Constants.Colors.colorTextGray
        
        // Animate the user name edit popup out of view
        UIView.animate(withDuration: 0.2, animations:
            {
                self.blobCommentsContainer.frame = CGRect(x: 0, y: self.viewContainer.frame.height - 250, width: self.blobCommentsContainer.frame.width, height: self.viewContainer.frame.height)
                // + self.addedCommentHeight + 5
            }, completion: nil)
    }
    
    
    // MARK: TAP GESTURE METHODS
    
    func blobCommentButtonTap(_ gesture: UITapGestureRecognizer)
    {
        // Show the keyboard
        self.blobCommentAddTextView.becomeFirstResponder()
        
        // Animate the comment box into view
        UIView.animate(withDuration: 0.2, animations:
            {
                self.blobCommentsContainer.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.width, height: self.viewContainer.frame.height)
            }, completion: nil)
    }
    
    func blobCommentAddCancelLabelTap(_ gesture: UITapGestureRecognizer)
    {
        print("BVC - COMMENT CANCEL")
        // Close the comment box and clear the text view
        self.closeCommentBox()
    }
    
    func blobCommentAddSendLabelTap(_ gesture: UITapGestureRecognizer)
    {
        print("BVC - COMMENT SEND")
        
        if self.blobCommentAddTextView.text != ""
        {
            print("BVC - COMMENT SEND - CONFIRM UPLOAD")
            // Upload the comment
            if let commentText = self.blobCommentAddTextView.text
            {
                AWSPrepRequest(requestToCall: AWSAddCommentForBlob(blobID: self.blob.blobID, comment: commentText), delegate: self as AWSRequestDelegate).prepRequest()
                
                // Add the comment locally
                let addBlobComment = BlobComment()
                addBlobComment.commentID        = "new"
                addBlobComment.blobID           = "new"
                addBlobComment.userID           = Constants.Data.currentUser
                addBlobComment.comment          = commentText
                addBlobComment.commentDatetime  = Date()
                self.blobCommentArray.append(addBlobComment)
                
                // Reload the TableView
                self.blobTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
            }
        }
        
        // Close the comment box and clear the text view
        self.closeCommentBox()
    }
    
    
    // MARK: CUSTOM METHODS
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        print("pop Back to Map View")
        self.dismiss(animated: true, completion: {})
    }
    
    func refreshBlobViewTable()
    {
        print("BVC - REFRESH BLOB VIEW TABLE")
        
        DispatchQueue.main.async(execute:
            {
                if self.blobTableView != nil
                {
                    // Reload the TableView
                    self.blobTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                }
        })
    }
    
    func refreshDataManually()
    {
        print("BVC - REFRESH DATA MANUALLY")
        
        // Request the image
        AWSPrepRequest(requestToCall: AWSGetBlobImage(blob: self.blob), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Request the Blob comments
        AWSPrepRequest(requestToCall: AWSGetBlobComments(blobID: self.blob.blobID), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    func closeCommentBox()
    {
        // Hide the keyboard
        self.blobCommentAddTextView.resignFirstResponder()
        
        // Clear the text
        self.blobCommentAddTextView.text = ""
        
        // Animate the comment box out of view
        UIView.animate(withDuration: 0.2, animations:
            {
                self.blobCommentsContainer.frame = CGRect(x: 0, y: self.viewContainer.frame.height, width: self.viewContainer.frame.width, height: self.blobCommentBoxDefaultHeight)
            }, completion:
            { (finished: Bool) -> Void in
                
                // Hide the add comment labels
                self.blobCommentAddCancelLabel.textColor = Constants.Colors.standardBackgroundGrayUltraLight
                self.blobCommentAddSendLabel.textColor = Constants.Colors.standardBackgroundGrayUltraLight
                
                // Show the comment box default text
                self.blobCommentAddTextView.addSubview(self.blobCommentAddTextViewDefaultText)
        })
    }
    
    func tableViewHeight() -> CGFloat {
        self.blobTableView.layoutIfNeeded()
        
        return self.blobTableView.contentSize.height
    }
    
    func textHeightForAttributedText(text: NSAttributedString, width: CGFloat) -> CGFloat
    {
        let calculationView = UITextView()
        calculationView.attributedText = text
        let size = calculationView.sizeThatFits(CGSize(width: width, height: CGFloat(FLT_MAX)))
        return size.height
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
                case _ as AWSAddBlobView:
                    if !success
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSAddBlobView - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetBlobImage as AWSGetBlobImage:
                    if success
                    {
                        print("BVC - AWS RETURN - AWSGetBlobImage")
                        if let blobImage = awsGetBlobImage.blobImage
                        {
                            // Set the local image property to the downloaded image
                            self.blobImage = blobImage
                            
                            // Reload the TableView
                            self.refreshBlobViewTable()
                            
                            print("BVC - ADDED IMAGE FOR BLOB WITH TEXT: \(awsGetBlobImage.blob.blobText)")
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetBlobImage - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsGetBlobComments as AWSGetBlobComments:
                    if success
                    {
                        print("BVC - AWS RETURN - AWSGetBlobComments")
                        
                        self.blobCommentArray = awsGetBlobComments.blobCommentArray
                        
                        print("BVC - COMMENT COUNT: \(self.blobCommentArray.count)")
                        
                        // Check to ensure that the user data has been downloaded for each comment's user
                        // If not, download the user data (AWSGetUserImage will be called after AWSGetSingleUserData - so listen for AWSGetUserImage's return)
                        for blobComment in self.blobCommentArray
                        {
                            userLoop: for user in Constants.Data.userObjects
                            {
                                var userExists = false
                                if user.userID == blobComment.userID
                                {
                                    userExists = true
                                    break userLoop
                                }
                                if !userExists
                                {
                                    AWSPrepRequest(requestToCall: AWSGetSingleUserData(userID: blobComment.userID, forPreviewBox: false), delegate: self as AWSRequestDelegate).prepRequest()
                                }
                            }
                        }
                        
                        // Stop the refresh controller and reload the table
                        self.refreshControl.endRefreshing()
                        self.refreshBlobViewTable()
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetBlobComments - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as AWSGetSingleUserData:
                    if success
                    {
                        print("BVC - AWS RETURN - AWSGetSingleUserData")
                        
                        // Reload the TableView
                        self.refreshBlobViewTable()
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetUserImage - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as AWSGetUserImage:
                    if success
                    {
                        print("BVC - AWS RETURN - AWSGetUserImage")
                        // A new user image was just downloaded for a user in the blob comment list
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
