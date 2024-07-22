//
//  NoteModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/16.
//

import Foundation
import GRDB

class MyNote: Codable, FetchableRecord, PersistableRecord {
    
    var id: Int64?
    var lastUpdate: Date
    var title: String
    var attributedStringData: Data
    var documentType: String
    
    
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
}

extension MyNote {
    /// tableName
    static let databaseTableName = "myNotes"
    static let comments = hasMany(MyComment.self)
    var comments: QueryInterfaceRequest<MyComment> {
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
