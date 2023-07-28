//
//  ThenDynamicLaunch+Filter.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit
import Foundation

// MARK: - Filter
extension ThenDynamicLaunch {
                    
    /// 检查启动图文件是否存在
    func filterlaunchImageExists(at path: String, imageName: String) -> String? {
        let fullPath = (path as NSString).appendingPathComponent(imageName)
        if FileManager.default.fileExists(atPath: fullPath) {
            return imageName
        }
        // 删除记录中无效的启动图名称
        for direction in Orientation.allCases {
            let key = direction.key_name
            if value(key) == imageName {
                save(key, value: nil)
                return nil
            }
        }
        return nil
    }
    
    /// 遍历系统启动图并和生成的目标启动图进行比较
    func filterlaunchImageName_0(for targetImage: UIImage, atPaths paths: [String]) -> [String] {
        var imageNames: [String] = []
        for path in paths {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let launchImage = UIImage(data: data, scale: UIScreen.main.scale)
            else {
                continue
            }
            if targetImage.thresholdEqual(to: launchImage) {
                imageNames.append((path as NSString).lastPathComponent)
            }
        }
        return imageNames
    }
    
    /// 将启动图指定区域替换为纯色后进行比较
    func filterlaunchImageName_1(for targetImage: UIImage, atPaths paths: [String]) -> [String] {
        guard let frames = Bundle.main.launchImageViewRects(targetImage.isPortrait) else {
            return []
        }
        let solidColor = UIColor.black
        guard let image = targetImage.scaled(to: UIScreen.main.scale).draw(in: frames, with: solidColor) else {
            return []
        }
        var fileNames = [String]()
        for path in paths {
            guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let scaleImage = UIImage(data: imageData, scale: UIScreen.main.scale),
                  let launchImage = scaleImage.draw(in: frames, with: solidColor)
            else {
                continue
            }
            if image.thresholdEqual(to: launchImage) {
                fileNames.append(URL(fileURLWithPath: path).lastPathComponent)
            }
        }
        return fileNames
    }
    
    /// 比较启动图右下角1×1像素尺寸的颜色
    func filterlaunchImageName_2(for targetImage: UIImage, atPaths paths: [String]) -> String? {
        let image = targetImage.scaled(to: 1.0)
        let pixelRect = CGRect(x: image.size.width - 1, y: image.size.height - 1, width: 1, height: 1)
        guard let color = image.pixelColor(in: pixelRect) else {
            return nil
        }
        
        var similarity = CGFLOAT_MAX
        var fileName = ""
        for path in paths {
            guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let scaleImage = UIImage(data: imageData, scale: 1.0),
                  let scaleColor = scaleImage.pixelColor(in: pixelRect)
            else {
                continue
            }
            let space = color.distance(to: scaleColor)
            if similarity > space {
                similarity = space
                fileName = (path as NSString).lastPathComponent
            }
        }
        return fileName
    }
    
}
