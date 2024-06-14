//
//  OpenAIProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import Combine
import OpenAI

protocol OpenAIProtocol {
    
    //var openAI: OpenAI {  get }
    
    func chatQuery(message: String) -> AnyPublisher<ChatResult, Error>
    
}

protocol ChatService {
    
}
