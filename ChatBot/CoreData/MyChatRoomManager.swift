//
//  MyChatRoomManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/6.
//

import Foundation
import CoreData

class MyChatRoomManager {

    // 创建一个新的 ChatRoom 对象
    func createChatRoom(messages: [ChatMessage]) throws {
        do {
            let context = CoreDataStack.shared.viewContext
            let chatRoom = MyChatRoom(context: context)
            chatRoom.id = UUID().uuidString
            chatRoom.lastUpdate = .now
            chatRoom.messages = NSSet(array: messages)
            try CoreDataStack.shared.saveContext()
        }catch {
            throw error
        }
    }

    // 检索所有 ChatRoom 对象
    func fetchAllChatRooms() -> [MyChatRoom] {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<MyChatRoom> = MyChatRoom.fetchRequest()
        do {
            let chatRooms = try context.fetch(fetchRequest)
            return chatRooms
        } catch {
            print("Failed to fetch chat rooms: \(error)")
            return []
        }
    }
}
