//
//  MainViewController.swift
//  Blobjot
//
//  Created by Sean Hart on 3/2/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, MapViewControllerDelegate
{
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
    
    // Declare the view controllers that make up the page viewer
    var viewControllers: [UIViewController]!
    var cameraVC: CameraViewController!
    var mapVC: MapViewController!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Instantiate and assign delegates for the Page Viewer View Controllers
        cameraVC = CameraViewController()
        mapVC = MapViewController()
        mapVC.mapViewDelegate = self
        viewControllers = [cameraVC, mapVC]
        
        // Status Bar Settings
        UIApplication.shared.isStatusBarHidden = true
//        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        if self.navigationController != nil
        {
            self.navigationController!.isNavigationBarHidden = true
        }
//        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
////        navBarHeight = self.navigationController?.navigationBar.frame.height
//        navBarHeight = 44
//        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        print("MainVC - SCREEN SIZE: \(screenSize)")
        print("MainVC - VIEW SIZE: \(self.view.frame)")
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        viewContainer.backgroundColor = UIColor.black
        self.view.addSubview(viewContainer)
        
        // Add the Page View container and controller at the top of the view, but under the nav bar and search bar
        pageViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewContainer.addSubview(pageViewContainer)
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([viewControllers.first!], direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion: nil)
        pageViewContainer.addSubview(pageViewController.view)
        
//        // Add a page controller (dots indicating the currently viewed page) under the page viewer
//        pageControl = UIPageControl(frame: CGRect(x: 0, y: viewContainer.frame.height - 10 - viewContainer.frame.width, width: viewContainer.frame.width, height: 0))
//        pageControl.numberOfPages = viewControllers.count
//        pageControl.currentPage = 0
//        pageControl.tintColor = UIColor.lightGray
//        pageControl.pageIndicatorTintColor = UIColor.lightGray
//        pageControl.currentPageIndicatorTintColor = Constants.Colors.colorPurple
//        viewContainer.addSubview(pageControl)
        
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    
    // MARK: DELEGATE METHODS
    
    func goToCamera()
    {
        pageViewController.setViewControllers([viewControllers.first!], direction: UIPageViewControllerNavigationDirection.reverse, animated: true, completion: nil)
        
        UIApplication.shared.isStatusBarHidden = true
        if self.navigationController != nil
        {
            self.navigationController!.isNavigationBarHidden = true
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
//        if let pendingVC = pendingViewControllers.first
//        {
//            let index = viewControllers.index(of: pendingVC)
//            pageControl.currentPage = index!
//        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        print("MainVC - PVC - DFA: \(completed)")
        if completed
        {
            print("MainVC - PVC - DFA: \(completed)")
            self.setNeedsStatusBarAppearanceUpdate()
            
            // Hide the statusbar if the previous VC was the MapVC (will now be on the CameraVC)
            if previousViewControllers.count > 0
            {
                if previousViewControllers[0] == mapVC
                {
                    UIApplication.shared.isStatusBarHidden = true
                    if self.navigationController != nil
                    {
                        self.navigationController!.isNavigationBarHidden = true
                    }
                }
                else
                {
                    UIApplication.shared.isStatusBarHidden = false
                    if self.navigationController != nil
                    {
                        self.navigationController!.isNavigationBarHidden = false
                    }
                }
            }
        }
    }
    
    
//    // MARK: PAGE VIEW CONTROLLER - DELEGATE METHODS
//    // Return how many pages are needed in the Page Viewer
//    func presentationCount(for pageViewController: UIPageViewController) -> Int
//    {
//        return viewControllers.count
//    }
//    
//    func presentationIndex(for pageViewController: UIPageViewController) -> Int
//    {
//        return 0
//    }
}
