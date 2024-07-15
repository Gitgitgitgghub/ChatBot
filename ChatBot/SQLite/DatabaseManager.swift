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
            
            try dbQueue.write { db in
                try db.create(table: ChatRoom.databaseTableName, ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("lastUpdate", .datetime)
                }
                try db.create(table: ChatMessage.databaseTableName, ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("message", .text)
                    t.column("timestamp", .datetime)
                    t.column("type", .integer)
                    t.column("role", .text)
                    t.column("chatRoomId", .text).references(ChatRoom.databaseTableName, onDelete: .cascade)
                }
            }
        } catch {
            print("Error creating database: \(error)")
        }
    }
    
    func saveChatRoom(_ chatRoom: ChatRoom, messages: [ChatMessage]) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try self.dbQueue.write { db in
                    try chatRoom.save(db)
                    for message in messages {
                        try message.save(db)
                    }
                }
                promise(.success(()))
            } catch {
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
                    for chatRoom in chatRooms {
                        let messages = try ChatMessage.fetchAll(db, sql: "SELECT * FROM messages WHERE chatRoomId = ? ORDER BY timestamp ASC", arguments: [chatRoom.id])
                        //chatRoom.messages = messages
                    }
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

