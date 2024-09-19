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
import NaturalLanguage


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

extension OpenAIService: AIAudioServiceProtocol {
    
    func speechToText(url: URL, detectEnglish: Bool = false) -> AnyPublisher<String, Error> {
        guard let data = try? Data(contentsOf: url) else {
            return Fail(outputType: String.self, failure: AIServiceError.emptyData)
                .eraseToAnyPublisher()
        }
        let query = AudioTranscriptionQuery(file: data, fileType: .m4a, model: .whisper_1)
        return openAI.audioTranscriptions(query: query)
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .tryMap { [weak self] response in
                guard let `self` = self else {
                    throw AIServiceError.selfDeallocated
                }
                if detectEnglish {
                    let detectedLanguage = detectLanguage(for: response.text)
                    if detectedLanguage == "en" {
                        return response.text
                    } else {
                        throw AIServiceError.nonEnglishDetected(detectedLanguage: detectedLanguage)
                    }
                }
                return response.text
            }
            .eraseToAnyPublisher()
    }
    
    func textToSpeech(text: String)  -> AnyPublisher<Data, Error> {
        let query = AudioSpeechQuery(model: .tts_1, input: text, voice: .alloy, responseFormat: .aac, speed: 1)
        return openAI.audioCreateSpeech(query: query)
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .map({ $0.audio })
            .eraseToAnyPublisher()
    }
    
    /// 偵測文本語言
    func detectLanguage(for text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue ?? "unknown"
    }
    
}

extension OpenAIService: AIVocabularyServiceProtocol {
    
}

extension OpenAIService: AIEnglishQuestonServiceProtocol {
    
}
