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
    
    enum BlobType: Int
    {
        case origin = 0
        case location = 1
    }
    
    enum BlobAccount: Int
    {
        case standard = 0
        case sponsored = 1
    }
    
    enum BlobFeature: Int
    {
        case standard = 0
        case invisible = 1
    }
    
    enum BlobAccess: Int
    {
        case standard = 0
        case followers = 1
    }
    
    enum ContentType: Int
    {
        case text = 0
        case image = 1
        case video = 2
    }
    
    enum ContentActionType: Int
    {
        case view = 0
        case hide = 1
        case delete = 2
    }
    
    enum UserStatusType: Int
    {
        case standard = 0
        case following = 1
        case blocked = 2
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
    
    func blobType(_ blobTypeInt: Int) -> Constants.BlobType
    {
        // Evaluate the blobType Integer received and convert it to the appropriate BlobType
        switch blobTypeInt
        {
        case 0:
            return Constants.BlobType.origin
        case 1:
            return Constants.BlobType.location
        default:
            // Return location as default because the original BlobTypes (1-6) were all location-restricted
            return Constants.BlobType.location
        }
    }
    
    func blobFeature(_ blobFeatureInt: Int) -> Constants.BlobFeature
    {
        // Evaluate the blobFeature Integer received and convert it to the appropriate BlobFeature
        switch blobFeatureInt
        {
        case 0:
            return Constants.BlobFeature.standard
        case 1:
            return Constants.BlobFeature.invisible
        default:
            return Constants.BlobFeature.standard
        }
    }
    
    func blobAccess(_ blobAccessInt: Int) -> Constants.BlobAccess
    {
        // Evaluate the blobAccess Integer received and convert it to the appropriate BlobAccess
        switch blobAccessInt
        {
        case 0:
            return Constants.BlobAccess.standard
        case 1:
            return Constants.BlobAccess.followers
        default:
            return Constants.BlobAccess.standard
        }
    }
    
    func blobAccount(_ blobAccountInt: Int) -> Constants.BlobAccount
    {
        // Evaluate the blobAccount Integer received and convert it to the appropriate BlobAccount
        switch blobAccountInt
        {
        case 0:
            return Constants.BlobAccount.standard
        case 1:
            return Constants.BlobAccount.sponsored
        default:
            return Constants.BlobAccount.standard
        }
    }
    
    func contentType(_ contentTypeInt: Int) -> Constants.ContentType
    {
        // Evaluate the contentType Integer received and convert it to the appropriate ContentType
        switch contentTypeInt
        {
        case 0:
            return Constants.ContentType.text
        case 1:
            return Constants.ContentType.image
        case 2:
            return Constants.ContentType.video
        default:
            return Constants.ContentType.text
        }
    }
    
    func contentActionType(_ contentActionTypeInt: Int) -> Constants.ContentActionType
    {
        // Evaluate the contentActionType Integer received and convert it to the appropriate ContentActionType
        switch contentActionTypeInt
        {
        case 0:
            return Constants.ContentActionType.view
        case 1:
            return Constants.ContentActionType.hide
        case 2:
            return Constants.ContentActionType.delete
        default:
            return Constants.ContentActionType.view
        }
    }
    
    func userStatusType(_ userStatusTypeInt: Int) -> Constants.UserStatusType
    {
        // Evaluate the userStatusType Integer received and convert it to the appropriate UserStatusType
        switch userStatusTypeInt
        {
        case 0:
            return Constants.UserStatusType.standard
        case 1:
            return Constants.UserStatusType.following
        case 2:
            return Constants.UserStatusType.blocked
        default:
            return Constants.UserStatusType.standard
        }
    }
    
    // Color switches on blobType, not blobAccount due to possibility of adding a different color for different types of sponsored Blobs
    func blobColor(_ blobType: Constants.BlobType, blobFeature: Constants.BlobFeature, blobAccess: Constants.BlobAccess, blobAccount: Constants.BlobAccount, mainMap: Bool) -> UIColor
    {
        switch blobType
        {
        case .origin:
            if blobAccount == Constants.BlobAccount.sponsored
            {
                if blobAccess == Constants.BlobAccess.followers
                {
                    return Constants.Colors.blobBlue
                }
                else
                {
                    return Constants.Colors.blobBlueLight
                }
            }
            else
            {
                if blobAccess == Constants.BlobAccess.followers
                {
                    return Constants.Colors.blobPurple
                }
                else
                {
                    return Constants.Colors.blobPurpleLight
                }
            }
        case .location:
            if blobAccount == Constants.BlobAccount.sponsored
            {
                if blobAccess == Constants.BlobAccess.followers
                {
                    return Constants.Colors.blobBlue
                }
                else
                {
                    return Constants.Colors.blobBlueLight
                }
            }
            else if blobFeature == Constants.BlobFeature.invisible && mainMap
            {
                return Constants.Colors.blobInvisible
            }
            else if blobFeature == Constants.BlobFeature.invisible
            {
                if blobAccess == Constants.BlobAccess.followers
                {
                    return Constants.Colors.blobGray
                }
                else
                {
                    return Constants.Colors.blobGrayLight
                }
            }
            else
            {
                if blobAccess == Constants.BlobAccess.followers
                {
                    return Constants.Colors.blobYellow
                }
                else
                {
                    return Constants.Colors.blobYellowLight
                }
            }
        }
    }
    
    func blobColorOpaque(_ blobType: Constants.BlobType, blobFeature: Constants.BlobFeature, blobAccess: Constants.BlobAccess, blobAccount: Constants.BlobAccount, mainMap: Bool) -> UIColor
    {
        switch blobType
        {
        case .origin:
            if blobAccount == Constants.BlobAccount.sponsored
            {
                return Constants.Colors.blobBlueOpaque
            }
            else
            {
                return Constants.Colors.blobPurpleOpaque
            }
        case .location:
            if blobAccount == Constants.BlobAccount.sponsored
            {
                return Constants.Colors.blobBlueOpaque
            }
            else if blobFeature == Constants.BlobFeature.invisible && mainMap
            {
                return Constants.Colors.blobInvisible
            }
            else if blobFeature == Constants.BlobFeature.invisible
            {
                return Constants.Colors.blobGrayOpaque
            }
            else
            {
                return Constants.Colors.blobYellowOpaque
            }
        }
    }
    
    struct Colors
    {
        static let standardBackground = UIColor.white
        static let standardBackgroundTransparent = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8) //#FFF
        static let standardBackgroundGray = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 1.0) //#686868
        static let standardBackgroundGrayTransparent = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 0.3) //#686868
        static let standardBackgroundGrayUltraLight = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
        static let standardBackgroundGrayUltraLightTransparent = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 0.3) //#F2F2F2
//        static let colorStatusBar = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
//        static let colorTopBar = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1.0) //#404040
//        static let colorStatusBar = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
//        static let colorTopBar = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
        static let colorStatusBar = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorStatusBarLight = UIColor(red: 187/255, green: 172/255, blue: 210/255, alpha: 1.0) //#BBACD2
        static let colorTopBar = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorBorderGrayLight = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0) //#CCC
//        static let colorTextNavBar = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0) //#333333
        static let colorTextNavBar = UIColor.white
        static let colorGrayLight = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0) //#CCC
        static let colorGrayDark = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
        
        static let colorFacebookDarkBlue = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1.0) //#3B5998
        
        static let colorTextStandard = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3) //#000000
        static let colorTextRed = UIColor(red: 242/255, green: 105/255, blue: 99/255, alpha: 1.0) //#F26963
        static let colorTextGray = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
        static let colorTextGrayMedium = UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0) //#8C8C8C
        static let colorTextGrayLight = UIColor(red: 154/255, green: 154/255, blue: 154/255, alpha: 1.0) //#999999
        static let colorTextGrayUltraLight = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
        static let colorTextWhite = UIColor.white
        
        static let colorUsernameAvailable = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorUsernameNotAvailable = UIColor(red: 242/255, green: 105/255, blue: 99/255, alpha: 1.0) //#F26963
        
        static let blobInvisible = UIColor.clear
        static let blobGrayLight = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2) //#000000
        static let blobGray = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4) //#000000
        static let blobGrayOpaque = UIColor(red: 154/255, green: 154/255, blue: 154/255, alpha: 1.0) //#999999
        static let blobYellowLight = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 0.2) //#FCB249
        static let blobYellow = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 0.4) //#FCB249
        static let blobYellowMinorTransparent = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 0.7) //#FCB249
        static let blobYellowOpaque = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 1.0) //#FCB249
        static let blobYellowDark = UIColor(red: 201/255, green: 118/255, blue: 3/255, alpha: 1.0) //#C97603
        static let blobPurpleLight = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 0.2) //#8A70B2
        static let blobPurple = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 0.4) //#8A70B2
        static let blobPurpleMinorTransparent = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 0.7) //#8A70B2
        static let blobPurpleOpaque = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let blobPurpleDark = UIColor(red: 96/255, green: 71/255, blue: 133/255, alpha: 1.0) //#604785
        static let blobBlueLight = UIColor(red: 0/255, green: 153/255, blue: 255/255, alpha: 0.2) //#0099FF
        static let blobBlue = UIColor(red: 0/255, green: 153/255, blue: 255/255, alpha: 0.4) //#0099FF
        static let blobBlueOpaque = UIColor(red: 0/255, green: 153/255, blue: 255/255, alpha: 1.0) //#0099FF
        static let blobHighlight = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 1.0) //#686868
        
        static let colorPurple = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorPurpleTransparent = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 0.3) //#8A70B2
        static let colorPurpleLight = UIColor(red: 215/255, green: 206/255, blue: 228/255, alpha: 1.0) //#D7CEE4
        static let colorPurpleDark = UIColor(red: 84/255, green: 62/255, blue: 116/255, alpha: 1.0) //#543E74
        
        static let colorBlue = UIColor(red: 0/255, green: 153/255, blue: 255/255, alpha: 1.0) //#0099FF
        static let colorBlueLight = UIColor(red: 102/255, green: 194/255, blue: 255/255, alpha: 1.0) //#66C2FF
        static let colorBlueExtraLight = UIColor(red: 153/255, green: 214/255, blue: 255/255, alpha: 1.0) //#99D6FF
        
        static let colorRed = UIColor(red: 242/255, green: 105/255, blue: 99/255, alpha: 0.4) //#F26963
        static let colorRedOpaque = UIColor(red: 242/255, green: 105/255, blue: 99/255, alpha: 1.0) //#F26963
        
        static let colorPink = UIColor(red: 255/255, green: 0/255, blue: 102/255, alpha: 1.0) //#FF0066
        
        static let colorStarSelected = UIColor.yellow
        static let colorStarLarge = UIColor.lightGray.withAlphaComponent(0.9)
        
        static let colorBlobAddPeopleSearchBar = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorPeopleSearchBar = UIColor.gray
        
        static let colorPreviewTextNormal = UIColor.black
        static let colorPreviewTextError = UIColor.red
        
        static let colorMapViewButton = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
    }
    
    struct Data
    {
        static var badgeNumber = 0
        static var attemptedLogin: Bool = false
        static var serverTries: Int = 0 // Used to prevent looping through failed requests
        static var serverLastRefresh: TimeInterval = Date().timeIntervalSince1970 // Used to prevent looping through failed requests in a short period of time
        static var lastCredentials: TimeInterval = Date().timeIntervalSince1970
        static var stillSendingBlob: Bool = false
        
        static var currentUser = User()
//        static var currentUserLikes = [String]()
        static var currentUserInterests = [Interest]()
//        static var currentUserName: String?
//        static var currentUserImage: UIImage?
        
        // Long-term global storage lists
        static var allBlobs = [Blob]()
        static var mapBlobIDs = [String]()
        static var blobContent = [BlobContent]()
        static var userBlobContentIDs = [String]()
        
        // Short-term global storage lists
        static var locationBlobContent = [BlobContent]()
        static var previewBlobContent = [BlobContent]()
        static var previewCurrentIndex: Int?
        
        static var defaultBlob = Blob(blobID: "default", blobDatetime: Date(), blobLat: 0.0, blobLong: 0.0, blobRadius: 0.0, blobType: Constants.BlobType.origin, blobAccount: Constants.BlobAccount.standard, blobFeature: Constants.BlobFeature.standard, blobAccess: Constants.BlobAccess.standard)
        static var defaultBlobContent = BlobContent(blobContentID: "default", blobID: defaultBlob.blobID, userID: "default", contentDatetime: Date(), contentType: Constants.ContentType.text, response: false, contentText: "Check out Blobjot.com!", contentMediaID: nil, contentThumbnailID: nil, respondingToContentID: nil)
        
        static var mapCircles = [GMSCircle]()
//        static var thumbnailObjects = [ThumbnailObject]()
        static var userObjects = [User]()
        static var userPublicArea = User(facebookID: "blobjotBlob", userID: "blobjotBlob", userName: "Public Area", userImage: UIImage(named: Constants.Strings.iconStringBlobjotLogo))
    }
    
    struct Dim
    {
        static let statusBarStandardHeight: CGFloat = 20
        
        static let mapViewButtonSize: CGFloat = 40
        static let mapViewButtonAddSize: CGFloat = 40
        static let mapViewButtonSearchSize: CGFloat = 40
        static let mapViewButtonListSize: CGFloat = 40
        static let mapViewButtonAccountSize: CGFloat = 40
        static let mapViewButtonTrackUserSize: CGFloat = 40
        
        static let mapViewMenuWidth: CGFloat = 200
        
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
        
        static let cardShadowOffset = CGSize(width: 0, height: 0.1) // CGSize(width: 0, height: 0.2)
        static let cardShadowOpacity: Float = 0.5 // 0.5
        static let cardShadowRadius: CGFloat = 1.0 // 2.0
        
        static let blobsActiveTableViewCellHeight: CGFloat = 100
        static let blobsActiveTableViewUserImageSize: CGFloat = 60
        static let blobsActiveTableViewIndicatorSize: CGFloat = 40
        static let blobsActiveTableViewContentSize: CGFloat = 90
        
        static let blobsTableViewCellHeight: CGFloat = 100
        static let blobsTableViewUserImageSize: CGFloat = 60
        static let blobsTableViewIndicatorSize: CGFloat = 40
        static let blobsTableViewContentSize: CGFloat = 90
        
        static let accountTableViewCellHeight: CGFloat = 100
        static let blobsUserTableViewIndicatorSize: CGFloat = 40
        static let blobsUserTableViewContentSize: CGFloat = 90
        
        static let blobViewUserImageSize: CGFloat = 28
        static let blobViewIndicatorSize: CGFloat = 60
        static let blobViewButtonSize: CGFloat = 40
        static let blobViewCellHeight: CGFloat = 20
        static let blobViewContentCellHeight: CGFloat = 35
        static let blobViewContentUserImageSize: CGFloat = 20
        
        static let blobViewTypeIndicatorWidth: CGFloat = 5
        
        static let blobAddTypeCircleSize: CGFloat = 40
        
        static let blobAddPeopleSearchBarHeight: CGFloat = 40
        static let blobAddPeopleTableViewCellHeight: CGFloat = 40
        
        static let peopleSearchBarHeight: CGFloat = 40
        static let peopleTableViewCellHeight: CGFloat = 80
        static let peopleTableViewUserImageSize: CGFloat = 40
        static let peopleTableViewFBImageSize: CGFloat = 20
        static let peopleConnectIndicatorSize: CGFloat = 30
        
        static let accountProfileBoxHeight: CGFloat = 120
        static let accountSearchBarHeight: CGFloat = 40
        static let accountConnectStarSize: CGFloat = 40
        
        static let tabBarHeight: CGFloat = 49
    }
    
    struct Strings
    {
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
        
        static let mapViewMessageDefaultBlob = "Blobs at your location will appear in this list."
        static let mapViewMessageOutOfRange = "This Blob is not in range.  Travel within the perimeter of the Blob to see all of the content!"
        static let mapViewLabelOutOfRange = "Out of Range"
        
        static let addBlobSelectorTypeBoxOrigin = "Blob is viewable from anywhere."
        static let addBlobSelectorTypeBoxLocation = "Blob is viewable at Blob location."
        
        static let previewBlobsCellReuseIdentifier = "selectionBlobsCell"
        static let peopleTableViewCellReuseIdentifier = "peopleTableViewCell"
        static let locationBlobsCellReuseIdentifier = "locationBlobsCell"
        static let blobsActiveTableViewCellReuseIdentifier = "blobsActiveTableViewCell"
        static let blobsTableViewCellReuseIdentifier = "blobsTableViewCell"
        static let accountTableViewCellReuseIdentifier = "accountTableViewCell"
        static let blobAddPeopleTableViewCellReuseIdentifier = "blobAddPeopleTableViewCell"
        static let blobTableViewCellReuseIdentifier = "blobTableViewCell"
        
        static let cacheSessionViewHistory = "sessionViewHistory"
        
        static let iconStringDefaultProfile = "PROFILE_DEFAULT.png"
        static let iconStringBlobjotLogo = "BLOBJOT_purple.png"
        static let iconStringDefaultMedia = "defaultMedia.png"
        static let iconStringMapViewAddCombo = "MV_add_combo_icon.png"
        static let iconStringBlobAdd = "add_icon.png"
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
        static let iconStringTabIconActiveBlobsGray = "TAB_ICON_active_blobs_gray.png"
        static let iconStringTabIconActiveBlobsWhite = "TAB_ICON_active_blobs_white.png"
        static let iconStringTabIconConnectionsGray = "TAB_ICON_connections_gray.png"
        static let iconStringTabIconConnectionsWhite = "TAB_ICON_connections_white.png"
        static let iconStringTabIconAccountGray = "TAB_ICON_account_gray.png"
        static let iconStringTabIconAccountWhite = "TAB_ICON_account_white.png"
        
        static let awsRegion = AWSRegionType.usEast1
        static let awsCognitoIdentityPoolID = "us-east-1:c24cf3db-0349-4163-87ad-3572319324e7"
        
        static let stringLogOut = "Log Out"
        static let stringLMAlways = "Constant Tracking\n(High Accuracy)"
        static let stringLMSignificant = "Battery Saver\n(Low Accuracy)"
        static let stringLMOff = "Background Location\nTracking OFF"
    }
    
    struct Settings
    {
        static let gKey = "AIzaSyBdwjW6jYuPjZP7oW8NsqHkZQyMxFq_j0w"
        static let mapStyleUrl = URL(string: "mapbox://styles/tangojlabs/ciqwaddsl0005b7m0xwctftow")
        static let maxServerTries: Int = 5
        static let maxServerTryRefreshTime: Double = 5000 // In milliseconds
        static let maxUserObjectSaveWithoutUse: Double = 43200000 // 12 Hours // In milliseconds
        static let maxBlobObjectSaveWithoutUse: Double = 0 // 43200000 // 12 Hours // In milliseconds
        static let maxBlobContentObjectSaveWithoutUse: Double = 0 // 43200000 // 12 Hours // In milliseconds
        
        static let mapViewDefaultLat: CLLocationDegrees = 29.758624
        static let mapViewDefaultLong: CLLocationDegrees = -95.366795
        static let mapViewDefaultZoom: Float = 10
        static let mapViewAngledZoom: Float = 16
        static let mapViewAngledDegrees: Double = 60.0
        
//        static let addBlobDefaultOriginMaxDistance: Double = 
        
        static let userNameMaxLength: Int = 18
//        static let userNameDisallowedCharacterSet = NSCharacterSet(charactersIn: "!@#$%^&*()-+={}|[]\\:;\'\"<>?,/~`").inverted
        static let userNameAllowedCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_1234567890").inverted
        static let mapViewAddBlobMinZoom: Float = 18
        
        static let imageSizeUser: CGFloat = 200
        static let imageSizeThumbnail: CGFloat = 200
        static let imageSizeBlob: CGFloat = 720 // 1080
        
        static let locationDistanceFilter: Double = 100 // In meters
        static let locationAccuracyMax: Double = 100 // In meters
        static let locationAccuracyMaxBackground: Double = 200 // In meters
        static let locationAccuracyDeferredDistance: Double = 100 // In meters
        static let locationAccuracyDeferredInterval: Double = 180 // In seconds
        
        static let locationDistanceMinChange: Double = 20 // In meters
        static let locationDistanceUpdateBlobjotBlobs: Double = 2000 // In meters
        static let locationTimeMinChange: Double = 3 // In seconds
        
        static var locationManagerSetting: LocationManagerSettingType = Constants.LocationManagerSettingType.significant
        static var statusBarStyle: UIStatusBarStyle = UIStatusBarStyle.lightContent
    }
    
    enum LocationManagerSettingType: String
    {
        case always = "always"
        case significant = "significant"
        case off = "off"
    }
    
    func blobTypes(_ locationManagerSettingTypeString: String) -> Constants.LocationManagerSettingType
    {
        // Evaluate the LocationManagerSetting String received and convert it to the appropriate LocationManagerSetting Type
        switch locationManagerSettingTypeString
        {
        case "always":
            return Constants.LocationManagerSettingType.always
        case "significant":
            return Constants.LocationManagerSettingType.significant
        case "off":
            return Constants.LocationManagerSettingType.off
        default:
            return Constants.LocationManagerSettingType.significant
        }
    }
    
}
