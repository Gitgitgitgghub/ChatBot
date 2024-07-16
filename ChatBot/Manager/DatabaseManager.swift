//
//  DatabaseManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/12.
//

import Foundation
import GRDB
import Combine

class DatabaseManager {
    
    static let shared = DatabaseManager()
    var dbQueue: DatabaseQueue!
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let databaseURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("db.sqlite")
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            var migrator = DatabaseMigrator()
            // 創造聊天室和訊息的表
            migrator.registerMigration("createChatRooms") { db in
                try db.create(table: ChatRoom.databaseTableName, ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("lastUpdate", .datetime).notNull()
                }
                try db.create(table: ChatMessage.databaseTableName, ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("message", .text).notNull()
                    t.column("timestamp", .datetime).notNull()
                    t.column("type", .integer).notNull()
                    t.column("role", .text).notNull()
                    t.belongsTo(ChatRoom.databaseTableName, onDelete: .cascade).notNull()
                }
            }
            // 創造Note跟Comment的表
            migrator.registerMigration("createMyNotesAndComments") { db in
                try db.create(table: MyNote.databaseTableName, ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("lastUpdate", .datetime).notNull()
                    t.column("attributedStringData", .blob).notNull()
                }
                try db.create(table: MyComment.databaseTableName, ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("lastUpdate", .datetime).notNull()
                    t.column("attributedStringData", .blob).notNull()
                    t.belongsTo(MyNote.databaseTableName, onDelete: .cascade).notNull()
                }
            }
            try migrator.migrate(dbQueue)
            print("🟢創建ＤＢ成功")
        } catch {
            print("🔴創建ＤＢ失敗: \(error)")
        }
    }
    
    /// 保存聊天訊息
    func saveChatRoom(_ chatRoom: ChatRoom, messages: [ChatMessage]) -> AnyPublisher<Void, Error> {
        dbQueue.writePublisher(receiveOn: RunLoop.main) { db in
            // save結合了indert跟update如果主鍵不存在則insert反之update
            chatRoom.lastUpdate = .now
            try chatRoom.save(db)
            for message in messages {
                //注意這邊chatRoom insert後會有id他是ChatMessage的chatRoomsId一定要給不然會錯誤
                message.chatRoomsId = chatRoom.id!
                try message.save(db)
            }
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
    /// 讀取所有聊天室資料
    func fetchChatRooms() -> AnyPublisher<[ChatRoom], Error> {
        dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            return try ChatRoom.fetchAll(db, sql: "SELECT * FROM chatRooms ORDER BY lastUpdate DESC")
        }
        .eraseToAnyPublisher()
    }
    
    /// 刪除特定的聊天室
    func deleteChatRoom(byID id: Int64) -> AnyPublisher<Void, Error> {
        dbQueue.writePublisher(receiveOn: RunLoop.main) { db in
            try ChatRoom.deleteOne(db, key: id)
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
    /// 刪除所有聊天室
    func deleteAllChatRooms() -> AnyPublisher<Void, Error> {
        dbQueue.writePublisher { db in
            try ChatRoom.deleteAll(db)
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
}

