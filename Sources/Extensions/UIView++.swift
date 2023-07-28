//
//  UIView++.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit

extension UIView {
        
    var subImageViews: [UIImageView] {
        var imageViews = [UIImageView]()
        for subview in subviews {
            imageViews += subview.subImageViews
            guard !subview.isHidden,
                  let imageView = subview as? UIImageView,
                  imageView.image != nil else {
                continue
            }
            imageViews.append(imageView)
        }
        return imageViews
    }
        
    var subImageViewRects: [CGRect] {
        subImageViews
            .compactMap {
                let imageFrame = $0.convert($0.bounds, to: self)
                let imageRect  = $0.image?.rect(with: $0.contentMode, in: $0.bounds.size, clipsToBounds: $0.clipsToBounds) ?? .zero
                
                let x = imageFrame.minX + imageRect.minX
                let y = imageFrame.minY + imageRect.minY
                let w = imageRect.width
                let h = imageRect.height
                
                return CGRect(x: x, y: y, width: w, height: h)
            }
    }
    
}


extension UIView {
    
    func snapShot(opaque: Bool = true, scale: CGFloat = 0, afterScreenUpdates: Bool = true) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, scale)
        defer { UIGraphicsEndImageContext() }
        drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
}
