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
}