//
//  OpenAIProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import Combine
import OpenAI
import UIKit

protocol OpenAIProtocol: ImageFileHandler {
    
    //var openAI: OpenAI {  get }
    
    func chatQuery(message: String) -> AnyPublisher<ChatResult, Error>
    
    func createImage(prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, Error>
    
    func editImage(info: [UIImagePickerController.InfoKey : Any], prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, Error>
    
}

enum OpenAIResult {
    
    case userChatQuery(message: String)
    case chatResult(data: ChatResult?)
    case imageResult(prompt: String, data: ImagesResult)
    case imageEditResult(prompt: String, data: ImagesResult)
    
    var message: String {
        switch self {
        case .userChatQuery(let message):
            return message
        case .chatResult(let data):
            return mockString
        case .imageResult, .imageEditResult:
            return ""
        }
    }
}


protocol ChatService {
    
}
