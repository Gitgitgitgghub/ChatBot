//
//  OpenAIService.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import Foundation
import OpenAI
import Combine
import UIKit

class OpenAIService: OpenAIProtocol {
    
    enum LoadingStatus {
        case loading
        case success
        case error(message: String)
    }
    
    let openai = OpenAI(apiToken: apiKey)
    let loadingStatusSubject = PassthroughSubject<LoadingStatus, Never>()
    
    func chatQuery(message: String) -> AnyPublisher<ChatResult, Error> {
        let query = ChatQuery(messages: [.init(role: .user, content: message)!], model: .gpt3_5Turbo)
        return openai.chats(query: query)
            .subscribe(on: DispatchSerialQueue.global())
            .receive(on: DispatchSerialQueue.main)
            .eraseToAnyPublisher()
    }
    
    func createImage(prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, any Error> {
        let query = ImagesQuery(prompt: prompt, size: size)
        return openai.images(query: query)
            .handleEvents(receiveSubscription: { _ in
                print("receiveSubscription")
            }, receiveOutput: { _ in
                print("receiveOutput")
            }, receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("receiveCompletion finished")
                case .failure(_):
                    print("receiveCompletion failure")
                }
            })
            .subscribe(on: DispatchSerialQueue.global())
            .receive(on: DispatchSerialQueue.main)
            .eraseToAnyPublisher()
    }
    
    func editImage(info: [UIImagePickerController.InfoKey : Any], prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, any Error> {
        do {
            let image = try getImageFromInfo(info: info).compressLessThanXMB(mb: 4)
            let query = ImageEditsQuery(image: image.pngData()!, prompt: prompt)
            return openai.imageEdits(query: query)
                .subscribe(on: DispatchSerialQueue.global())
                .receive(on: DispatchSerialQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
}
