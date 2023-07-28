//
//  UIImage++.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit
import Foundation

extension UIImage {
    
    var launchOpaque: Bool {
        guard let info = self.cgImage?.alphaInfo else {
            return false
        }
        switch info {
        case .noneSkipLast, .noneSkipFirst, .none:
            return true
        default:
            return false
        }
    }
    
    var isPortrait: Bool { size.width < size.height }
    
    func scaled(to scale: CGFloat) -> UIImage {
        guard self.scale != scale, let cgImage = self.cgImage else {
            return self
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: self.imageOrientation)
    }
        
    /// 某块像素点的平均颜色值
    func pixelColor(in rect: CGRect) -> UIColor? {
        
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard
            bounds.intersects(rect),
            let cgimage = cgImage,
            let dataProvider = cgimage.dataProvider,
            let data = dataProvider.data,
            let pointer = CFDataGetBytePtr(data)
        else {
            return nil
        }
        
        let comptsPerPixel = cgimage.bitsPerPixel / cgimage.bitsPerComponent
        
        let image_w   = Int(size.width)
        let interRect = bounds.intersection(rect)
        
        let inter_x = Int(interRect.minX)
        let inter_y = Int(interRect.minY)
        let inter_w = Int(interRect.width)
        let inter_h = Int(interRect.height)
        
        var r: Int = 0
        var g: Int = 0
        var b: Int = 0
        var a: Int = 0
        
        for y in 0..<inter_h {
            for x in 0..<inter_w {
                let index = (image_w * (inter_y + y) + (inter_x + x)) * comptsPerPixel
                r += Int(pointer.advanced(by: index + 0).pointee)
                g += Int(pointer.advanced(by: index + 1).pointee)
                b += Int(pointer.advanced(by: index + 2).pointee)
                a += Int(pointer.advanced(by: index + 3).pointee)
            }
        }
        
        let pixelCount = inter_w * inter_h
        
        let red   = (CGFloat(r) / CGFloat(pixelCount)) / 255.0
        let green = (CGFloat(g) / CGFloat(pixelCount)) / 255.0
        let blue  = (CGFloat(b) / CGFloat(pixelCount)) / 255.0
        let alpha = (CGFloat(a) / CGFloat(pixelCount)) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    func cropped(to rect: CGRect) -> UIImage? {
        let imageRect = CGRect(origin: .zero, size: self.size)
        if rect.contains(imageRect) { return self }
        
        var scaledRect = rect
        scaledRect.origin.x    *= self.scale
        scaledRect.origin.y    *= self.scale
        scaledRect.size.width  *= self.scale
        scaledRect.size.height *= self.scale
        guard scaledRect.size.width > 0, scaledRect.size.height > 0 else {
            return nil
        }
        guard let imageRef = self.cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        let croppedImage = UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        return croppedImage
    }

}

// MARK: - Draw
extension UIImage {
    
    /// draw rect with color
    func draw(in rects: [CGRect], with color: UIColor) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(self.size, self.launchOpaque, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        draw(in: CGRect(origin: .zero, size: self.size))
        context.setFillColor(color.cgColor)
        
        for r in rects {
            context.fill(r)
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// ll_drawInRect:(CGRect)rect contentMode:(UIViewContentMode)contentMode
    func draw(in rect: CGRect, content mode: UIView.ContentMode) {
        /// ll_CGRectFitWithContentMode:(UIViewContentMode)mode size:(CGSize)size rect:(CGRect)rect
        func modeRect(with mode: UIView.ContentMode, size: CGSize, rect: CGRect) -> CGRect {
            var rect = rect.standardized
            var size = size
            size.width  = size.width  < 0 ? -size.width  : size.width
            size.height = size.height < 0 ? -size.height : size.height
            let center = CGPoint(x: rect.midX, y: rect.midY)
            
            switch mode {
            case .scaleAspectFit, .scaleAspectFill:
                if rect.size.width < 0.01 || rect.size.height < 0.01 || size.width < 0.01 || size.height < 0.01 {
                    rect.origin = center
                    rect.size = .zero
                } else {
                    var scale: CGFloat
                    if mode == .scaleAspectFit {
                        if size.width / size.height < rect.size.width / rect.size.height {
                            scale = rect.size.height / size.height
                        } else {
                            scale = rect.size.width / size.width
                        }
                    } else {
                        if size.width / size.height < rect.size.width / rect.size.height {
                            scale = rect.size.width / size.width
                        } else {
                            scale = rect.size.height / size.height
                        }
                    }
                    size.width *= scale
                    size.height *= scale
                    rect.size = size
                    rect.origin = CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
                }
            case .center:
                rect.size = size
                rect.origin = CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
            case .top:
                rect.origin.x = center.x - size.width * 0.5
                rect.size = size
            case .bottom:
                rect.origin.x = center.x - size.width * 0.5
                rect.origin.y += rect.size.height - size.height
                rect.size = size
            case .left:
                rect.origin.y = center.y - size.height * 0.5
                rect.size = size
            case .right:
                rect.origin.y = center.y - size.height * 0.5
                rect.origin.x += rect.size.width - size.width
                rect.size = size
            case .topLeft:
                rect.size = size
            case .topRight:
                rect.origin.x += rect.size.width - size.width
                rect.size = size
            case .bottomLeft:
                rect.origin.y += rect.size.height - size.height
                rect.size = size
            case .bottomRight:
                rect.origin.x += rect.size.width - size.width
                rect.origin.y += rect.size.height - size.height
                rect.size = size
            default:
                break
            }
            return rect
        }
        let rect = modeRect(with: mode, size: self.size, rect: rect)
        if rect.width == 0 || rect.height == 0 {
            return
        }
        draw(in: rect)
    }

}

// MARK: - Resize
extension UIImage {
    
    func resize(isPortrait: Bool) -> UIImage? {
        if size == .zero {
            return self
        }
        let targetSize: CGSize = {
            let w = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            let h = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            return isPortrait ? CGSize(width: w, height: h) : CGSize(width: h, height: w)
        }()
        
        let image = scaled(to: UIScreen.main.scale)
        if image.size == targetSize {
            return self
        }
        return image.resize(to: targetSize, content: .scaleAspectFill)
    }
    
    /// ll_imageByResizeToSize
    func resize(to size: CGSize, content mode: UIView.ContentMode) -> UIImage? {
        if size.width <= 0 || size.height <= 0 {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(size, self.launchOpaque, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size), content: mode)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIImage {
            
    /// ll_isEqualToImage:(UIImage *)image ignoreAlpha:(BOOL)ignore threshold:(CGFloat)threshold
    func thresholdEqual(to image: UIImage, ignoreAlpha: Bool = false, threshold: CGFloat = 0.9) -> Bool {
        guard let ciImage1 = CIImage(image: self), let ciImage2 = CIImage(image: image) else { return false }
        guard !self.size.equalTo(.zero), !image.size.equalTo(.zero) else { return false }
        
        var image1 = self
        var image2 = image
        
        let size1 = image1.size
        let size2 = image2.size
        
        // 如果尺寸不一样，把大图调整成小图尺寸。
        if size1 != size2 {
            let isPortrait1 = image1.size.width < image1.size.height
            let isPortrait2 = image2.size.width < image2.size.height
            
            // 判断图片比例是否一样，如果1张是竖图，另1张是横图的话则直接返回。
            guard isPortrait1 == isPortrait2 else { return false }
            
            let scale1 = size1.width * size1.height
            let scale2 = size2.width * size2.height
            
            if scale1 > scale2 {
                image1 = self.scaled(to: 1.0)
                image2 = image.resize(to: size1, content: .scaleToFill) ?? image
            } else {
                image1 = self.resize(to: size2, content: .scaleToFill) ?? self
                image2 = image.scaled(to: 1.0)
            }
        }
                
        let context = CIContext()
        
        // 获取图片像素数据。
        let imageExtent = ciImage1.extent
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * Int(imageExtent.size.width)
        let totalBytes  = bytesPerRow * Int(imageExtent.size.height)
        
        let image1Data = UnsafeMutablePointer<UInt8>.allocate(capacity: totalBytes)
        let image2Data = UnsafeMutablePointer<UInt8>.allocate(capacity: totalBytes)
        
        context.render(ciImage1, toBitmap: image1Data, rowBytes: bytesPerRow, bounds: imageExtent, format: .RGBA8, colorSpace: nil)
        context.render(ciImage2, toBitmap: image2Data, rowBytes: bytesPerRow, bounds: imageExtent, format: .RGBA8, colorSpace: nil)
        
        // 计算两张图片的相似度。
        var ignoreCount = 0
        var samePixelCount = 0
        for i in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
            let r1 = image1Data[i]
            let g1 = image1Data[i+1]
            let b1 = image1Data[i+2]
            let a1 = image1Data[i+3]
            
            let r2 = image2Data[i]
            let g2 = image2Data[i+1]
            let b2 = image2Data[i+2]
            let a2 = image2Data[i+3]
            
            if ignoreAlpha {
                // 忽略带透明的像素点。
                if a1 != 0xff || a2 != 0xff {
                    ignoreCount += 1
                    continue
                }
            }
            
            let color1 = LaunchColor(r: CGFloat(r1) / 255.0, g: CGFloat(g1) / 255.0, b: CGFloat(b1) / 255.0, a: CGFloat(a1) / 255.0)
            let color2 = LaunchColor(r: CGFloat(r2) / 255.0, g: CGFloat(g2) / 255.0, b: CGFloat(b2) / 255.0, a: CGFloat(a2) / 255.0)
            if LaunchColor.thresholdEqual(color1, color2, threshold: threshold) {
                samePixelCount += 1
            }
        }
        
        let similarity = CGFloat(samePixelCount) / (CGFloat(totalBytes) / CGFloat(bytesPerPixel) - CGFloat(ignoreCount))
        image1Data.deallocate()
        image2Data.deallocate()
        return (similarity >= threshold)
    }
    
    /// ll_CGRectWithContentMode:(UIViewContentMode)mode viewSize:(CGSize)viewSize clipsToBounds:(BOOL)clips
    func rect(with mode: UIView.ContentMode, in targetSize: CGSize, clipsToBounds clips: Bool) -> CGRect {
        let imageSize = self.size
        var contentRect = CGRect(origin: .zero, size: targetSize)

        switch mode {
        case .scaleAspectFit, .scaleAspectFill:
            let scale = min(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
            let width = imageSize.width * scale
            let height = imageSize.height * scale
            contentRect.size = CGSize(width: width, height: height)
            switch mode {
            case .scaleAspectFit:
                contentRect.origin = CGPoint(x: (targetSize.width - width) / 2.0, y: (targetSize.height - height) / 2.0)
            case .scaleAspectFill:
                contentRect.origin = CGPoint(x: (targetSize.width - width) / 2.0, y: (targetSize.height - height) / 2.0)
            default:
                break
            }
        case .center, .top, .bottom, .left, .right, .topLeft, .topRight, .bottomLeft, .bottomRight:
            switch mode {
            case .center:
                contentRect.origin = CGPoint(x: (targetSize.width - imageSize.width) / 2.0, y: (targetSize.height - imageSize.height) / 2.0)
            case .top:
                contentRect.origin = CGPoint(x: (targetSize.width - imageSize.width) / 2.0, y: 0)
            case .bottom:
                contentRect.origin = CGPoint(x: (targetSize.width - imageSize.width) / 2.0, y: targetSize.height - imageSize.height)
            case .left:
                contentRect.origin = CGPoint(x: 0, y: (targetSize.height - imageSize.height) / 2.0)
            case .right:
                contentRect.origin = CGPoint(x: targetSize.width - imageSize.width, y: (targetSize.height - imageSize.height) / 2.0)
            case .topLeft:
                contentRect.origin = .zero
            case .topRight:
                contentRect.origin = CGPoint(x: targetSize.width - imageSize.width, y: 0)
            case .bottomLeft:
                contentRect.origin = CGPoint(x: 0, y: targetSize.height - imageSize.height)
            case .bottomRight:
                contentRect.origin = CGPoint(x: targetSize.width - imageSize.width, y: targetSize.height - imageSize.height)
            default:
                break
            }
        default:
            break
        }
        if clips {
            contentRect = contentRect.intersection(CGRect(origin: .zero, size: targetSize))
        }
        return contentRect.integral
    }

    
}
