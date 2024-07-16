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
    
}

