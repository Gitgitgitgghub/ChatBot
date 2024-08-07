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
    
    func setAttributedString(attr: NSAttributedString) {
        do {
            let documentType: NSAttributedString.DocumentType = .rtfd
            self.lastUpdate = .now
            self.attributedStringData = try attr.archivedData()
            self.documentType = documentType.rawValue
        }catch {
            print("setAttributedString error: \(error.localizedDescription)")
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

//MARK: - 我的筆記 initializer
extension MyNote {
    /// tableName
    static let databaseTableName = "myNotes"
    static let comments = hasMany(MyComment.self)
    var commentsRequest: QueryInterfaceRequest<MyComment> {
        request(for: MyNote.comments)
    }
    
    convenience init?(title: String, attributedString: NSAttributedString) {
        do {
            let documentType: NSAttributedString.DocumentType = attributedString.containsAttachments(in: NSRange.init(location: 0, length: attributedString.length)) ? .rtfd : .rtf
            let attributedStringData = try attributedString.archivedData()
            self.init(id: nil, title: title, lastUpdate: .now, attributedStringData: attributedStringData, documentType: documentType.rawValue)
        }catch {
            print("MyNote init error : \(error.localizedDescription)")
            return nil
        }
    }
    
    convenience init?(title: String, htmlString: NSAttributedString) {
        do {
            let documentType: NSAttributedString.DocumentType = .html
            let attributedStringData = try htmlString.data(from: NSRange(location: 0, length: htmlString.length), documentAttributes: [.documentType: documentType, .characterEncoding: String.Encoding.utf8.rawValue])
            self.init(id: nil, title: title, lastUpdate: .now, attributedStringData: attributedStringData, documentType: documentType.rawValue)
        }catch {
            print("MyNote init error : \(error.localizedDescription)")
            return nil
        }
    }
    
    convenience init?(title: String, htmlString: String) {
        let documentType: NSAttributedString.DocumentType = .html
        guard let data = htmlString.data(using: .utf8) else {
            print("MyNote init error: Failed to convert HTML string to Data")
            return nil
        }
        self.init(id: nil, title: title, lastUpdate: .now, attributedStringData: data, documentType: documentType.rawValue)
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
    
    func setAttributedString(attr: NSAttributedString) {
        do {
            let documentType: NSAttributedString.DocumentType = .rtfd
            self.lastUpdate = .now
            self.attributedStringData = try attr.archivedData()
            self.documentType = documentType.rawValue
        }catch {
            print("setAttributedString error: \(error.localizedDescription)")
        }
    }
    ///required init(row: Row)
    ///encode(to container: inout PersistenceContainer)兩個方法因為遵從codable可以不用實作，但是如果要新增不再row的變數就要實作告訴他怎麼初始化
    
    func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

//MARK: - 筆記評論 initializer
extension MyComment {
    /// tableName
    static let databaseTableName = "myComments"
    static let myNote = belongsTo(MyNote.self)
    var myNote: QueryInterfaceRequest<MyNote> {
        request(for: MyComment.myNote)
    }
    
    convenience init?(attributedString: NSAttributedString) {
        do {
            let documentType: NSAttributedString.DocumentType = attributedString.containsAttachments(in: NSRange.init(location: 0, length: attributedString.length)) ? .rtfd : .rtf
            let attributedStringData = try attributedString.archivedData()
            self.init(id: nil, myNoteId: 0, lastUpdate: .now, attributedStringData: attributedStringData, documentType: documentType.rawValue)
        }catch {
            print("MyComment init error: \(error.localizedDescription)")
            return nil
        }
    }
    
    convenience init?(htmlString: NSAttributedString) {
        do {
            let documentType: NSAttributedString.DocumentType = .html
            let attributedStringData = try htmlString.data(from: NSRange(location: 0, length: htmlString.length), documentAttributes: [.documentType: documentType, .characterEncoding: String.Encoding.utf8.rawValue])
            self.init(id: nil, myNoteId: 0, lastUpdate: .now, attributedStringData: attributedStringData, documentType: documentType.rawValue)
        }catch {
            print("MyComment init error: \(error.localizedDescription)")
            return nil
        }
    }
    
    convenience init?(htmlString: String) {
        let documentType: NSAttributedString.DocumentType = .html
        guard let data = htmlString.data(using: .utf8) else {
            print("MyComment init error: Failed to convert HTML string to Data")
            return nil
        }
        self.init(id: nil, myNoteId: 0, lastUpdate: .now, attributedStringData: data, documentType: documentType.rawValue)
    }
}

//MRRK: - confirm DataToAttributedString protocol
extension MyComment: DataToAttributedString {
    
    var stringDocumentType: NSAttributedString.DocumentType {
        return .init(self.documentType)
    }
}

extension MyNote: DataToAttributedString {
    
    var stringDocumentType: NSAttributedString.DocumentType {
        return .init(self.documentType)
    }
}


