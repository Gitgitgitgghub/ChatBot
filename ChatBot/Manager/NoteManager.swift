//
//  NoteManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/16.
//

import Foundation
import Combine

class NoteManager {
    
    static let shared = NoteManager()
    let dbQueue = DatabaseManager.shared.dbQueue!
    private init() {}
    
    
    /// 保存筆記
    func saveNote(_ note: MyNote, comments: [MyComment]) -> AnyPublisher<Void, Error> {
        dbQueue.writePublisher(receiveOn: RunLoop.main) { db in
            note.lastUpdate = .now
            try note.save(db)
            for comment in comments {
                comment.myNotesId = note.id!
                try comment.save(db)
            }
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
    /// 讀取所有聊天室資料
    func fetchMyNotes() -> AnyPublisher<[MyNote], Error> {
        dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            return try MyNote.fetchAll(db, sql: "SELECT * FROM \(MyNote.databaseTableName) ORDER BY lastUpdate DESC")
        }
        .eraseToAnyPublisher()
    }
    
    /// 刪除特定的筆記
    func deleteMyNote(byID id: Int64) -> AnyPublisher<Void, Error> {
        dbQueue.writePublisher(receiveOn: RunLoop.main) { db in
            try MyNote.deleteOne(db, key: id)
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
}
