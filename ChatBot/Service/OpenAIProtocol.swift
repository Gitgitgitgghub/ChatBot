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
    
    func chatQuery(messages: [ChatMessage], model: Model) -> AnyPublisher<ChatMessage, Error>
    
    func createImage(prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, Error>
    
    func editImage(info: [UIImagePickerController.InfoKey : Any], prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, Error>
    /// 處理api請求可以不用一直重複寫loadingStatus
    func performAPICall<T: Decodable>(_ publisher: AnyPublisher<T, Error>) -> AnyPublisher<T, Error>
    
}

extension OpenAIProtocol {
    
    func performAPICall<T: Decodable>(_ publisher: AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        loadingStatusSubject.send(.loading())
        return publisher
            .timeout(.seconds(10), scheduler: RunLoop.main, customError: { URLError(.timedOut) })
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
}
