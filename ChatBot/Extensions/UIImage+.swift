//
//  UIImage+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/20.
//

import Foundation
import UIKit


extension UIImage {
    
    /// 重新繪製圖片尺寸
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    
    func resizeToFit(maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let aspectWidth = maxWidth / self.size.width
        let aspectHeight = maxHeight / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        let newSize = CGSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// 壓縮圖片至小於Ｘ ＭＢ
    func compressLessThanXMB(mb: Int) throws -> UIImage {
        guard var pngData = pngData() else { throw NSError() }
        var resizedImage = self
        let maxFileSize: Int = mb * 1024 * 1024
        var imageSizeInBytes = pngData.count
        var targetSize = size
        // Adjust the size to fit within 4MB
        while imageSizeInBytes > maxFileSize {
            targetSize = CGSize(width: targetSize.width * 0.9, height: targetSize.height * 0.9)
            if let resized = resizeImage(self, targetSize: targetSize), let resizedData = resized.pngData() {
                resizedImage = resized
                pngData = resizedData
                imageSizeInBytes = pngData.count
            } else {
                throw NSError()
            }
        }
        return resizedImage
    }
    
}
