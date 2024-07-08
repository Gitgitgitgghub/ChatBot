//
//  ChatMessage+CoreDataClass.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/6.
//
//

import Foundation
import CoreData
import OpenAI
import UIKit

@objc(ChatMessage)
public class ChatMessage: NSManagedObject {
    enum MessageType: Int16 {
        case mock, message
    }
    public typealias Role = ChatQuery.ChatCompletionMessageParam.Role
//    @NSManaged private var messageTypeRawValue: Int16
//    @NSManaged private var roleRawValue: String
}

extension ChatMessage {
    
    var messageType: MessageType {
        set {
            messageTypeRawValue = newValue.rawValue
        }
        get {
            return .init(rawValue: messageTypeRawValue) ?? .message
        }
    }
    var role: Role {
        set {
            roleRawValue = newValue.rawValue
        }
        get {
            return .init(rawValue: roleRawValue ?? "system") ?? .system
        }
    }
    
    static func createNewMessage(content: String, role: Role, messageType: MessageType) -> ChatMessage? {
        let context = CoreDataStack.shared.viewContext
            if let entityDescription = NSEntityDescription.entity(forEntityName: "ChatMessage", in: context) {
                let newMessage = ChatMessage(entity: entityDescription, insertInto: context)
                newMessage.uuid = UUID().uuidString
                newMessage.message = content
                newMessage.role = role
                newMessage.messageType = messageType
                return newMessage
            }
            return nil
        }
}
