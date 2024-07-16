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
    var attributedStringData: Data
    
    init(id: Int64? = nil, lastUpdate: Date, attributedStringData: Data) {
        self.id = id
        self.lastUpdate = lastUpdate
        self.attributedStringData = attributedStringData
    }
    
    init(attributedString: NSAttributedString) throws {
        self.lastUpdate = .now
        self.attributedStringData = try NSKeyedArchiver.archivedData(withRootObject: attributedString, requiringSecureCoding: true)
    }
    
    func attributedString() -> NSAttributedString? {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: attributedStringData)
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
    
    init(id: Int64? = nil, myNoteId: Int64, lastUpdate: Date, attributedStringData: Data) {
        self.id = id
        self.myNotesId = myNoteId
        self.lastUpdate = lastUpdate
        self.attributedStringData = attributedStringData
    }
    
    init(attributedString: NSAttributedString) throws {
        self.lastUpdate = .now
        self.attributedStringData = try NSKeyedArchiver.archivedData(withRootObject: attributedString, requiringSecureCoding: true)
    }
    
    ///required init(row: Row)
    ///encode(to container: inout PersistenceContainer)兩個方法因為遵從codable可以不用實作，但是如果要新增不再row的變數就要實作告訴他怎麼初始化
    
    func attributedString() -> NSAttributedString? {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: attributedStringData)
        } catch {
            print("Error unarchiving attributed string: \(error)")
            return nil
        }
    }
    
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