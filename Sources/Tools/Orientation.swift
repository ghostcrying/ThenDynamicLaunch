//
//  Orientation.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit
import Foundation

/// 操作类型
public enum ImageModern: Int {
    case system
    case custom
}

/// 方向类型
public enum Orientation: String, CaseIterable {
    
    public static var allCases: [Orientation] = {
        if #available(iOS 13.0, *) {
            return [.portraitLight, .portraitDark, .landscapeLight, .landscapeDark]
        } else {
            return [.portraitLight, .landscapeLight]
        }
    }()
    
    case portraitLight
    case landscapeLight
    
    @available(iOS 13.0, *)
    case portraitDark
    
    @available(iOS 13.0, *)
    case landscapeDark
    
    var isPortrait: Bool {
        switch self {
        case .portraitLight, .portraitDark:
            return true
        default:
            return false
        }
    }
    
    var isDark: Bool {
        switch self {
        case .portraitDark, .landscapeDark:
            return true
        default:
            return false
        }
    }
    
    var name: String {
        switch self {
        case .portraitLight:
            return "portrait_light"
        case .portraitDark:
            return "portrait_dark"
        case .landscapeDark:
            return "landscape_dark"
        case .landscapeLight:
            return "landscape_light"
        }
    }
    
    var key_name: String { name + "_name" }
    
    var key_modify: String { name + "_modify" }
    
}
