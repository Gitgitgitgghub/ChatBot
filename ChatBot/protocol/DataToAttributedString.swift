//
//  DataToAttributedString.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/7.
//

import Foundation
import UIKit

/// 自己定義的data與AttributedString轉換方式
protocol DataToAttributedString {
    
    var stringDocumentType: NSAttributedString.DocumentType { get }
    var attributedStringData: Data { get }
    
    func attributedString() -> NSAttributedString?
    
}

extension DataToAttributedString {
    
    func attributedString() -> NSAttributedString? {
        do {
            if stringDocumentType == .html {
                return replaceImageAttachmentsWithRemoteImages()
            }
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: attributedStringData)
        } catch {
            print("error: \(error)")
        }
        return nil
    }
    
    /// 將html string 轉成NSAttributedString並且替換掉裡面的ImageAttachment
    func replaceImageAttachmentsWithRemoteImages() -> NSAttributedString? {
        let htmlString = String(data: attributedStringData, encoding: .utf8) ?? ""
        guard let mutableAttributedString = NSMutableAttributedString(htmlString: htmlString) else { return nil }
        let imageUrls = extractImageSrcs(from: htmlString)
        guard imageUrls.isNotEmpty else { return mutableAttributedString }
        var i = 0
        mutableAttributedString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: mutableAttributedString.length), options: []) { (value, range, stop) in
            // 獲取圖片 URL (如果需要)
            if value is NSTextAttachment {
                if let urlString = imageUrls.getOrNil(index: i),
                   let imageURL = URL(string: urlString) {
                    // 創建新的 RemoteImageTextAttachment
                    let newAttachment = RemoteImageTextAttachment(imageURL: imageURL, displaySize: .init(width: UIScreen.main.bounds.width - 36, height: 210))
                    // 替換 attachment
                    mutableAttributedString.removeAttribute(.attachment, range: range)
                    mutableAttributedString.addAttribute(.attachment, value: newAttachment, range: range)
                    i += 1
                }
            }
        }
        return mutableAttributedString
    }
    
    /// 從html取出所有src
    func extractImageSrcs(from htmlString: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "<img[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"]", options: [])
        let matches = regex.matches(in: htmlString, range: NSRange(location: 0, length: htmlString.utf16.count))
        var srcs = [String]()
        for match in matches {
            let range = Range(match.range(at: 1), in: htmlString)!
            let src = String(htmlString[range])
            srcs.append(src)
        }
        return srcs
    }
}
