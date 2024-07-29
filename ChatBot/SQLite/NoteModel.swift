//
//  NoteModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/16.
//

import Foundation
import GRDB
import UIKit
import ZMarkupParser
import ZNSTextAttachment

class MyNote: Codable, FetchableRecord, PersistableRecord {
    
    var id: Int64?
    var lastUpdate: Date
    var title: String
    var attributedStringData: Data
    var documentType: String
    var comments: [MyComment] = []
    
    
    init(id: Int64? = nil, title: String, lastUpdate: Date, attributedStringData: Data, documentType: String) {
        self.id = id
        self.title = title
        self.lastUpdate = lastUpdate
        self.attributedStringData = attributedStringData
        self.documentType = documentType
    }
    
    init(title: String, attributedString: NSAttributedString) throws {
        self.title = title
        self.lastUpdate = .now
        let documentType: NSAttributedString.DocumentType = attributedString.containsAttachments(in: NSRange.init(location: 0, length: attributedString.length)) ? .rtfd : .rtf
        self.documentType = documentType.rawValue
        self.attributedStringData = try attributedString.data(from: NSRange(location: 0, length: attributedString.length), documentAttributes: [.documentType: documentType, .characterEncoding: String.Encoding.utf8.rawValue])
    }
    
    init(title: String, htmlString: NSAttributedString) throws {
        self.title = title
        self.lastUpdate = .now
        let documentType: NSAttributedString.DocumentType = .html
        self.documentType = documentType.rawValue
        self.attributedStringData = try htmlString.data(from: NSRange(location: 0, length: htmlString.length), documentAttributes: [.documentType: documentType, .characterEncoding: String.Encoding.utf8.rawValue])
    }
    
    init?(title: String, htmlString: String) {
        self.title = title
        self.lastUpdate = .now
        let documentType: NSAttributedString.DocumentType = .html
        self.documentType = documentType.rawValue
        guard let data = htmlString.data(using: .utf8) else {
            print("Failed to convert HTML string to Data")
            return nil
        }
        self.attributedStringData = data
    }
    
    func setAttributedString(htmlString: String) {
        self.lastUpdate = .now
        let documentType: NSAttributedString.DocumentType = .html
        self.documentType = documentType.rawValue
        guard let data = htmlString.data(using: .utf8) else {
            print("Failed to convert HTML string to Data")
            return
        }
        self.attributedStringData = data
    }
    
    func setAttributedString(attr: NSAttributedString, documentType: NSAttributedString.DocumentType? = nil) {
        do {
            let documentType: NSAttributedString.DocumentType = documentType ?? .init(rawValue: self.documentType)
            self.attributedStringData = try attr.data(from: NSRange(location: 0, length: attr.length), documentAttributes: [.documentType: documentType, .characterEncoding: String.Encoding.utf8.rawValue])
        }catch {
            print("setAttributedString error: \(error.localizedDescription)")
        }
    }
    
    func attributedString() -> NSAttributedString? {
        do {
            return try NSAttributedString(data: attributedStringData, options: [.documentType: self.documentType, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print("Error unarchiving attributed string: \(error)")
            return nil
        }
    }
    
    func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case lastUpdate
        case title
        case attributedStringData
        case documentType
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(lastUpdate, forKey: .lastUpdate)
        try container.encode(attributedStringData, forKey: .attributedStringData)
        try container.encode(documentType, forKey: .documentType)
    }
}

extension MyNote {
    /// tableName
    static let databaseTableName = "myNotes"
    static let comments = hasMany(MyComment.self)
    var commentsRequest: QueryInterfaceRequest<MyComment> {
        request(for: MyNote.comments)
    }
}

class MyComment: Codable, FetchableRecord, PersistableRecord {
    
    var id: Int64?
    var myNotesId: Int64 = 0
    var lastUpdate: Date
    var attributedStringData: Data
    var documentType: String
    
    init(id: Int64? = nil, myNoteId: Int64, lastUpdate: Date, attributedStringData: Data, documentType: String) {
        self.id = id
        self.myNotesId = myNoteId
        self.lastUpdate = lastUpdate
        self.attributedStringData = attributedStringData
        self.documentType = documentType
    }
    
    init(attributedString: NSAttributedString) throws {
        self.lastUpdate = .now
        let documentType: NSAttributedString.DocumentType = attributedString.containsAttachments(in: NSRange.init(location: 0, length: attributedString.length)) ? .rtfd : .rtf
        self.documentType = documentType.rawValue
        self.attributedStringData = try attributedString.data(from: NSRange(location: 0, length: attributedString.length), documentAttributes: [.documentType: documentType, .characterEncoding: String.Encoding.utf8.rawValue])
    }
    
    init(htmlString: NSAttributedString) throws {
        self.lastUpdate = .now
        let documentType: NSAttributedString.DocumentType = .html
        self.documentType = documentType.rawValue
        self.attributedStringData = try htmlString.data(from: NSRange(location: 0, length: htmlString.length), documentAttributes: [.documentType: documentType, .characterEncoding: String.Encoding.utf8.rawValue])
    }
    
    init?(htmlString: String) {
        self.lastUpdate = .now
        let documentType: NSAttributedString.DocumentType = .html
        self.documentType = documentType.rawValue
        guard let data = htmlString.data(using: .utf8) else {
            print("Failed to convert HTML string to Data")
            return nil
        }
        self.attributedStringData = data
    }
    
    func setAttributedString(htmlString: String) {
        self.lastUpdate = .now
        let documentType: NSAttributedString.DocumentType = .html
        self.documentType = documentType.rawValue
        guard let data = htmlString.data(using: .utf8) else {
            print("Failed to convert HTML string to Data")
            return
        }
        self.attributedStringData = data
    }
    
    func setAttributedString(attr: NSAttributedString, documentType: NSAttributedString.DocumentType? = nil) {
        do {
            let documentType: NSAttributedString.DocumentType = documentType ?? .init(rawValue: self.documentType)
            self.attributedStringData = try attr.data(from: NSRange(location: 0, length: attr.length), documentAttributes: [.documentType: documentType, .characterEncoding: String.Encoding.utf8.rawValue])
        }catch {
            print("setAttributedString error: \(error.localizedDescription)")
        }
    }
    
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
    
    //TODO: - 暫時寫這樣看起來還是得做catch
    func attributedString() -> NSAttributedString? {
        // 定义 HTML 转换的选项
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let htmlString = String(data: attributedStringData, encoding: .utf8) ?? ""
        let parser = ZHTMLParserBuilder.initWithDefault().build()
        let mutableAttributedString = parser.render(htmlString, forceDecodeHTMLEntities: false) as! NSMutableAttributedString
        let imageUrls = extractImageSrcs(from: htmlString)
        guard imageUrls.isNotEmpty else { return mutableAttributedString }
        var i = 0
        mutableAttributedString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: mutableAttributedString.length), options: []) { (value, range, stop) in
            // 獲取圖片 URL (如果需要)
            if value is NSTextAttachment {
                if let urlString = imageUrls.getOrNil(index: i),
                   let imageURL = URL(string: urlString),
                   let newImageUrl = ImageManager.shared.replaceDirectoryInURL(originalURL: imageURL){
                    // 創建新的 RemoteImageTextAttachment
                    let newAttachment = RemoteImageTextAttachment(imageURL: newImageUrl, displaySize: .init(width: 300, height: 210))
                    newAttachment.bounds = CGRect(x: 0, y: 0, width: 300, height: 210)
                    // 替換 attachment
                    mutableAttributedString.removeAttribute(.attachment, range: range)
                    mutableAttributedString.addAttribute(.attachment, value: newAttachment, range: range)
                    i += 1
                }
            }
        }
        return mutableAttributedString
    }
    ///required init(row: Row)
    ///encode(to container: inout PersistenceContainer)兩個方法因為遵從codable可以不用實作，但是如果要新增不再row的變數就要實作告訴他怎麼初始化
    
    func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension MyComment {
    /// tableName
    static let databaseTableName = "myComments"
    static let myNote = belongsTo(MyNote.self)
    var myNote: QueryInterfaceRequest<MyNote> {
        request(for: MyComment.myNote)
    }
}
