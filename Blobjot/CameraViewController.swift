//
//  CameraViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 2/4/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import AVFoundation
import GoogleMaps
import MapKit
import MobileCoreServices
import UIKit


protocol CameraViewControllerDelegate
{
    func triggerLoadingScreenOn(screenOn: Bool)
}

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, MKMapViewDelegate
{
    var cameraDelegate: CameraViewControllerDelegate?
    
    // MARK: PROPERTIES
    
    var loadingScreen: UIView!
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCaptureStillImageOutput?
    var captureDeviceInput: AVCaptureDeviceInput!
    var captureDevice: AVCaptureDevice!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var imageRingView: UIView!
    
    var actionButton: UIView!
    var actionButtonLabel: UILabel!
    var actionButtonTapView: UIView!
    
    var switchCameraView: UIView!
    var switchCameraLabel: UILabel!
    var switchCameraTapView: UIView!
    
    var mapViewSize: CGFloat = 100 //Constants.Dim.recordResponseEdgeSize
    
    var screenSize: CGRect!
    var viewContainer: UIView!
    var cameraView: UIView!
    var mapViewContainer: UIView!
    var mapView: MKMapView!
//    var mapViewTapView1: UIView!
//    var mapViewTapView2: UIView!
//    var mapViewTapView3: UIView!
    
    // The Google Maps Coordinate Object for the current center of the map and the default Camera
    var mapCenter: CLLocationCoordinate2D!
    var defaultCamera: GMSCameraPosition!
    
    var imageViewArray = [UIView]()
    var imageTimestamps = [Double]()
    var imageArray = [UIImage]()
    var imageSelected = [Int]()
    
    var useBackCamera = true
    var baseBlobID: String?
    var privateVideo = false
    
    let imageRingDiameter: CGFloat = 300
    
    
    // MARK: INITIALIZING
    
    // Do any additional setup after loading the view.
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        UIApplication.shared.isStatusBarHidden = true
        if self.navigationController != nil
        {
            self.navigationController!.isNavigationBarHidden = true
        }
        
        // Calculate the screenSize
        screenSize = UIScreen.main.bounds
        print("CVC - SCREEN SIZE: \(screenSize)")
        print("CVC - VIEW SIZE: \(self.view.frame)")
        
        // Add the loading screen, leaving NO room for the status bar at the top
        loadingScreen = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        loadingScreen.backgroundColor = UIColor.darkGray.withAlphaComponent(1.0)
        self.view.addSubview(loadingScreen)
        
        previewLayer = AVCaptureVideoPreviewLayer(layer: self.view.layer)
        
        viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        viewContainer.backgroundColor = UIColor.black
        viewContainer.clipsToBounds = false
        self.view.addSubview(viewContainer)
        
        // The cameraView should be square, but centered and filling the viewContainer, so offset the left side off the screen to compensate
        let leftOffset = (screenSize.height - screenSize.width) / 4
        cameraView = UIView(frame: CGRect(x: 0 - leftOffset, y: 0, width: screenSize.height, height: screenSize.height))
        cameraView.backgroundColor = UIColor.black
        cameraView.clipsToBounds = false
        viewContainer.addSubview(cameraView)
        print("CAMERA VIEW FRAME: \(cameraView.frame)")
        
        mapViewContainer = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (mapViewSize / 2), y: viewContainer.frame.height - 5 - mapViewSize, width: mapViewSize, height: mapViewSize))
        mapViewContainer.backgroundColor = UIColor.clear
        mapViewContainer.layer.cornerRadius = mapViewSize / 2
        mapViewContainer.clipsToBounds = true
        viewContainer.addSubview(mapViewContainer)
        
//        let mapMask = CAShapeLayer()
//        mapMask.frame = mapViewContainer.bounds
//        let mapMaskPath = CGMutablePath()
//        mapMaskPath.move(to: CGPoint(x: mapViewSize, y: mapViewSize))
//        mapMaskPath.addArc(center: CGPoint(x: mapViewSize, y: mapViewSize), radius: mapViewSize, startAngle: CGFloat(270.degreesToRadians), endAngle: CGFloat(180.degreesToRadians), clockwise: true)
////        mapMaskPath.addLine(to: CGPoint(x: mapViewSize, y: mapViewSize))
////        mapMaskPath.addLine(to: CGPoint(x: 0, y: mapViewSize))
////        mapMaskPath.addLine(to: CGPoint(x: mapViewSize, y: 0))
//        mapMask.path = mapMaskPath
//        mapViewContainer.layer.mask = mapMask
        
        let initialLocation = CLLocation(latitude: Constants.Settings.mapViewDefaultLat, longitude: Constants.Settings.mapViewDefaultLong)
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: mapViewSize, height: mapViewSize))
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.showsPointsOfInterest = false
        mapView.isUserInteractionEnabled = false
        
        mapViewContainer.addSubview(mapView)
        print("CVC - MV SET 1: TRACKING MODE: \(mapView.userTrackingMode.rawValue)")
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        print("CVC - MV SET 2: TRACKING MODE: \(mapView.userTrackingMode.rawValue)")
        
        for subview in mapView.subviews
        {
            print("CVC - MAP SUBVIEW: \(subview.description)")
        }
        
//        mapViewTapView1 = UIView(frame: CGRect(x: mapViewSize / 2, y: mapViewSize / 2, width: mapViewSize / 2, height: mapViewSize / 2))
//        mapViewContainer.addSubview(mapViewTapView1)
//        mapViewTapView2 = UIView(frame: CGRect(x: mapViewSize * (3/4), y: mapViewSize / 4, width: mapViewSize / 4, height: mapViewSize / 4))
//        mapViewContainer.addSubview(mapViewTapView2)
//        mapViewTapView3 = UIView(frame: CGRect(x: mapViewSize / 4, y: mapViewSize * (3/4), width: mapViewSize / 4, height: mapViewSize / 4))
//        mapViewContainer.addSubview(mapViewTapView3)
        
        // Add the Text Button and overlaid Tap View for more tap coverage
        let actionButtonSize: CGFloat = 40
        actionButton = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (actionButtonSize / 2), y: (viewContainer.frame.height / 2) - (actionButtonSize / 2), width: actionButtonSize, height: actionButtonSize))
        actionButton.layer.cornerRadius = 20
        actionButton.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        actionButton.isHidden = true
        viewContainer.addSubview(actionButton)
        
        actionButtonLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        actionButtonLabel.backgroundColor = UIColor.clear
        actionButtonLabel.text = "\u{2713}" //"\u{1F5D1}"
        actionButtonLabel.textAlignment = .center
        actionButtonLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        actionButton.addSubview(actionButtonLabel)
        
        actionButtonTapView = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - ((actionButtonSize + 20) / 2), y: (viewContainer.frame.height / 2) - ((actionButtonSize + 20) / 2), width: actionButtonSize + 20, height: actionButtonSize + 20))
        actionButtonTapView.layer.cornerRadius = (actionButtonSize + 20) / 2
        actionButtonTapView.backgroundColor = UIColor.clear
        viewContainer.addSubview(actionButtonTapView)
        
        
        // Add the Switch Camera Button and overlaid Tap View for more tap coverage
        switchCameraView = UIView(frame: CGRect(x: 20, y: viewContainer.frame.height - 60, width: 40, height: 40))
        switchCameraView.layer.cornerRadius = 20
        switchCameraView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        viewContainer.addSubview(switchCameraView)
        
        switchCameraLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        switchCameraLabel.backgroundColor = UIColor.clear
        switchCameraLabel.text = "\u{21ba}"
        switchCameraLabel.textAlignment = .center
        switchCameraLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        switchCameraView.addSubview(switchCameraLabel)
        
        switchCameraTapView = UIView(frame: CGRect(x: 10, y: viewContainer.frame.height - 70, width: 60, height: 60))
        switchCameraTapView.layer.cornerRadius = 30
        switchCameraTapView.backgroundColor = UIColor.clear
        viewContainer.addSubview(switchCameraTapView)
        
        // Add the overall circle for the ring view
        print("CVC - VC FRAME WIDTH: \(viewContainer.frame.width)")
        print("CVC - VC FRAME HEIGHT: \(viewContainer.frame.height)")
        imageRingView = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (imageRingDiameter / 2), y: (viewContainer.frame.height / 2) - (imageRingDiameter / 2), width: imageRingDiameter, height: imageRingDiameter))
        imageRingView.layer.cornerRadius = imageRingDiameter / 2
        imageRingView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        imageRingView.isHidden = true
        viewContainer.addSubview(imageRingView)
        
        // Add the path and mask to only show the outer ring
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: imageRingDiameter / 2, y: imageRingDiameter / 2), radius: (imageRingDiameter / 2) - Constants.Dim.cameraViewImageCellSize, startAngle: 0.0, endAngle: 2 * 3.14, clockwise: false)
        path.addRect(CGRect(x: 0, y: 0, width: imageRingDiameter, height: imageRingDiameter))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillRule = kCAFillRuleEvenOdd
        imageRingView.layer.mask = maskLayer
        imageRingView.clipsToBounds = true
        
        print("CAMERA VIEW: HIDE LOADING SCREEN")
        self.view.sendSubview(toBack: self.loadingScreen)
//        clearTmpDirectory()
    }
    
    // Perform setup before the view loads
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(true)
        
//        prepareSessionUseBackCamera(useBackCamera: true)
    }
    
    // These will occur after viewDidLoad
    override func viewDidAppear(_ animated: Bool)
    {
        let attributionLabel: UIView = mapView.subviews[1]
        let labelWidth = attributionLabel.frame.width
        attributionLabel.frame = CGRect(x: (mapViewContainer.frame.width / 2) - (labelWidth / 2), y: attributionLabel.frame.minY, width: labelWidth, height: attributionLabel.frame.height)
        
        prepareSessionUseBackCamera(useBackCamera: true)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: GESTURE METHODS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first
        {
            // Find which image the tap was inside
            var imageSelectedIndicator: Bool = false
            for (viewIndex, imageView) in imageViewArray.enumerated()
            {
                if imageView.frame.contains(touch.location(in: imageRingView))
                {
                    print("CVC - IMAGEVIEW: \(imageView) CONTAINS SELECTION")
                    imageSelectedIndicator = true
                    
                    // Check whether the image has already been selected
                    var alreadySelected = false
                    for (i, sIndex) in imageSelected.enumerated()
                    {
                        if sIndex == viewIndex
                        {
                            print("CVC - IMAGEVIEW CHECK 1")
                            alreadySelected = true
                            
                            // The image was selected for a second time, so de-select the image
                            imageSelected.remove(at: i)
                        }
                    }
                    print("CVC - IMAGEVIEW CHECK 2")
                    if !alreadySelected
                    {
                        imageSelected.append(viewIndex)
                    }
                    print("CVC - imageSelected COUNT 1: \(imageSelected.count)")
                }
            }
            
            // If at least one image has been selected, show the delete icon
            if imageSelected.count > 0
            {
                // An image was selected, so change the action button to the delete button
                actionButtonLabel.text = "\u{1F5D1}"
            }
            else
            {
                // No images are selected, so change the action button to the upload button
                actionButtonLabel.text = "\u{2713}"
            }
            
//            print("CVC - SWITCH BUTTON TAP: \(switchCameraTapView.frame.contains(touch.location(in: viewContainer)))")
//            print("CVC - SWITCH BUTTON TAP LOCATION: \(touch.location(in: viewContainer))")
//            print("CVC - SWITCH BUTTON FRAME: \(switchCameraTapView.frame)")
//            if mapViewTapView1.frame.contains(touch.location(in: mapViewContainer)) || mapViewTapView2.frame.contains(touch.location(in: mapViewContainer)) || mapViewTapView3.frame.contains(touch.location(in: mapViewContainer))
//            {
//                print("CVC - TOUCHED MAP")
//                mapTap()
//            }
            if mapViewContainer.frame.contains(touch.location(in: viewContainer))
            {
                print("CVC - TOUCHED MAP")
                mapViewContainer.backgroundColor = Constants.Colors.recordButtonColorRecord
                captureImage()
            }
            else if switchCameraTapView.frame.contains(touch.location(in: viewContainer))
            {
                print("TOUCHED SWITCH CAMERA BUTTON")
                switchCamera()
            }
            else if actionButtonTapView.frame.contains(touch.location(in: viewContainer))
            {
                print("TOUCHED ACTION BUTTON")
                
                // If images are selected, the delete button is showing, so delete the selected images
                // Otherwise upload the images
                if imageSelected.count > 0
                {
                    deleteImages()
                }
                else
                {
                    // Upload the images
                }
            }
//            else if cameraView.frame.contains(touch.location(in: viewContainer)) && !imageSelectedIndicator
//            {
//                print("TOUCHED CAMERA")
//                captureImage()
//            }
            else if imageSelectedIndicator
            {
                // An image was selected, so highlight the image
                self.refreshImageRing()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first
        {
//            if mapViewTapView1.frame.contains(touch.location(in: mapViewContainer)) || mapViewTapView2.frame.contains(touch.location(in: mapViewContainer)) || mapViewTapView3.frame.contains(touch.location(in: mapViewContainer))
//            {
//                print("MAP TOUCH ENDED")
//            }
            if mapViewContainer.frame.contains(touch.location(in: viewContainer))
            {
                print("MAP TOUCH ENDED")
                mapViewContainer.backgroundColor = UIColor.clear
            }
            else if switchCameraTapView.frame.contains(touch.location(in: viewContainer))
            {
                print("SWITCH CAMERA BUTTON TOUCH ENDED")
            }
            else if actionButtonTapView.frame.contains(touch.location(in: viewContainer))
            {
                print("ACTION BUTTON TOUCH ENDED")
            }
//            else if cameraView.frame.contains(touch.location(in: viewContainer))
//            {
//                print("CAMERA TOUCH ENDED")
//            }
        }
    }
    
    
    // MARK: MKMAPVIEW DELEGATE METHODS
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
//        print("CVC - MV UPDATE 1: TRACKING MODE: \(mapView.userTrackingMode.rawValue)")
//        print("CVC - MV UPDATE: HEADING: \(userLocation.heading)")
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
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
    
    // Populate the Image Ring
    func refreshImageRing()
    {
        // Clear the imageRing and the imageViewArray
        imageRingView.subviews.forEach({ $0.removeFromSuperview() })
        imageViewArray = [UIView]()
        
        print("CVC - IMAGE ARRAY COUNT: \(imageArray.count)")
        if imageArray.count > 0
        {
            imageRingView.isHidden = false
            actionButton.isHidden = false
            
            let cellSize: CGFloat = Constants.Dim.cameraViewImageCellSize
            let imageSize: CGFloat = Constants.Dim.cameraViewImageSize
            let imageCellGap: CGFloat = (cellSize - imageSize) / 2
            
            // Add the imageviews to the ring view
            for index in 1...imageArray.count
            {
                let imageViewBase: CGPoint = basepointForCircleOfCircles(index, mainCircleRadius: imageRingDiameter / 2, radius: cellSize / 2, distance: (imageRingDiameter / 2) - (cellSize / 2)) // - (imageCellGap / 2))
                let cellContainer = UIView(frame: CGRect(x: imageViewBase.x, y: imageViewBase.y, width: cellSize, height: cellSize))
                cellContainer.layer.cornerRadius = cellSize / 2
                cellContainer.clipsToBounds = true
                
                let imageContainer = UIView(frame: CGRect(x: imageCellGap, y: imageCellGap, width: imageSize, height: imageSize))
                imageContainer.layer.cornerRadius = imageSize / 2
                imageContainer.clipsToBounds = true
                imageContainer.backgroundColor = UIColor.white
                cellContainer.addSubview(imageContainer)
                
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
                imageView.image = imageArray[index - 1]
                imageContainer.addSubview(imageView)
                
                imageRingView.addSubview(cellContainer)
                imageViewArray.append(cellContainer)
                print("CVC - IMAGE ARRAY INDEX: \(index)")
                print("CVC - imageSelected COUNT 2: \(imageSelected.count)")
                // If the index is stored in the imageSelect array, it has been selected, so highlight the image
                for sIndex in imageSelected
                {
                    print("CVC - IMAGE SELECT ARRAY INDEX: \(sIndex)")
                    if sIndex == index - 1
                    {
                        cellContainer.backgroundColor = UIColor.red.withAlphaComponent(0.3)
                    }
                }
            }
        }
        else
        {
            imageRingView.isHidden = true
            actionButton.isHidden = true
        }
    }
    
    // Called when the map is tapped
    func mapTap()
    {
        print("CVC - VIEW MAP VC")
        
//        // Create a back button and title for the Nav Bar
//        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
//                                             style: UIBarButtonItemStyle.plain,
//                                             target: self,
//                                             action: #selector(CameraViewController.popViewController(_:)))
//        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
//        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
//        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
//        ncTitleText.text = "Caption"
//        ncTitleText.font = UIFont(name: Constants.Strings.fontRegular, size: 14)
//        ncTitleText.textColor = Constants.Colors.colorTextNavBar
//        ncTitleText.textAlignment = .center
//        ncTitle.addSubview(ncTitleText)
        
        // Instantiate the TextViewController and pass the Images to the VC
        let mapVC = MapViewController()
        
//        // Assign the created Nav Bar settings to the Tab Bar Controller
//        mapVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
//        mapVC.navigationItem.titleView = ncTitle
        
        self.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        self.present(mapVC, animated: true, completion: nil)
//        if let navController = self.navigationController
//        {
//            navController.pushViewController(mapVC, animated: true)
//        }
        
        // Save an action in Core Data
        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
    func triggerCloseCameraView()
    {
        print("TRIGGER CLOSE -> BACK TO VIEW CONTROLLER")
        self.presentingViewController!.dismiss(animated: true, completion:
            {
            print("PARENT VC: \(self.cameraDelegate)")
            if let parentVC = self.cameraDelegate
            {
                print("TRY TO CVC HIDE LOADING SCREEN")
                parentVC.triggerLoadingScreenOn(screenOn: false)
            }
        })
    }
    
    // Called when the action button is pressed with images selected.  Deletes the selected images from the image array
    func deleteImages()
    {
        // Sort the array and then reverse the order so that the latest indexes are removed first
        imageSelected.sort()
        imageSelected.reverse()
        
        for imageIndex in imageSelected
        {
            for (index, _) in imageArray.enumerated()
            {
                if index == imageIndex
                {
                    imageArray.remove(at: index)
                    print("CVC - REMOVED IMAGE AT INDEX: \(index)")
                }
            }
        }
        
        // Reset the imageSelected array, hide the delete button, and refresh the collection view
        imageSelected = [Int]()
        actionButtonLabel.text = "\u{2713}"
        if imageArray.count == 0
        {
            actionButton.isHidden = true
        }
        refreshImageRing()
    }
    
    
    // MARK: CAMERA FUNCTIONS
    
    func prepareSessionUseBackCamera(useBackCamera: Bool)
    {
        print("IN PREPARE SESSION")
        self.useBackCamera = useBackCamera
        
        if let devices = AVCaptureDevice.devices()
        {
            for device in devices
            {
                if ((device as AnyObject).hasMediaType(AVMediaTypeVideo))
                {
                    if (useBackCamera && (device as AnyObject).position == AVCaptureDevicePosition.back)
                    {
                        captureDevice = device as? AVCaptureDevice
                        beginSession()
                    }
                    else if (!useBackCamera && (device as AnyObject).position == AVCaptureDevicePosition.front)
                    {
                        captureDevice = device as? AVCaptureDevice
                        beginSession()
                    }
                }
            }
        }
    }
    
    func beginSession()
    {
        if captureDevice != nil
        {
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
            
            if let currentInputs = captureSession.inputs
            {
                for inputIndex in currentInputs
                {
                    captureSession.removeInput(inputIndex as! AVCaptureInput)
                }
            }
            
            let err : NSError? = nil
            do
            {
                captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(captureDeviceInput)
            }
            catch _
            {
                print("error: \(err?.localizedDescription)")
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill // CHANGE THIS
            self.cameraView.layer.addSublayer(previewLayer)
            previewLayer?.frame = self.cameraView.layer.frame
            print("CAMERA VIEW LAYER FRAME: \(self.cameraView.layer.frame)")
            print("PREVIEW LAYER FRAME: \(previewLayer?.frame)")
            
            stillImageOutput = AVCaptureStillImageOutput()
            captureSession.addOutput(stillImageOutput)
            if let orientationInt = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)
            {
                print("ASSIGNING ORIENTATION 1: \(UIDevice.current.orientation.hashValue)")
                if stillImageOutput != nil
                {
                    stillImageOutput!.connection(withMediaType: AVMediaTypeVideo).videoOrientation = orientationInt
                }
            }
            
            captureSession.startRunning()
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!)
    {
        print("Capture Delegate: Did START Recording to Output File")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!)
    {
        print("Capture Delegate: Did FINISH Recording to Output File")
    }
    
    func switchCamera()
    {
        if self.useBackCamera
        {
            self.useBackCamera = false
        }
        else
        {
            self.useBackCamera = true
        }
        
        if let devices = AVCaptureDevice.devices()
        {
            for device in devices
            {
                if ((device as AnyObject).hasMediaType(AVMediaTypeVideo))
                {
                    if let currentInputs = captureSession.inputs
                    {
                        for inputIndex in currentInputs
                        {
                            captureSession.removeInput(inputIndex as! AVCaptureInput)
                        }
                    }
                    if (self.useBackCamera && (device as AnyObject).position == AVCaptureDevicePosition.back)
                    {
                        do
                        {
                            captureDevice = device as? AVCaptureDevice
                            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                            captureSession.addInput(captureDeviceInput)
                            captureSession.removeOutput(stillImageOutput)
                            stillImageOutput = AVCaptureStillImageOutput()
                            captureSession.addOutput(stillImageOutput)
                            break
                        }
                        catch _
                        {
                            print("error")
                        }
                    }
                    else if (!self.useBackCamera && (device as AnyObject).position == AVCaptureDevicePosition.front)
                    {
                        do
                        {
                            captureDevice = device as? AVCaptureDevice
                            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                            captureSession.addInput(captureDeviceInput)
                            captureSession.removeOutput(stillImageOutput)
                            stillImageOutput = AVCaptureStillImageOutput()
                            captureSession.addOutput(stillImageOutput)
                            break
                        }
                        catch _
                        {
                            print("error")
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: NAVIGATION & CUSTOM FUNCTIONS
    
    func captureImage()
    {
        print("IN CAPTURE IMAGE")
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo)
        {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler:
                { (sampleBuffer, error) -> Void in
                    // Process the image data (sampleBuffer) here to get an image file we can put in our captureImageView
                    if sampleBuffer != nil
                    {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                        if let dataProvider = CGDataProvider(data: imageData as! CFData)
                        {
                            // UIImage orientation assumes a landscape (left) orientation
                            // We must correct this difference and set the image to default to portrait
                            
                            // Device orientation 1 : Portrait (Set as default)
                            let deviceOrientationValue = UIDevice.current.orientation.rawValue
                            var imageOrientationValue = 3
                            // Device orientation 2 : Portrait Upside Down
                            if deviceOrientationValue == 2
                            {
                                imageOrientationValue = 2
                            }
                            // Device orientation 3 : Landscape Left
                            else if deviceOrientationValue == 3
                            {
                                imageOrientationValue = 0
                            }
                            // Device orientation 4 : Landscape Right
                            else if deviceOrientationValue == 4
                            {
                                imageOrientationValue = 1
                            }
//                            print("CVC - DEVICE ORIENTATION (FOR IMAGE): \(UIDevice.current.orientation.rawValue)")
                            
                            // Resize the image into a square
                            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                            let rawImage = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                            let sizedImage = rawImage.cropToBounds(rawImage.size.width, height: rawImage.size.width)
//                            print("CVC - OLD IMAGE ORIENTATION: \(sizedImage.imageOrientation.rawValue)")
                            
                            if let cgImage = sizedImage.cgImage
                            {
                                let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImageOrientation(rawValue: imageOrientationValue)!)
                                
                                if self.imageArray.count < 12
                                {
                                    self.imageTimestamps.append(NSDate.timeIntervalSinceReferenceDate)
                                    self.imageArray.append(image)
//                                    print("CVC - NEW IMAGE ORIENTATION: \(image.imageOrientation.rawValue)")
                                    self.refreshImageRing()
                                }
                            }
                        }
                    }
            })
        }
    }
    
    // Correct Video Orientation Issues
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool)
    {
        var assetOrientation = UIImageOrientation.up
        var isPortrait = false
        print("CHECK A: \(transform.a)")
        print("CHECK B: \(transform.b)")
        print("CHECK C: \(transform.c)")
        print("CHECK D: \(transform.d)")
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0
        {
            assetOrientation = .right
            isPortrait = true
        }
        else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0
        {
            assetOrientation = .left
            isPortrait = true
        }
        else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0
        {
            assetOrientation = .up
        }
        else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0
        {
            assetOrientation = .down
        }
        print("assetOrientation: \(assetOrientation.hashValue)")
        return (assetOrientation, isPortrait)
    }
    
    func clearTmpDirectory()
    {
        do
        {
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach
                { file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try FileManager.default.removeItem(atPath: path)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    // The equation to find the top-left edge of a circle in the circle of circles
    func basepointForCircleOfCircles(_ circle: Int, mainCircleRadius: CGFloat, radius: CGFloat, distance: CGFloat) -> CGPoint
    {
        let numberOfCirclesInCircle: Int = 12
        let angle: CGFloat = (2.0 * CGFloat(circle) * CGFloat.pi) / CGFloat(numberOfCirclesInCircle)
        let radian90: CGFloat = CGFloat(90) * (CGFloat.pi / CGFloat(180))
        let radian45: CGFloat = CGFloat(45) * (CGFloat.pi / CGFloat(180))
        let circleH: CGFloat = radius / cos(radian45)
//        print("CVC - RADIAN90: \(radian90), CIRCLE HYPOTENUSE: \(circleH)")
        let adjustRadian: CGFloat = atan((circleH / 2) / mainCircleRadius) * 2
//        print("CVC - RADIAN45: \(radian45), ADJUST RADIAN: \(adjustRadian)")
        let x = round(mainCircleRadius + distance * cos(angle - radian90 - adjustRadian) - radius)
        let y = round(mainCircleRadius + distance * sin(angle - radian90 - adjustRadian) - radius)
        
//        print("CVC - CIRCLE BASEPOINT FOR CIRCLE: \(circle): \(x), \(y), angle: \(angle), radius: \(radius), distance: \(distance)")
        
        return CGPoint(x: x, y: y)
    }
}
