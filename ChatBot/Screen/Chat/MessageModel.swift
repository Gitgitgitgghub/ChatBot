//
//  MessageModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation

struct MessageModel {
    
    let message: String
    let isUser: Bool
    let id: String = UUID().uuidString
    
}
