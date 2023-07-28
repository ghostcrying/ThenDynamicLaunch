//
//  UIColor++.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit

/// colorDistanceBetweenColor
extension UIColor {
    
    func distance(to otherColor: UIColor) -> CGFloat {
        let color1 = self.convertedToHsb()
        let color2 = otherColor.convertedToHsb()
        
        let deltaX = color1.brightness * color1.saturation * cos(color1.hue - color2.hue)
        let deltaY = color1.brightness * color1.saturation * sin(color1.hue - color2.hue)
        let deltaZ = color1.brightness - color2.brightness
        
        return sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
    }
    
    private func convertedToHsb() -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        return (hue * 360, saturation, brightness)
    }
    
}

