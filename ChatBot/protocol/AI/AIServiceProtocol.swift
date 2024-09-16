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


enum AIServiceError: Error {
    /// 查詢不到該單字
    case wordNotFound(suggestion: String? = nil)
    /// timeout
    case timeout
    /// 無有效回應
    case noValidResponse
    /// 轉換成jsonData失敗
    case unableToConvertResponseToData
    /// 不明錯誤
    case unknown
    case selfDeallocated

}

enum AIResponseFormat: String {
    case json
    case text
}

protocol AIServiceProtocol: AnyObject, ImageFileHandler {
    
    /// chatResult decode
    func decodeChatResult<T>(_ type: T.Type, from result: ChatResult) throws -> T where T : Decodable
    /// chatResult decode
    func decodeChatResult<T>(_ type: T.Type, from result: String?) throws -> T where T : Decodable
    
    func chat(messages: [ChatMessage], responseFormat: AIResponseFormat) -> AnyPublisher<ChatMessage, Error>
    
    func chat(prompt: String, responseFormat: AIResponseFormat) -> AnyPublisher<ChatMessage, Error>
    
    func test() -> AnyPublisher<Void, Error>
    
}

extension AIServiceProtocol {
    
    func test() -> AnyPublisher<Void, Error> {
        return chat(messages: [.init(message: "hello", role: .user)], responseFormat: .text)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func decodeChatResult<T: Decodable>(_ type: T.Type, from result: ChatResult) throws -> T {
        guard let text = result.choices.first?.message.content?.string else {
            throw AIServiceError.noValidResponse
        }
        print("Received JSON: \(text)")
        guard let jsonData = text.data(using: .utf8) else {
            throw AIServiceError.unableToConvertResponseToData
        }
        return try JSONDecoder().decode(type, from: jsonData)
    }
    
    func decodeChatResult<T: Decodable>(_ type: T.Type, from result: String?) throws -> T {
        guard let text = result else {
            throw AIServiceError.noValidResponse
        }
        print("Received JSON: \(text)")
        guard let jsonData = text.data(using: .utf8) else {
            throw AIServiceError.unableToConvertResponseToData
        }
        return try JSONDecoder().decode(type, from: jsonData)
    }
}
