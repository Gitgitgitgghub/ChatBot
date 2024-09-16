//
//  ChatModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/12.
//

import GRDB
import Foundation
import OpenAI
import GoogleGenerativeAI

class ChatMessage: Codable, FetchableRecord, PersistableRecord {
    
    //typealias Role = ChatQuery.ChatCompletionMessageParam.Role
    enum MessageType: Int, Codable {
        case mock, message
    }
    
    enum Role: Codable {
        
        case ai(String)
        case user
        case unknown(String)
        
        var rawValue: String {
            switch self {
            case .ai(let value):
                return value
            case .user:
                return "user"
            case .unknown(let value):
                return value
            }
        }
        
        init(rawValue: String) {
            switch rawValue {
            case "assistant", "model":
                self = .ai(rawValue)
            case "user":
                self = .user
            default:
                self = .unknown(rawValue)
            }
        }
    }
    
    /// id由資料庫自動產生所以是optional
    var id: Int64?
    /// 訊息的聊天室id (注意這邊命名規則有要求)
    /// 定義 static let chatRoom = belongsTo(ChatRoom.self)
    /// 所以欄位名稱為 ChatRoom的tableName + "Id"
    var chatRoomsId: Int64 = 0
    var timestamp: Date = .now
    var type: MessageType = .message
    var message: String
    var role: Role
    
    init(id: Int64? = nil, chatRoomsId: Int64, timestamp: Date, type: MessageType, message: String, role: Role) {
        self.id = id
        self.chatRoomsId = chatRoomsId
        self.timestamp = timestamp
        self.type = type
        self.message = message
        self.role = role
    }
    
    init(message: String, role: Role) {
        self.message = message
        self.role = role
    }
    
    /// 插入成功後會有一個id，要手動把inserted.rowID指定給self.id
    func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    static let databaseTableName = "messages"
}

//MARK: - 定義 ChatMessage 關聯
extension ChatMessage {
    static let chatRoom = belongsTo(ChatRoom.self)
    var chatRoom: QueryInterfaceRequest<ChatRoom> {
        request(for: ChatMessage.chatRoom)
    }
}

/// 簡易轉換
extension Array where Element: ChatMessage {
    
    func toChatCompletionMessageParam() -> [ChatQuery.ChatCompletionMessageParam] {
        return self.compactMap({ .init(role: .init(rawValue: $0.role.rawValue) ?? .assistant, content: $0.message) })
    }
    
    func toGeminiModelContent() -> [ModelContent] {
        return self.compactMap({ .init(role: $0.role.rawValue, [$0.message]) })
    }
    
}


//TODO: - ChatRoom,ChatMessage關聯處理，讀取是否能優化一點
class ChatRoom: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var lastUpdate: Date
    //var messages: [ChatMessage]
    
    
    init(id: Int64? = nil, lastUpdate: Date) {
        self.id = id
        self.lastUpdate = lastUpdate
    }
    
    func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
        print("ChatRoom didInsert id: \(inserted.rowID)")
    }
    
    static let databaseTableName = "chatRooms"
}

//MARK: -定義 ChatRoom 關聯
extension ChatRoom {
    static let messages = hasMany(ChatMessage.self)
    var messages: QueryInterfaceRequest<ChatMessage> {
        request(for: ChatRoom.messages)
    }
}

