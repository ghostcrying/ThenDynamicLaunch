//
//  Color.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import Foundation

struct LaunchColor {
    
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    var a: CGFloat
    
    static func thresholdEqual(
        _ lhs: LaunchColor,
        _ rhs: LaunchColor,
        threshold: CGFloat = 0.2)
    -> Bool {
        abs(lhs.r - rhs.r) <= threshold &&
        abs(lhs.g - rhs.g) <= threshold &&
        abs(lhs.b - rhs.b) <= threshold &&
        abs(lhs.a - rhs.a) <= threshold
    }
}
