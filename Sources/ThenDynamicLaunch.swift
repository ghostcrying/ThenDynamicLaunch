//
//  ThenDynamicLaunch.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit
import Foundation

public class ThenDynamicLaunch {
    
    public static let shared = ThenDynamicLaunch()
    
    private init() {
        self.checkLaunchImage()
        // 版本变更
        guard let oldversion = value(Keys.Version.default.rawValue), let version = Bundle.main.version, oldversion != version else {
            save(Keys.Version.default.rawValue, value: Bundle.main.version)
            return
        }
        save(Keys.Version.default.rawValue, value: Bundle.main.version)
        // 删除上个版本的系统启动图备份文件
        if let path = Keys.BackUp.system.cachePath {
            let files = try? FileManager.default.contentsOfDirectory(atPath: path)
            files?
                .filter { $0.hasSuffix(version) == false }
                .forEach { try? FileManager.default.removeItem(atPath: path + "/" + $0) }
        }
        
        // 找出上个版本修改过的启动图类型
        if Orientation.allCases.filter({ direction in
            // 删除上个版本记录的启动图名称
            save(direction.key_name, value: nil)
            // 移除未修改的类型，最后保留下来的就是修改过的类型
            return value(direction.key_modify) == "0"
        }).isEmpty {
            // 上个版本没有修改过启动图
            return
        }
        DispatchQueue.global().async {
            guard let path = Keys.BackUp.custom.cachePath else { return }
            Orientation.allCases.forEach { direction in
                if let data = try? Data(contentsOf: URL(fileURLWithPath: path + "/" + direction.name)), let image = UIImage(data: data, scale: UIScreen.main.scale) {
                    self.replace(with: image, direction: direction)
                } else {
                    self.save(direction.key_modify, value: nil)
                }
            }
        }
    }
    
    public func config() { }
}

public extension ThenDynamicLaunch {
    
    /// 系统默认启动图路径
    /// 原理: 直接修改对应路径的启动图即可在下次启动修改launch image.
    /// 版本:
    /// - iOS 10.0+
    ///   - 后缀: ktx, 有权限
    /// - iOS 10.0-
    ///   - 后缀: png, 无权限
    static var defaultlaunchSnapshotsPath: String? {
        guard let bundleID = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String else {
            print("Read CFBundleIdentifier failed.")
            return nil
        }
        
        let snapshotsPath: String
        if #available(iOS 13.0, *) {
            let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
            snapshotsPath = "\(libraryDirectory)/SplashBoard/Snapshots/\(bundleID) - {DEFAULT GROUP}"
        } else {
            let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
            snapshotsPath = cacheDirectory + "/Snapshots/" + bundleID
        }
        
        if FileManager.default.fileExists(atPath: snapshotsPath) {
            return snapshotsPath
        }
        return nil
    }
    
    /// 启动图
    func launchImage(with modern: ImageModern, direction: Orientation) -> UIImage? {
        switch modern {
        case .system:
            return systemlaunchImage(with: direction)
        case .custom:
            return customlaunchImage(with: direction)
        }
    }
     
    /// Main Replace
    func replace(with image: UIImage?, direction: Orientation = .portraitLight, validation handler: ((UIImage?, UIImage) -> Bool)? = nil) {
        // 操作路径
        guard let tmpPath = self.operateTmpPath() else {
            return
        }
        
        // 调整图片尺寸，保持和系统启动图一样
        guard let input = image ?? availableSystemLaunchImage(with: direction),
              let replace = input.resize(isPortrait: direction.isPortrait)
        else {
            return
        }
        // 获取启动图
        guard let imageName = launchImageName(with: direction, atPath: tmpPath) else {
            return
        }
        
        var result = true
        let imagePath = tmpPath + "/" + imageName
        if let handler = handler {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)), let old = UIImage(data: data) {
                result = handler(old, replace)
            } else {
                return
            }
        }
        guard result, let data = replace.pngData(), let customBackupPath = Keys.BackUp.custom.cachePath else {
            return
        }
        do {
            try data.write(to: URL(fileURLWithPath: imagePath))
            if #available (iOS 13.0, *) {} else {
                if let launchPath = ThenDynamicLaunch.defaultlaunchSnapshotsPath {
                    try? FileManager.default.moveItem(atPath: tmpPath, toPath: launchPath)
                }
            }
        } catch {
            print(error.localizedDescription)
            return
        }
        // 更新启动图的修改记录
        save("\(direction.name)_modify", value: image != nil ? "1" : "0")
        // 更新启动图的备份文件夹
        let backupPath = customBackupPath + "/\(direction.name)"
        if image == nil {
            try? FileManager.default.removeItem(atPath: backupPath)
        } else {
            try? data.write(to: URL(fileURLWithPath: backupPath))
        }
    }

    ///
    func restore() {
        Orientation.allCases.forEach {
            let key = $0.name + "_modify"
            if value(key) == "1" {
                replace(with: nil, direction: $0)
            }
        }
        
    }
    
}
