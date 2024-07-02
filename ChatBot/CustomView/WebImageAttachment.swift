//
//  WebImageAttachment.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/28.
//

import Foundation
import UIKit
import SDWebImage

class WebImageAttachment: NSTextAttachment {
    var imageUrl: URL?
    var downloadTask: SDWebImageOperation?
    var isDownloadSuccess = false
}

extension WebImageAttachment {
    
    /// 取消下載任務
    func cancelDownloadTask() {
        downloadTask?.cancel()
        downloadTask = nil
    }
    
    func loadImage(placeholder: UIImage?, maxSize: CGSize = .init(width: 300, height: 210), completion: @escaping ((UIImage) -> Void)) {
        self.image = placeholder
        guard let url = imageUrl else { return }
        downloadTask = SDWebImageManager.shared.loadImage(
            with: url,
            options: [.highPriority],
            progress: nil) { [weak self] image, data, error, cacheType, finished, imageUrl in
                guard let self = self else { return }
                if let image = image, error == nil {
                    let resizeImage = image.resizeToFit(maxWidth: maxSize.width, maxHeight: maxSize.height)
                    DispatchQueue.main.async {
                        self.image = resizeImage
                        self.bounds = .init(origin: .zero, size: resizeImage.size)
                        self.isDownloadSuccess = true
                        completion(resizeImage)
                        self.cancelDownloadTask()
                    }
                } else {
                    print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
    }
    
    ///使用 SDWebImage 异步下载图片
    func setImage(placeholder: UIImage?, maxSize: CGSize = .init(width: 300, height: 210), completion: (() -> Void)? = nil) {
        self.image = placeholder
        guard let url = imageUrl else { return }
        downloadTask = SDWebImageManager.shared.loadImage(
            with: url,
            options: [.highPriority],
            progress: nil) { [weak self] image, data, error, cacheType, finished, imageUrl in
                guard let self = self else { return }
                if let image = image, error == nil {
                    let resizeImage = image.resizeToFit(maxWidth: maxSize.width, maxHeight: maxSize.height)
                    DispatchQueue.main.async {
                        self.image = resizeImage
                        self.bounds = .init(origin: .zero, size: resizeImage.size)
                        self.isDownloadSuccess = true
                        completion?()
                        self.cancelDownloadTask()
                    }
                } else {
                    print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
    }
}
