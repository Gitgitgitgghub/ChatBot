//
//  MyChatRoomManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/6.
//

import Foundation
import CoreData
import Combine

class MyChatRoomManager {
    
    static let shared = MyChatRoomManager()
    
    private init(){}

    func saveChatMessage(chatRoom: MyChatRoom, messages: [ChatMessage]) -> AnyPublisher<Void, Error>{
        return Future<Void, Error> { promise in
            DispatchQueue.global().async {
                guard !messages.isEmpty else { return }
                guard let context = chatRoom.managedObjectContext else { 
                    promise(.success(()))
                    return }
                chatRoom.messages = NSSet(array: messages)
                chatRoom.lastUpdate = messages.last?.timestamp ?? .now
                do {
                    if context.hasChanges {
                        try context.save()
                    }
                    promise(.success(()))
                }catch {
                    print("保存訊息失敗：\(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 刪除聊天室
    func deleteChatRoom(id: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            DispatchQueue.global().async {
                let context = CoreDataStack.shared.viewContext
                let fetchRequest: NSFetchRequest<MyChatRoom> = MyChatRoom.fetchRequest()
                fetchRequest.predicate = .init(format: "id == %@", id)
                do {
                    let chatRooms = try context.fetch(fetchRequest)
                    for chatRoom in chatRooms {
                        context.delete(chatRoom)
                    }
                    if context.hasChanges {
                        try context.save()
                    }
                    promise(.success(()))
                }catch {
                    print("刪除聊天室失敗：\(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 刪除所有聊天室
    func deleteAllChatRoom() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            DispatchQueue.global().async {
                let context = CoreDataStack.shared.viewContext
                let fetchRequest: NSFetchRequest<MyChatRoom> = MyChatRoom.fetchRequest()
                do {
                    let chatRooms = try context.fetch(fetchRequest)
                    for chatRoom in chatRooms {
                        context.delete(chatRoom)
                    }
                    if context.hasChanges {
                        try context.save()
                    }
                    promise(.success(()))
                }catch {
                    print("刪除聊天室失敗：\(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 创建一个新的ChatRoom对象
    func createChatRoom() -> MyChatRoom {
        let context = CoreDataStack.shared.viewContext
        let chatRoom = MyChatRoom(context: context)
        chatRoom.id = UUID().uuidString
        print("創建新聊天室成功 id：\(chatRoom.id ?? "")")
        return chatRoom
    }

    // 检索所有 ChatRoom 对象
    func fetchAllChatRooms() -> AnyPublisher<[MyChatRoom], Error> {
        return Future<[MyChatRoom], Error> { promise in
            DispatchQueue.global().async {
                let context = CoreDataStack.shared.viewContext
                let fetchRequest: NSFetchRequest<MyChatRoom> = MyChatRoom.fetchRequest()
                /// 對lastUpdate做降冪排序
                fetchRequest.sortDescriptors = [.init(key: "lastUpdate", ascending: false)]
                do {
                    let chatRooms = try context.fetch(fetchRequest)
                    promise(.success(chatRooms))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
