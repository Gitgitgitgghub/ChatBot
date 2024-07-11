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
    
    
    let openai = OpenAI(apiToken: AccountManager.shared.apiKey)
    let loadingStatusSubject = CurrentValueSubject<LoadingStatus, Never>(.none)
    
    func chatQuery(messages: [ChatMessage], model: Model = .gpt3_5Turbo) -> AnyPublisher<ChatMessage, Error> {
        let queryMessages = messages.toChatCompletionMessageParam()
        let query = ChatQuery(messages: queryMessages, model: model)
        let publisher = openai.chats(query: query)
            .eraseToAnyPublisher()
        return performAPICall(publisher)
            .print("chatQuery")
            .compactMap({ result in
                return ChatMessage.createNewMessage(content: result.choices.first?.message.content?.string ?? "", role: .assistant, messageType: .message)
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
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
