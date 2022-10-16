//
//  UIImage+Extensions.swift
//  OSMap (iOS)
//
//  Created by Aleksandr Borodulin on 13.10.2022.
//

import Foundation

extension UIImage {
    func imageWithAlpha(alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPointZero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
