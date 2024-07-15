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
            try migrator.migrate(dbQueue)
            print("🟢創建ＤＢ成功")
        } catch {
            print("🔴創建ＤＢ失敗: \(error)")
        }
    }
    
    //TODO: - 如果聊天室已經存在不應該創建新的
    func saveChatRoom(_ chatRoom: ChatRoom, messages: [ChatMessage]) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try self.dbQueue.write { db in
                    try chatRoom.insert(db)
                    for message in messages {
                        //注意這邊chatRoom insert後會有id他是ChatMessage的chatRoomsId一定要給不然會錯誤
                        message.chatRoomsId = chatRoom.id!
                        try message.insert(db)
                    }
                }
                print("🟢saveChatRoom success \(chatRoom.id ?? -1)")
                promise(.success(()))
            } catch {
                print("🔴saveChatRoom error: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchChatRooms() -> AnyPublisher<[ChatRoom], Error> {
        Future { promise in
            do {
                let chatRooms = try self.dbQueue.read { db in
                    let chatRooms = try ChatRoom.fetchAll(db, sql: "SELECT * FROM chatRooms ORDER BY lastUpdate DESC")
                    return chatRooms
                }
                promise(.success(chatRooms))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteChatRoom(byID id: String) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try self.dbQueue.write { db in
                    _ = try ChatRoom.deleteOne(db, key: id)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAllChatRooms() -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try self.dbQueue.write { db in
                    let _ = try ChatRoom.deleteAll(db)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

