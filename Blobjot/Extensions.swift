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
    func cropToBounds(_ width: CGFloat, height: CGFloat) -> UIImage
    {
        let contextImage: UIImage = UIImage(cgImage: self.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        let contextScale: CGFloat = self.scale
        let contextOrientation: UIImageOrientation = self.imageOrientation
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = width
        var cgheight: CGFloat = height
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height
        {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        }
        else
        {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: contextScale, orientation: contextOrientation)
        
        return image
    }
    
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
extension Int {
    init(_ bool:Bool) {
        self = bool ? 1 : 0
    }
}
extension Bool {
    init(_ number: Int) {
        self.init(number as NSNumber)
    }
}
