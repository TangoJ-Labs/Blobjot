//
//  Extensions.swift
//  Blobjot
//
//  Created by Sean Hart on 8/7/16.
//  Copyright © 2016 blobjot. All rights reserved.
//

import Foundation
import UIKit

extension UIImage
{
//*COMPLETE *** NOT SQUARING IMAGE
    func resizeWithSquareSize(_ targetSize: CGFloat) -> UIImage
    {
        let originalSize = self.size
        
        let widthRatio  = targetSize / self.size.width
        let heightRatio = targetSize / self.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio
        {
            // Vertical Image
            newSize = CGSize(width: originalSize.width * heightRatio, height: originalSize.height * heightRatio)
        }
        else
        {
            // Horizontal Image
            newSize = CGSize(width: originalSize.width * widthRatio,  height: originalSize.height * widthRatio)
        }
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
//    func resizeWithSquareSize(_ size: CGFloat) -> UIImage?
//    {
//        // Use the original image dimensions to calculate the square starting point (either vertical or horizontal image)
//        let originalImage = self
////        var squareStartingPoint = CGPoint(x: 0, y: 0)
//        var rect: CGRect = CGRect(x: 0, y: 0, width: originalImage.size.width, height: originalImage.size.height)
////        var scale: CGFloat = originalImage.scale
//        
//        if originalImage.size.height > originalImage.size.width
//        {
//            // A vertical image
//            let startingPointY = (originalImage.size.height - originalImage.size.width) / 2
////            squareStartingPoint = CGPoint(x: 0, y: startingPointY)
//            rect = CGRect(x: 0, y: startingPointY, width: originalImage.size.width, height: originalImage.size.width)
////            scale = size / originalImage.size.width
//        }
//        else
//        {
//            // A horizontal image
//            let startingPointX = (originalImage.size.width - originalImage.size.height) / 2
////            squareStartingPoint = CGPoint(x: startingPointX, y: 0)
//            rect = CGRect(x: startingPointX, y: 0, width: originalImage.size.height, height: originalImage.size.height)
////            scale = size / originalImage.size.height
//        }
//        
//        // Create bitmap image from context using the rect
//        let imageRef: CGImage = originalImage.cgImage!.cropping(to: rect)!
//        
//        // Create a new image based on the imageRef and rotate back to the original orientation
//        let image: UIImage = UIImage(cgImage: imageRef, scale: originalImage.scale, orientation: originalImage.imageOrientation)
//        
//        return image
//    }
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage
    {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1))
    {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

extension UISlider
{
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        var bounds: CGRect = self.bounds
        bounds = bounds.insetBy(dx: -10, dy: -20)
        return bounds.contains(point)
    }
}

// "It uses recursion to find the current top view controller": http://stackoverflow.com/questions/30052299/show-uialertcontroller-outside-of-viewcontroller
extension UIAlertController
{
    func show()
    {
        present(animated: true, completion: nil)
    }
    
    func present(animated: Bool, completion: (() -> Void)?)
    {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController
        {
            presentFromController(controller: rootVC, animated: animated, completion: completion)
        }
    }
    
    private func presentFromController(controller: UIViewController, animated: Bool, completion: (() -> Void)?)
    {
        if let navVC = controller as? UINavigationController,
            let visibleVC = navVC.visibleViewController
        {
            presentFromController(controller: visibleVC, animated: animated, completion: completion)
        }
        else
            if let tabVC = controller as? UITabBarController,
                let selectedVC = tabVC.selectedViewController
            {
                presentFromController(controller: selectedVC, animated: animated, completion: completion)
            }
            else
            {
                controller.present(self, animated: animated, completion: completion);
        }
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
    var radiansToDegrees: Double { return Double(self) * 180 / .pi }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
