//
//  UITextView+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/24.
//

import Foundation
import UIKit
import SDWebImage


extension UITextView {
    func updateHeight() {
        let size = self.sizeThatFits(CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
        if let heightConstraint = self.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.constant = size.height
        }
    }
}


extension NSTextAttachment {
    
    ///使用 SDWebImage 异步下载图片
    func setImage(from urlString: String, placeholder: UIImage?, maxSize: CGSize = .init(width: 300, height: 210), completion: (() -> Void)? = nil) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        //
        SDWebImageManager.shared.loadImage(
            with: url,
            options: .highPriority,
            progress: nil) { [weak self] image, data, error, cacheType, finished, imageUrl in
                guard let self = self else { return }
                if let image = image, error == nil {
                    let resizeImage = image.resizeToFit(maxWidth: maxSize.width, maxHeight: maxSize.height)
                    DispatchQueue.main.async {
                        self.image = resizeImage
                        self.bounds = .init(origin: .zero, size: resizeImage.size)
                        completion?()
                    }
                } else {
                    print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
    }
}
