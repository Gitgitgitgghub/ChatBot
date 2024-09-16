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


class OpenAIService: AIServiceProtocol {
    
    let openAI: OpenAI
    let model: Model
    
    init(apiKey: String, model: Model = .gpt4_o) {
        self.model = model
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    func chat(prompt: String, responseFormat: AIResponseFormat) -> AnyPublisher<ChatMessage, any Error> {
        return chat(messages: [.init(message: prompt, role: .user)], responseFormat: responseFormat)
    }
    
    func chat(messages: [ChatMessage], responseFormat: AIResponseFormat) -> AnyPublisher<ChatMessage, any Error> {
        let queryMessages = messages.toChatCompletionMessageParam()
        let query = ChatQuery(messages: queryMessages, model: model, responseFormat: responseFormat == .json ? .jsonObject : .text)
        let publisher = openAI.chats(query: query)
            .eraseToAnyPublisher()
        return publisher
            .print("OpenAIService")
            .map({ ChatMessage(message: $0.choices.first?.message.content?.string ?? "", role: .ai($0.choices.first?.message.role.rawValue ?? "assistant")) })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    
    
//    func createImage(prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, any Error> {
//        let query = ImagesQuery(prompt: prompt, size: size)
//        return openAI.images(query: query)
//            .handleEvents(receiveSubscription: { _ in
//                print("receiveSubscription")
//            }, receiveOutput: { _ in
//                print("receiveOutput")
//            }, receiveCompletion: { completion in
//                switch completion {
//                case .finished:
//                    print("receiveCompletion finished")
//                case .failure(_):
//                    print("receiveCompletion failure")
//                }
//            })
//            .subscribe(on: DispatchSerialQueue.global())
//            .receive(on: DispatchSerialQueue.main)
//            .eraseToAnyPublisher()
//    }
//    
//    func editImage(info: [UIImagePickerController.InfoKey : Any], prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, any Error> {
//        do {
//            let image = try getImageFromInfo(info: info).compressLessThanXMB(mb: 4)
//            let query = ImageEditsQuery(image: image.pngData()!, prompt: prompt)
//            return openAI.imageEdits(query: query)
//                .subscribe(on: DispatchSerialQueue.global())
//                .receive(on: DispatchSerialQueue.main)
//                .eraseToAnyPublisher()
//        } catch {
//            return Fail(error: error)
//                .eraseToAnyPublisher()
//        }
//    }
    
}

extension OpenAIService: AIVocabularyServiceProtocol {
    
}

extension OpenAIService: AIEnglishQuestonServiceProtocol {
    
}
