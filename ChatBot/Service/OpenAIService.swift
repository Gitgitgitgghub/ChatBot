//
//  OpenAIService.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import Foundation
import OpenAI
import Combine

class OpenAIService: OpenAIProtocol {
    
    let openai = OpenAI(apiToken: apiKey)
    
    func chatQuery(message: String) -> AnyPublisher<ChatResult, Error> {
        let query = ChatQuery(messages: [.init(role: .user, content: message)!], model: .gpt3_5Turbo)
        return openai.chats(query: query)
            .subscribe(on: DispatchSerialQueue.global())
            .receive(on: DispatchSerialQueue.main)
            .eraseToAnyPublisher()
    }
    
    
}
