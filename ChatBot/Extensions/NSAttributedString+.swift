//
//  NSAttributedString+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/28.
//

import Foundation
import UIKit

extension NSAttributedString {
    
    /// 取得NSAttributedString 顯示的預估高度
    func estimatedHeightForAttributedString(width: CGFloat = SystemDefine.Message.maxWidth) -> CGFloat {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let boundingRect = self.boundingRect(with: size, options: options, context: nil)
        // +16的原因是因為 textView有預設 textContainerInset 上下各８不加會顯示不完全
        let estimatedHeight = ceil(boundingRect.height) + 16
        return estimatedHeight
    }
    
    func toHTML() -> String? {
        let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
        ]
        
        do {
            let htmlData = try self.data(from: NSRange(location: 0, length: self.length), documentAttributes: documentAttributes)
            return String(data: htmlData, encoding: .utf8)
        } catch {
            print("Error converting NSAttributedString to HTML: \(error)")
            return nil
        }
    }
    
}
