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
    
    /// 取消載入WebAttachmentImage 圖片
    func cancelDownloadTask() {
        guard let attributedText = self.attributedText else { return }
        attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length), options: []) { (value, range, _) in
            if let attachment = value as? WebImageAttachment {
                attachment.cancelDownloadTask()
            }
        }
    }
    
    /// 載入WebAttachmentImage 圖片
    func asyncLoadWebAttachmentImage() {
        guard let attributedText = self.attributedText else { return }
        attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length), options: []) { (value, range, _) in
            if let attachment = value as? WebImageAttachment {
                attachment.cancelDownloadTask()
                attachment.setImage(placeholder: nil) { [weak self] in
                    self?.layoutManager.invalidateDisplay(forGlyphRange: range)
                }
            }
        }
    }
    
}


