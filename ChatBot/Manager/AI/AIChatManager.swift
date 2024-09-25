//
//  AIChatManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/13.
//

import Foundation
import Combine


class AIChatManager {
    
    let service: AIServiceProtocol
    
    init(service: AIServiceProtocol) {
        self.service = service
    }
    
    func chat(messages: [ChatMessage], responseFormat: AIResponseFormat = .text) -> AnyPublisher<ChatMessage, Error> {
        return service.chat(messages: messages, responseFormat: responseFormat)
    }
    
    func chat(prompt: String, responseFormat: AIResponseFormat = .text) -> AnyPublisher<ChatMessage, Error> {
        return service.chat(prompt: prompt, responseFormat: responseFormat)
    }
    
    func translation(input: String, to language: NaturalLanguage) -> AnyPublisher<ChatMessage, Error> {
        return service.translation(input: input, to: language)
    }
    
}
