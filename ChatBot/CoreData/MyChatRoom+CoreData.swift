//
//  MyChatRoom+CoreData.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/6.
//
//

import Foundation
import CoreData

@objc(MyChatRoom)
public class MyChatRoom: NSManagedObject {

}

extension MyChatRoom {
    
    var sortedMessages: [ChatMessage] {
        guard let messages = messages?.allObjects as? [ChatMessage] else { return [] }
        return messages.sorted(by: { $0.timestamp ?? Date() < $1.timestamp ?? Date() })
    }
    
}


