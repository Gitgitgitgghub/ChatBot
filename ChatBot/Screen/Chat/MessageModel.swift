//
//  MessageModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import OpenAI

class MessageModel {
    
    var uuid: String = UUID().uuidString
    var message: String = ""
    var attributedString: NSAttributedString? = nil
    var estimatedHeightForAttributedString: CGFloat = 0
    var originalData: AnyObject?
    var messageType: MessageType = .message
    var sender: Sender = .user
    
    /// 發送者類型
    enum Sender {
        /// 使用者訊息
        case user
        /// ai回覆的訊息
        case ai
        /// 發給系統的訊息
        case system
    }
    
    /// 訊息類型
    enum MessageType {
        /// 訊息
        case message
        /// 模擬訊息
        case mock
    }
    
    init(message: String, sender: Sender) {
        self.message = message
        self.sender = sender
        self.messageType = .mock
    }
    
    init(imagesResult: ImagesResult) {
        
    }
    
    init(chatResult: ChatResult, sender: Sender) {
        self.message = chatResult.choices.first?.message.content?.string ?? ""
        self.originalData = chatResult as AnyObject
        self.sender = sender
        self.messageType = .message
    }
    
}
