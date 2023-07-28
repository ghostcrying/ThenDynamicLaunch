//
//  Bundle++.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit
import Foundation

extension Bundle {
    
    /// 获取launchScreen上关于UIImage的所有位置数据
    func launchImageViewRects(_ isPortrait: Bool) -> [CGRect]? {
        switch isPortrait {
        case true:
            guard let view = launchScreenController?.view, isSupportPortrait else {
                return nil
            }
            view.bounds = CGRect(x: 0,
                                 y: 0,
                                 width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height),
                                 height: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
            view.setNeedsLayout()
            view.layoutIfNeeded()
            return view.subImageViewRects
        default:
            guard let view = launchScreenController?.view, isSupportlandscape else {
                return nil
            }
            view.bounds = CGRect(x: 0,
                                 y: 0,
                                 width: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height),
                                 height: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
            view.setNeedsLayout()
            view.layoutIfNeeded()
            return view.subImageViewRects
        }
    }
}

extension Bundle {
    
    /// value for CFBundleShortVersionString
    var version: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var launchScreenController: UIViewController? {
        guard let storyboardName = infoDictionary?["UILaunchStoryboardName"] as? String else {
            return nil
        }
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateInitialViewController()
    }
    
    var isSupportPortrait: Bool {
        guard let orientations = Bundle.main.infoDictionary?["UISupportedInterfaceOrientations"] as? [String] else {
            return true
        }
        return orientations.contains {
            $0 == "UIInterfaceOrientationPortrait" ||
            $0 == "UIInterfaceOrientationPortraitUpsideDown"
        }
    }
    
    var isSupportlandscape: Bool {
        guard let orientations = Bundle.main.infoDictionary?["UISupportedInterfaceOrientations"] as? [String] else {
            return true
        }
        return orientations.contains {
            $0 == "UIInterfaceOrientationLandscapeLeft" ||
            $0 == "UIInterfaceOrientationLandscapeRight"
        }
    }
    
    /// 启动图文件是否包含安全区域约束
    var containSafeAreaLayoutGuide: Bool {
        guard let view = launchScreenController?.view else {
            return false
        }
        
        let guide = view.safeAreaLayoutGuide
        for constraint in view.constraints {
            if constraint.firstItem === guide && constraint.secondItem !== view {
                return true
            }
            if constraint.secondItem === guide && constraint.firstItem !== view {
                return true
            }
        }
        return false
    }
}

// MARK: - UserInterfaceStyle
enum UserInterfaceStyle: Int {
    
    case system = 0
    
    case light
    
    case dark
}

extension Bundle {
    
    var interfaceStyle: UserInterfaceStyle {
        if #available(iOS 13.0, *), let style = infoDictionary?["UIUserInterfaceStyle"] as? String {
            if style == "Automatic" {
                return .system
            }
            if style == "Light" {
                return .light
            }
            if style == "Dark" {
                return .dark
            }
        }
        return .light
    }
    
}
