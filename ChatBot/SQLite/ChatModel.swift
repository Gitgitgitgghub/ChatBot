//
//  ChatModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/12.
//

import GRDB
import Foundation
import OpenAI

class ChatMessage: Codable, FetchableRecord, PersistableRecord {
    
    enum MessageType: Int, Codable {
        case mock, message
    }
    typealias Role = ChatQuery.ChatCompletionMessageParam.Role
    
    var id: String
    var message: String
    var timestamp: Date
    var type: MessageType
    var role: Role
    var chatRoomId: String
    static let chatRoom = belongsTo(ChatRoom.self)
    var chatRoom: QueryInterfaceRequest<ChatRoom> {
        request(for: ChatMessage.chatRoom)
    }
    
    init(id: String = UUID().uuidString, message: String, timestamp: Date, type: MessageType, role: Role, chatRoomId: String) {
        self.id = id
        self.message = message
        self.timestamp = timestamp
        self.type = type
        self.role = role
        self.chatRoomId = chatRoomId
    }
    
    init(message: String, type: MessageType, role: Role, chatRoomId: String) {
        self.id = UUID().uuidString
        self.message = message
        self.timestamp = Date()
        self.type = type
        self.role = role
        self.chatRoomId = chatRoomId
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let message = Column(CodingKeys.message)
        static let timestamp = Column(CodingKeys.timestamp)
        static let type = Column(CodingKeys.type)
        static let role = Column(CodingKeys.role)
        static let chatRoomId = Column(CodingKeys.chatRoomId)
    }
    
    static let databaseTableName = "messages"
}

/// 簡易轉換
extension Array where Element: ChatMessage {
    
    func toChatCompletionMessageParam() -> [ChatQuery.ChatCompletionMessageParam] {
        return self.compactMap({ .init(role: $0.role, content: $0.message) })
    }
    
}


//TODO: - ChatRoom ChatMessage 關聯處理是否能優化一點
class ChatRoom: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var lastUpdate: Date
    //var messages: [ChatMessage]
    static let messages = hasMany(ChatMessage.self)
    var messages: QueryInterfaceRequest<ChatMessage> {
        request(for: ChatRoom.messages)
    }
    
    init(id: String, lastUpdate: Date, messages: [ChatMessage]) {
        self.id = id
        self.lastUpdate = lastUpdate
    }
    
    enum Columns: String, ColumnExpression {
        case id, lastUpdate
    }
    
    static let databaseTableName = "chatRooms"
}

