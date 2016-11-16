//
//  Constants.swift
//  Blobjot
//
//  Created by Sean Hart on 7/23/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import AWSCore
import GoogleMaps
import UIKit

struct Constants
{
    
    static var inBackground = false
    static var appDelegateLocationManager = CLLocationManager()
    
    static var credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.Strings.awsRegion, identityPoolId: Constants.Strings.awsCognitoIdentityPoolID)
    
    enum LogType: String
    {
        case error = "error"
        case userflow = "userflow"
    }
    
    enum BlobTypes: Int
    {
        case temporary = 1
        case permanent = 2
        case `public` = 3
        case invisible = 4
        case sponsoredTemporary = 5
        case sponsoredPermanent = 6
    }
    
    enum UserStatusTypes: Int
    {
        case pending = 0
        case waiting = 1
        case connected = 2
        case notConnected = 3
        case blocked = 4
    }
    
    func logType(_ logType: String) -> Constants.LogType
    {
        // Evaluate the blobType Integer received and convert it to the appropriate BlobType Class
        switch logType
        {
        case "error":
            return Constants.LogType.error
        case "userflow":
            return Constants.LogType.userflow
        default:
            return Constants.LogType.error
        }
    }
    
    func blobTypes(_ blobTypeInt: Int) -> Constants.BlobTypes
    {
        // Evaluate the blobType Integer received and convert it to the appropriate BlobType Class
        switch blobTypeInt
        {
        case 1:
            return Constants.BlobTypes.temporary
        case 2:
            return Constants.BlobTypes.permanent
        case 3:
            return Constants.BlobTypes.public
        case 4:
            return Constants.BlobTypes.invisible
        case 5:
            return Constants.BlobTypes.sponsoredTemporary
        case 6:
            return Constants.BlobTypes.sponsoredPermanent
        default:
            return Constants.BlobTypes.temporary
        }
    }
    
    func blobColor(_ blobType: Constants.BlobTypes, mainMap: Bool) -> UIColor
    {
        switch blobType
        {
        case .temporary:
            return Constants.Colors.blobRed
        case .permanent:
            return Constants.Colors.blobYellow
        case .public:
            return Constants.Colors.blobPurple
        case .invisible:
            if mainMap
            {
                return Constants.Colors.blobInvisible
            }
            else
            {
                return Constants.Colors.blobGray
            }
        default:
            return Constants.Colors.blobRed
        }
    }
    
    func blobColorOpaque(_ blobType: Constants.BlobTypes, mainMap: Bool) -> UIColor
    {
        switch blobType
        {
        case .temporary:
            return Constants.Colors.blobRedOpaque
        case .permanent:
            return Constants.Colors.blobYellowOpaque
        case .public:
            return Constants.Colors.blobPurpleOpaque
        case .invisible:
            if mainMap
            {
                return Constants.Colors.blobInvisible
            }
            else
            {
                return Constants.Colors.blobGrayOpaque
            }
        default:
            return Constants.Colors.blobRedOpaque
        }
    }
    
    struct Colors
    {
        
        static let standardBackground = UIColor.white
        static let standardBackgroundTransparent = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8) //#FFF
        static let standardBackgroundGray = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 1.0) //#686868
        static let standardBackgroundGrayTransparent = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 0.3) //#686868
        static let standardBackgroundGrayUltraLight = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
//        static let colorStatusBar = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
//        static let colorTopBar = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1.0) //#404040
//        static let colorStatusBar = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
//        static let colorTopBar = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
        static let colorStatusBar = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorTopBar = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorBorderGrayLight = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0) //#CCC
//        static let colorTextNavBar = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0) //#333333
        static let colorTextNavBar = UIColor.white
        static let colorGrayLight = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0) //#CCC
        static let colorGrayDark = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
        
        static let colorTextStandard = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3) //#000000
        static let colorTextGray = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
        static let colorTextGrayMedium = UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0) //#8C8C8C
        static let colorTextGrayLight = UIColor(red: 154/255, green: 154/255, blue: 154/255, alpha: 1.0) //#999999
        
        static let colorUsernameAvailable = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorUsernameNotAvailable = UIColor(red: 242/255, green: 105/255, blue: 99/255, alpha: 1.0) //#F26963
        
        static let blobInvisible = UIColor.clear
        static let blobGray = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3) //#000000
        static let blobGrayOpaque = UIColor(red: 154/255, green: 154/255, blue: 154/255, alpha: 1.0) //#999999
        static let blobRed = UIColor(red: 242/255, green: 105/255, blue: 99/255, alpha: 0.3) //#F26963
        static let blobRedOpaque = UIColor(red: 242/255, green: 105/255, blue: 99/255, alpha: 1.0) //#F26963
        static let blobYellow = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 0.3) //#FCB249
        static let blobYellowOpaque = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 1.0) //#FCB249
        static let blobPurple = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 0.3) //#8A70B2
        static let blobPurpleOpaque = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let blobHighlight = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 1.0) //#686868
        
        static let colorPurple = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorPurpleTransparent = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 0.3) //#8A70B2
        static let colorPurpleLight = UIColor(red: 215/255, green: 206/255, blue: 228/255, alpha: 1.0) //#D7CEE4
        static let colorPurpleDark = UIColor(red: 84/255, green: 62/255, blue: 116/255, alpha: 1.0) //#543E74
        
        static let colorBlue = UIColor(red: 0/255, green: 153/255, blue: 255/255, alpha: 1.0) //#0099FF
        static let colorBlueLight = UIColor(red: 102/255, green: 194/255, blue: 255/255, alpha: 1.0) //#66C2FF
        static let colorBlueExtraLight = UIColor(red: 153/255, green: 214/255, blue: 255/255, alpha: 1.0) //#99D6FF
        
        static let colorPink = UIColor(red: 255/255, green: 0/255, blue: 102/255, alpha: 1.0) //#FF0066
        
        static let colorStarSelected = UIColor.yellow
        static let colorStarLarge = UIColor.lightGray.withAlphaComponent(0.9)
        
        static let colorBlobAddPeopleSearchBar = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorPeopleSearchBar = UIColor.gray
        
        static let colorPreviewTextNormal = UIColor.black
        static let colorPreviewTextError = UIColor.red
        
        static let colorMapViewButton = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        
    }
    
    struct Data {
        
        static var badgeNumber = 0
        static var attemptedLogin: Bool = false
        static var serverTries: Int = 0
        static var lastCredentials: TimeInterval = Date().timeIntervalSince1970
        static var stillSendingBlob: Bool = false
        
        static var currentUser: String = "" //DON_QUIXOTE: MY9QP9I8HW6ZDMWA || THE_LADY_WITH_COFFEE: 70X4ODWM6D4AL2H4 || TEST_USER: NOLFGJEJ5KX6AIE2 // THE LOGGED IN USER
        static var currentUserName: String?
        static var currentUserImage: UIImage?
        
        static var mapBlobs = [Blob]()
        static var userBlobs = [Blob]()
        static var defaultBlob = Blob(blobID: "default", blobUserID: "default", blobLat: 0.0, blobLong: 0.0, blobRadius: 0.0, blobType: Constants.BlobTypes.invisible, blobMediaType: 1, blobText: "Check out Blobjot.com!")
        
        static var mapCircles = [GMSCircle]()
        static var locationBlobs = [Blob]()
        static var blobThumbnailObjects = [BlobThumbnailObject]()
        static var userObjects = [User]()
        
    }
    
    struct Dim {
        
        static let statusBarStandardHeight: CGFloat = 20
        
        static let mapViewButtonSize: CGFloat = 40
        static let mapViewButtonAddSize: CGFloat = 40
        static let mapViewButtonSearchSize: CGFloat = 40
        static let mapViewButtonListSize: CGFloat = 40
        static let mapViewButtonAccountSize: CGFloat = 40
        static let mapViewButtonTrackUserSize: CGFloat = 40
        
        static let mapViewSearchBarContainerHeight: CGFloat = 45
        static let mapViewSearchBarHeight: CGFloat = 25
        static let mapViewPreviewContainerHeight: CGFloat = 45
        
        static let mapViewLocationBlobsCVCellSize: CGFloat = 50
        static let mapViewLocationBlobsCVItemSize: CGFloat = 40
        static let mapViewLocationBlobsCVIndicatorSize: CGFloat = 10
        static let mapViewLocationBlobsCVHighlightAdjustSize: CGFloat = 10
        
        static let mapViewBackgroundActivityViewSize: CGFloat = 40
        
        static let mapViewShadowOffset = CGSize(width: 0, height: 0.2)
        static let mapViewShadowOpacity: Float = 0.2
        static let mapViewShadowRadius: CGFloat = 1.0
        
        static let cardShadowOffset = CGSize(width: 0, height: 0.2)
        static let cardShadowOpacity: Float = 0.5
        static let cardShadowRadius: CGFloat = 2.0
        
        static let blobsActiveTableViewCellHeight: CGFloat = 100
        static let blobsActiveTableViewUserImageSize: CGFloat = 60
        static let blobsActiveTableViewIndicatorSize: CGFloat = 40
        static let blobsActiveTableViewContentSize: CGFloat = 90
        
        static let accountTableViewCellHeight: CGFloat = 100
        static let blobsUserTableViewIndicatorSize: CGFloat = 40
        static let blobsUserTableViewContentSize: CGFloat = 90
        
        static let blobViewUserImageSize: CGFloat = 28
        static let blobViewIndicatorSize: CGFloat = 60
        static let blobViewButtonSize: CGFloat = 40
        static let blobViewCellHeight: CGFloat = 20
        static let blobViewCommentCellHeight: CGFloat = 35
        static let blobViewCommentUserImageSize: CGFloat = 20
        
        static let blobAddTypeCircleSize: CGFloat = 40
        
        static let blobAddPeopleSearchBarHeight: CGFloat = 40
        static let blobAddPeopleTableViewCellHeight: CGFloat = 40
        
        static let peopleSearchBarHeight: CGFloat = 40
        static let peopleTableViewCellHeight: CGFloat = 80
        static let peopleTableViewUserImageSize: CGFloat = 40
        static let peopleConnectIndicatorSize: CGFloat = 30
        
        static let accountProfileBoxHeight: CGFloat = 120
        static let accountSearchBarHeight: CGFloat = 40
        static let connectionsTableViewCellHeight: CGFloat = 80
        static let accountConnectStarSize: CGFloat = 40
        
        static let tabBarHeight: CGFloat = 49
        
    }
    
    struct Strings {
        
        static let fontRegular = "Helvetica-Light"
//        static let fontRegular = "Rajdhani-Regular"
//        static let fontLight = "Rajdhani-Light"
//        static let fontBold = "Rajdhani-Bold"
//        static let fontThinRegular = "AmericanTypewriter-Condensed"
//        static let fontThinLight = "WireOne"
//        static let fontThinBold = "AmericanTypewriter-CondensedBold"
        
        static let S3BucketUserImages = "blobjot-userimages"
        static let S3BucketThumbnails = "blobjot-thumbnails"
        static let S3BucketMedia = "blobjot-media"
        
        static let peopleTableViewCellReuseIdentifier = "peopleTableViewCell"
        static let connectionsTableViewCellReuseIdentifier = "connectionsTableViewCell"
        static let locationBlobsCellReuseIdentifier = "locationBlobsCell"
        static let blobsActiveTableViewCellReuseIdentifier = "blobsActiveTableViewCell"
        static let accountTableViewCellReuseIdentifier = "accountTableViewCell"
        static let blobAddPeopleTableViewCellReuseIdentifier = "blobAddPeopleTableViewCell"
        static let blobTableViewCellBlobWithLabelReuseIdentifier = "blobTableViewCellBlobWithLabel"
        static let blobTableViewCellBlobNoLabelReuseIdentifier = "blobTableViewCellBlobNoLabel"
        static let blobTableViewCellCommentReuseIdentifier = "blobTableViewCellComment"
        
        static let cacheSessionViewHistory = "sessionViewHistory"
        
        static let iconStringDefaultProfile = "TAB_ICON_account.png"
        static let iconStringBlobjotLogo = "TAB_ICON_location_blobs.png"
        static let iconStringDefaultMedia = "defaultMedia.png"
        static let iconStringMapViewAddCombo = "MV_add_combo_icon.png"
        static let iconStringMapViewAdd = "MV_add_icon.png"
        static let iconStringMapViewCheck = "MV_check_icon.png"
        static let iconStringMapViewClose = "MV_close_icon.png"
        static let iconStringMapViewList = "MV_list_icon.png"
        static let iconStringMapViewLocation = "MV_location_icon.png"
        static let iconStringMapViewRefresh = "MV_refresh_icon.png"
        static let iconStringMapViewSearchCombo = "MV_search_combo_icon.png"
        static let iconStringMapViewSearch = "MV_search_icon.png"
        static let iconStringBlobViewAddComment = "BV_add_comment_icon.png"
        static let iconStringConnectionViewAddConnection = "CV_add_connection_icon.png"
        static let iconStringConnectionViewCheck = "CV_check_icon.png"
        static let iconStringConnectionViewPending = "CV_pending_icon.png"
        static let iconStringTabIconLocation = "TAB_ICON_location_blobs.png"
        static let iconStringTabIconConnections = "TAB_ICON_connections.png"
        static let iconStringTabIconAccount = "TAB_ICON_account.png"
        
        static let awsRegion = AWSRegionType.usEast1
//        static let awsCognitoIdentityPoolID = "us-east-1:6db4d1c8-f3f5-4466-b135-535279ff6077"
        static let awsCognitoIdentityPoolID = "us-east-1:c24cf3db-0349-4163-87ad-3572319324e7"
        
        static let stringLogOut = "Log Out"
        static let stringLMConstant = "Constant\n(High Accuracy)"
        static let stringLMSignificant = "Battery Saver\n(Low Accuracy)"
        
    }
    
    struct Settings {
        
        static let gKey = "AIzaSyBdwjW6jYuPjZP7oW8NsqHkZQyMxFq_j0w"
        static let mapStyleUrl = URL(string: "mapbox://styles/tangojlabs/ciqwaddsl0005b7m0xwctftow")
        static let maxServerTries: Int = 5
        
        static let userNameMaxLength: Int = 18
//        static let userNameDisallowedCharacterSet = NSCharacterSet(charactersIn: "!@#$%^&*()-+={}|[]\\:;\'\"<>?,/~`").inverted
        static let userNameAllowedCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_1234567890").inverted
        static let mapViewAddBlobMinZoom: Float = 18
        
        static let imageSizeUser: CGFloat = 200
        static let imageSizeThumbnail: CGFloat = 200
        static let imageSizeBlob: CGFloat = 1080
        
        static let locationDistanceFilter: Double = 100 // In meters
        static let locationAccuracyMax: Double = 100 // In meters
        static let locationAccuracyMaxBackground: Double = 200 // In meters
        static let locationAccuracyDeferredDistance: Double = 100 // In meters
        static let locationAccuracyDeferredInterval: Double = 180 // In seconds
        
        static let locationDistanceMinChange: Double = 20 // In meters
        static let locationTimeMinChange: Double = 3 // In seconds
        
        static var locationManagerConstant: Bool = true
        static var statusBarStyle: UIStatusBarStyle = UIStatusBarStyle.lightContent
        
    }
    
}
