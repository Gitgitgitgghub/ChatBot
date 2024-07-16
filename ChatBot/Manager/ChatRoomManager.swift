//
//  ChatRoomManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/16.
//

import Foundation
import Combine

class ChatRoomManager {
    
    static let shared = ChatRoomManager()
    let dbQueue = DatabaseManager.shared.dbQueue!
    private init() {}
    
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
