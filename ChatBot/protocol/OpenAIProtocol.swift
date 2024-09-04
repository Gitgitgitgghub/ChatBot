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

protocol OpenAIProtocol: AnyObject, ImageFileHandler {
    
    //var openAI: OpenAI {  get }
    var loadingStatusSubject: CurrentValueSubject<LoadingStatus, Never> { get }
    
    func chatQuery(messages: [ChatMessage], model: Model) -> AnyPublisher<ChatResult, Error>
    
    func createImage(prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, Error>
    
    func editImage(info: [UIImagePickerController.InfoKey : Any], prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, Error>
    /// 處理api請求可以不用一直重複寫loadingStatus
    func performAPICall<T: Decodable>(_ publisher: AnyPublisher<T, Error>) -> AnyPublisher<T, Error>
    /// chatResult decode
    func decodeChatResult<T>(_ type: T.Type, from result: ChatResult) throws -> T where T : Decodable
    
}

enum OpenAIError: Error {
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

extension OpenAIProtocol {
    
    func performAPICall<T>(_ publisher: AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        loadingStatusSubject.send(.loading())
        return publisher
            .timeout(.seconds(20), scheduler: RunLoop.main, customError: { OpenAIError.timeout })
            .handleEvents(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.loadingStatusSubject.send(.success)
                case .failure(let error):
                    self?.loadingStatusSubject.send(.error(error: error))
                }
            })
            .eraseToAnyPublisher()
    }
    
    func decodeChatResult<T: Decodable>(_ type: T.Type, from result: ChatResult) throws -> T {
        guard let text = result.choices.first?.message.content?.string else {
            throw OpenAIError.noValidResponse
        }
        print("Received JSON: \(text)")
        guard let jsonData = text.data(using: .utf8) else {
            throw OpenAIError.unableToConvertResponseToData
        }
        return try JSONDecoder().decode(type, from: jsonData)
    }
}
