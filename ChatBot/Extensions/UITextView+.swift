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
    
    func textRangeToNSRange(_ textRange: UITextRange) -> NSRange {
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
    
    /// 移動光標到最後方
    func moveCursorToEnd() {
        let endPosition = self.endOfDocument
        if let newTextRange = self.textRange(from: endPosition, to: endPosition) {
            self.selectedTextRange = newTextRange
        }
    }
    
    // 移動光標到指定位置
    func setCursorPosition(_ position: Int) {
        if position <= self.text.count {
            self.selectedRange = NSRange(location: position, length: 0)
        }
    }
    
    // 在光標當前位置插入换行符
    func insertNewLine() {
        if let selectedRange = self.selectedTextRange {
            self.replace(selectedRange, withText: "\n")
            if let newPosition = self.position(from: selectedRange.start, offset: 1) {
                self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
            }
        }
    }
    
}


