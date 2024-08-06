//
//  NSAttributedString+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/28.
//

import Foundation
import UIKit


extension NSMutableAttributedString {
    
    convenience init?(htmlStringData: Data) {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let attributedString = try? NSMutableAttributedString(data: htmlStringData, options: options, documentAttributes: nil)
        if let attributedString = attributedString?.convertPx2Px() {
            self.init(attributedString: attributedString)
        }else {
            return nil
        }
    }
    
    convenience init?(htmlString: String) {
        guard let data = htmlString.data(using: .utf8) else {
            return nil
        }
        self.init(htmlStringData: data)
    }
    
    private func convertPx2Px() -> NSMutableAttributedString {
        enumerateAttribute(.font, in: NSMakeRange(0, self.length), options: .init(rawValue: 0)) {
            (value, range, stop) in
            if let font = value as? UIFont {
                let resizedFont = font.withSize(font.pointSize * 1.33)
                addAttribute(.font, value: resizedFont, range: range)
            }
        }
        return self
    }
    
}

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
    
    func encodeToData() throws -> Data  {
        return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
    }
    
}
