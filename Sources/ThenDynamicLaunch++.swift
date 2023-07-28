//
//  ThenDynamicLaunch++.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit
import Foundation

// MARK: - Basic
extension ThenDynamicLaunch {
    
    /// 针对启动图的临时操作路径
    func operateTmpPath() -> String? {
        var lock = pthread_mutex_t()
        pthread_mutex_init(&lock, nil)
        pthread_mutex_lock(&lock)
        guard let launchImagePath = ThenDynamicLaunch.defaultlaunchSnapshotsPath else {
            pthread_mutex_unlock(&lock)
            return nil
        }
        var tmpPath = launchImagePath
        // iOS13.0以下无法直接对启动图进行操作，需要将其先移动到其他可操作的文件夹。
        if #available(iOS 13.0, *) { } else {
            tmpPath = NSTemporaryDirectory().appending(Keys.Path.tmp.rawValue)
            do {
                try FileManager.default.removeItem(atPath: tmpPath)
                try FileManager.default.moveItem(atPath: launchImagePath, toPath: tmpPath)
            } catch {
                pthread_mutex_unlock(&lock)
                return nil
            }
        }
        return tmpPath
        
        // if #available(iOS 13.0, *) {} else { try? FileManager.default.moveItem(atPath: tmpPath, toPath: launchImagePath) }
    }
    
    /// 校验
    func checkLaunchImage() {
        guard let version = Bundle.main.version else { return }
        if let version_check_old = value(Keys.Version.check.rawValue), version_check_old == version + "_check" {
            return
        }
        // 操作目录
        guard let tmpPath = self.operateTmpPath() else {
            return
        }
        var portraitImages: [UIImage] = []
        var portraitRect = CGRect.zero
        if Bundle.main.isSupportPortrait {
            portraitImages = launchScreenLastImage(isPortrait: true)
            portraitRect = Bundle.main.launchImageViewRects(true)?.last ?? .zero
        }
        //
        var landscapeImages: [UIImage] = []
        var landscapeRect = CGRect.zero
        if Bundle.main.isSupportlandscape {
            landscapeImages = launchScreenLastImage(isPortrait: false)
            landscapeRect = Bundle.main.launchImageViewRects(false)?.last ?? .zero
        }
        // 启动图文件中没有UIImageView元素
        if portraitImages.isEmpty && landscapeImages.isEmpty {
            return
        }
        
        func checkForAbnormalImage(_ image: UIImage) -> Bool {
            let images = image.isPortrait ? portraitImages : landscapeImages
            guard !images.isEmpty else { return false }
            let rect = image.isPortrait ? portraitRect : landscapeRect
            if let crop = image.cropped(to: rect) {
                for i in images {
                    if crop.thresholdEqual(to: i) {
                        return false
                    }
                }
            }
            // 如果截图和所有图片都不能匹配，则认为启动图异常
            return true
        }
        
        // 记一下哪些图片已经被修改过，修改过的图片不用修复
        let modifyNames = Orientation.allCases.compactMap { value($0.key_name) }
        let safeArea = Bundle.main.containSafeAreaLayoutGuide
        
        // 保存异常的启动图名称
        var imageNames = [String]()
        for file in (try? FileManager.default.contentsOfDirectory(atPath: tmpPath)) ?? [] {
            guard !modifyNames.contains(file) else {
                continue
            }
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: tmpPath + "/" + file)),
               let image = UIImage(data: data, scale: UIScreen.main.scale) else {
                continue
            }
            // 如果包含安全区域约束并且是横屏启动图
            if safeArea && !image.isPortrait {
                imageNames.append(file)
            } else {
                if checkForAbnormalImage(image) {
                    imageNames.append(file)
                }
            }
        }
        // 修复异常的启动图
        for imageName in imageNames {
            let direction = launchImageOrientation(path: tmpPath, imageName: imageName)
            save(direction.name, value: imageName)
            // write local
            if let image = availableSystemLaunchImage(with: direction) {
                try? image.pngData()?.write(to: URL(fileURLWithPath: tmpPath + "/" + imageName))
            }
        }
        // 修改目录
        if #available (iOS 13.0, *) {} else {
            if let launchPath = ThenDynamicLaunch.defaultlaunchSnapshotsPath {
                try? FileManager.default.moveItem(atPath: tmpPath, toPath: launchPath)
            }
        }
        //
        save(Keys.Version.check.rawValue, value: version)
    }

}

// MARK: - 启动图
extension ThenDynamicLaunch {
    
    /// 系统启动图
    func systemlaunchImage(with direction: Orientation) -> UIImage? {
        guard let version = Bundle.main.version, let systemlaunchImageCachePath = Keys.BackUp.system.cachePath else {
            return nil
        }
        // 检查之前生成的启动图是否存在本地缓存，如果存在则直接返回
        let cachePath = systemlaunchImageCachePath + "/\(direction.name)_\(version)"
        if FileManager.default.fileExists(atPath: cachePath) {
            if let launchImageData = try? Data(contentsOf: URL(fileURLWithPath: cachePath)),
               let launchImage = UIImage(data: launchImageData, scale: UIScreen.main.scale) {
                return launchImage
            }
            try? FileManager.default.removeItem(atPath: cachePath)
        }
        
        //
        guard let controller = Bundle.main.launchScreenController else { return nil }
        
        let launchClosure: () -> UIImage? = {
            if #available(iOS 13.0, *) {
                controller.overrideUserInterfaceStyle = direction.isDark ? .dark : .light
            }
            guard let view = controller.view else {
                return nil
            }
            view.bounds = UIScreen.main.bounds
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, UIScreen.main.scale)
            defer { UIGraphicsEndImageContext() }
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        let saveClosure: (UIImage?) -> UIImage? = { image in
            guard let image = image else { return nil }
            DispatchQueue.global(qos: .default).async {
                try? image.pngData()?.write(to: URL(fileURLWithPath: cachePath))
            }
            return image
        }
        return saveClosure(launchClosure())
    }

    /// 可用的系统启动图
    func availableSystemLaunchImage(with direction: Orientation) -> UIImage? {
        switch direction {
        case .portraitLight:
            if Bundle.main.isSupportPortrait, Bundle.main.interfaceStyle != .dark {
                return systemlaunchImage(with: .portraitLight)
            }
        case .landscapeLight:
            if Bundle.main.isSupportlandscape, Bundle.main.interfaceStyle != .dark {
                return systemlaunchImage(with: .landscapeLight)
            }
        default:
            break
        }
        if #available(iOS 13.0, *) {
            switch direction {
            case .portraitDark:
                if Bundle.main.isSupportPortrait, Bundle.main.interfaceStyle != .light {
                    return systemlaunchImage(with: .portraitDark)
                }
            case .landscapeDark:
                if Bundle.main.isSupportlandscape, Bundle.main.interfaceStyle != .light {
                    return systemlaunchImage(with: .landscapeDark)
                }
            default:
                break
            }
        }
        return nil
    }

    /// 修改的启动图
    func customlaunchImage(with direction: Orientation) -> UIImage? {
        
        guard let path = Keys.BackUp.custom.cachePath else {
            return nil
        }
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: "\(path)/\(direction.name)")), let image = UIImage(data: data) {
            return image
        }
        
        return availableSystemLaunchImage(with: direction)
    }

}

extension ThenDynamicLaunch {
        
    func launchImageName(with direction: Orientation, atPath path: String) -> String? {
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        let key = direction.key_name
        // 看一下这个类型的图片名称是不是已经记录过了
        if let imageName = value(key), let name = filterlaunchImageExists(at: path, imageName: imageName) {
            return name
        }
        
        guard let lists = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            return nil
        }
        // 已记录的启动图名称
        let nameSet = Orientation.allCases.compactMap { value($0.key_name) }
        var qualifiedPaths = [String]()
        for fileName in lists {
            if nameSet.contains(fileName) { continue }
            let fullPath = path + "/" + fileName
            if let data = try? Data(contentsOf: URL(fileURLWithPath: fullPath)), let launchImage = UIImage(data: data, scale: UIScreen.main.scale) {
                // 过滤掉尺寸不对的图片
                if (direction.isPortrait && launchImage.isPortrait) || (!direction.isPortrait && !launchImage.isPortrait) {
                    qualifiedPaths.append(fullPath)
                    continue
                }
            }
        }
        
        /// judge count
        switch qualifiedPaths.count {
        case 0:
            return nil
        case 1:
            let name = (qualifiedPaths[0] as NSString).lastPathComponent
            save(key, value: name)
            return name
        default:
            break
        }
        // available
        guard let targetImage = availableSystemLaunchImage(with: direction) else {
            return nil
        }
        let imageNames = filterlaunchImageName_0(for: targetImage, atPaths: qualifiedPaths)
        switch imageNames.count {
        case 0:
            // 如果1张图片都匹配不上，大概率是系统启动图异常（例如启动图图片黑化或白化)
            let names = filterlaunchImageName_1(for: targetImage, atPaths: qualifiedPaths)
            if names.count == 1 {
                let name = names[0]
                save(key, value: name)
                return name
            }
        case 1:
            let name = imageNames[0]
            save(key, value: name)
            return name
        default:
            break
        }
        
        // 匹配右下角1×1像素点颜色
        let name = filterlaunchImageName_2(for: targetImage, atPaths: qualifiedPaths)
        save(key, value: name)
        return name
    }
    
    /// 获取某个启动图的类型
    func launchImageOrientation(path: String, imageName: String) -> Orientation {
        let fullpath = path + "/" + imageName
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: fullpath)), let image = UIImage(data: data) else {
            return .portraitLight
        }
        switch Bundle.main.interfaceStyle {
        case .system:
            // 看一下是否记录过相同尺寸的启动图名称(`这意味着当前启动图就是被记录启动图的相反类型`)
            switch image.isPortrait {
            case true:
                let key_light = Orientation.portraitLight.key_name
                if let name = value(key_light), filterlaunchImageExists(at: path, imageName: name) != nil {
                    if #available(iOS 13.0, *) { return .portraitDark }
                }
                if #available(iOS 13.0, *) {
                    let key_dark = Orientation.portraitDark.key_name
                    if let name = value(key_dark), filterlaunchImageExists(at: path, imageName: name) != nil {
                        return .portraitLight
                    }
                }
            default:
                let key_light = Orientation.landscapeLight.key_name
                if let name = value(key_light), filterlaunchImageExists(at: path, imageName: name) != nil {
                    if #available(iOS 13.0, *) { return .landscapeDark }
                }
                if #available(iOS 13.0, *) {
                    let key_dark = Orientation.landscapeDark.key_name
                    if let name = value(key_dark), filterlaunchImageExists(at: path, imageName: name) != nil {
                        return .landscapeLight
                    }
                }
            }
            let lightImage = availableSystemLaunchImage(with: image.isPortrait ? .portraitLight : .landscapeLight)
            var darkImage: UIImage?
            if #available(iOS 13.0, *) {
                darkImage = availableSystemLaunchImage(with: image.isPortrait ? .portraitDark : .landscapeDark)
            }
            
            // 将图片指定区域替换为纯色后进行比较
            let solidColor = UIColor.black
            if let rects = Bundle.main.launchImageViewRects(image.isPortrait), let targetImage = image.draw(in: rects, with: UIColor.black) {
                var results = [UIImage]()
                for img in [lightImage, darkImage].compactMap({ $0 }) {
                    if let t_image = img.draw(in: rects, with: solidColor) {
                        if t_image.thresholdEqual(to: targetImage) {
                            results.append(t_image)
                        }
                    }
                }
                if results.count == 1 {
                    if results[0] == lightImage {
                        return image.isPortrait ? Orientation.portraitLight : Orientation.landscapeLight
                    }
                    if #available(iOS 13.0, *), results[0] == darkImage {
                        return image.isPortrait ? Orientation.portraitDark : Orientation.landscapeDark
                    }
                }
            }
            
            // 比较图片右下角1×1像素点颜色
            let pixelImage = image.scaled(to: 1.0)
            let pixelRect = CGRect(x: pixelImage.size.width - 1, y: pixelImage.size.height - 1, width: 1, height: 1)
            if let targetColor = pixelImage.pixelColor(in: pixelRect) {
                var minSimilarity: CGFloat = 0
                var matchedImage: UIImage?
                for i in [lightImage, darkImage].compactMap({ $0 }) {
                    if let color = i.pixelColor(in: pixelRect) {
                        let similarity = targetColor.distance(to: color)
                        if minSimilarity > similarity {
                            minSimilarity = similarity
                            matchedImage = image
                        }
                    }
                }
                if matchedImage === lightImage {
                    return image.isPortrait ? Orientation.portraitLight : Orientation.landscapeLight
                }
                if #available(iOS 13.0, *) {
                    if matchedImage === darkImage {
                        return image.isPortrait ? .portraitDark : .landscapeDark
                    }
                }
            }
            
            return image.isPortrait ? .portraitLight : .landscapeLight
        case .dark:
            if #available(iOS 13.0, *) {
                return image.isPortrait ? .portraitDark : .landscapeDark
            }
        default:
            return image.isPortrait ? .portraitLight : .landscapeLight
        }
        
        return .portraitLight
    }
    
    /// 获取启动图文件中最后1个UIImageView的深色与浅色截图
    func launchScreenLastImage(isPortrait: Bool) -> [UIImage] {
        guard let controller = Bundle.main.launchScreenController, let rects = Bundle.main.launchImageViewRects(isPortrait), let last = rects.last else {
            return []
        }
        let w = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let h = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        
        controller.view.bounds = CGRect(x: 0, y: 0, width: isPortrait ? w : h, height: isPortrait ? h : w)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        var images = [UIImage]()
        let snpshot = {
            if let image = controller.view.snapShot()?.cropped(to: last) {
                images.append(image)
            }
        }
        if #available(iOS 13.0, *), Bundle.main.interfaceStyle == .system {
            controller.overrideUserInterfaceStyle = .dark
            snpshot()
            controller.overrideUserInterfaceStyle = .light
            snpshot()
        }
        if images.isEmpty {
            snpshot()
        }
        return images
    }
    
}

