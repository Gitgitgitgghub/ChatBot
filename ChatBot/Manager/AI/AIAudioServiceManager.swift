//
//  AIAudioServiceManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/19.
//

import Foundation
import Combine
import OpenAI

struct SpeechResult {
    let role: ChatMessage.Role
    let audioURL: URL?
    let generatedText: String
}

struct TextToSpeechResult {
    let role: ChatMessage.Role
    let originalText: String
    let audioData: Data
    let savedAudioURL: URL?
}

enum AudioResult {
    case stt(result: SpeechResult)
    case tts(result: TextToSpeechResult)
    case initialScenario(content: String)
    
    var text: String {
        switch self {
        case .stt(let result):
            return result.generatedText
        case .tts(let result):
            return result.originalText
        case .initialScenario(let content):
            return content
        }
    }
    var audioURL: URL? {
        switch self {
        case .stt(let result):
            return result.audioURL
        case .tts(let result):
            return result.savedAudioURL
        case .initialScenario(_):
            return nil
        }
    }
    var role: ChatMessage.Role? {
        switch self {
        case .stt(let result):
            return result.role
        case .tts(let result):
            return result.role
        case .initialScenario(_):
            return nil
        }
    }
    
    func toChatCompletionMessage() -> ChatMessage {
        switch self {
        case .stt(let result):
            return .init(message: result.generatedText, role: result.role)
        case .tts(let result):
            return .init(message: result.originalText, role: result.role)
        case .initialScenario(content: let content):
            return .init(message: content, role: .ai("assistant"))
        }
    }
}

class AIAudioServiceManager {
    
    
    let service: AIAudioServiceProtocol
    
    init(service: AIAudioServiceProtocol, initialScenario: String) {
        self.service = service
        self.setInitialScenario(initialScenario: initialScenario)
    }
    private(set) var conversationHistory: [AudioResult] = []
    
    /// 語音轉文字，這邊用來將用戶語音轉文字
    func performSpeechToText(url: URL, detectEnglish: Bool = false) -> AnyPublisher<AudioResult, Error> {
        return service.speechToText(url: url, detectEnglish: detectEnglish)
            .tryMap { generatedText in
                let result = SpeechResult(role: .user, audioURL: url, generatedText: generatedText)
                return AudioResult.stt(result: result)
            }
            .eraseToAnyPublisher()
    }
    
    /// 文字轉語音，這邊用來將AI回覆文字轉語音
    func performTextToSpeech(text: String) -> AnyPublisher<AudioResult, Error> {
        return service.textToSpeech(text: text)
            .map { audioData in
                // 保存生成的音頻數據
                let savedURL = AudioManager.shared.saveAudioToDocumentsDirectory(data: audioData)
                let result = TextToSpeechResult(role: .ai("assistant"), originalText: text, audioData: audioData, savedAudioURL: savedURL)
                return AudioResult.tts(result: result)
            }
            .eraseToAnyPublisher()
    }
    
    /// 設定初始化情境
    func setInitialScenario(initialScenario: String) {
        conversationHistory = []
        let initialScenarioMessage = AudioResult.initialScenario(content: """
        You are a restaurant waiter, and the entire conversation must be in English. If the user speaks in a language other than English, kindly remind them to use English only. You will greet the user and take their order.
        """)
        conversationHistory.append(initialScenarioMessage)
    }
    
    func generateAIResponseWithInitialScenario() -> AnyPublisher<AudioResult, Error> {
        let queryMessages = conversationHistory.map { message in
            return message.toChatCompletionMessage()
        }
        return service.chat(messages: queryMessages, responseFormat: .text)
            .flatMap({ [weak self] chatMessage -> AnyPublisher<AudioResult, Error> in
                guard let `self` = self else {
                    return Fail(outputType: AudioResult.self, failure: AIServiceError.selfDeallocated)
                    .eraseToAnyPublisher()
                }
                return self.performTextToSpeech(text: chatMessage.message)
                    .handleEvents(receiveOutput: { [weak self] audioResult in
                        self?.conversationHistory.append(audioResult)
                    })
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
    }
    
    func simulateEnglishOnlyConversation(audioURL: URL) -> AnyPublisher<(userSpeechResult: AudioResult, aiSpeechResult: AudioResult), Error> {
        return performSpeechToTextConversion(audioURL: audioURL)
            .flatMap { [weak self] userSpeechResult -> AnyPublisher<(userSpeechResult: AudioResult, aiSpeechResult: AudioResult), Error> in
                guard let `self` = self else {
                    return Fail(error: AIServiceError.selfDeallocated)
                        .eraseToAnyPublisher()
                }
                // 更新對話歷史
                self.conversationHistory.append(userSpeechResult)
                return self.generateAIResponseBasedOnConversation()
                    .map { aiSpeechResult in
                        // 返回元組結果
                        return (userSpeechResult, aiSpeechResult)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }


    func simulateEnglishOnlyConversation(input: String) -> AnyPublisher<AudioResult, Error> {
        conversationHistory.append(AudioResult.stt(result: .init(role: .user, audioURL: nil, generatedText: input)))
        return generateAIResponseWithInitialScenario()
            .eraseToAnyPublisher()
    }
    
    /// 用戶語音轉文字
    func performSpeechToTextConversion(audioURL: URL) -> AnyPublisher<AudioResult, Error> {
        return performSpeechToText(url: audioURL)
            .compactMap { result in
                if case .stt = result {
                    return result
                }
                return nil
            }
            .eraseToAnyPublisher()
    }
    
    /// 生成 AI 回應
    func generateAIResponseBasedOnConversation() -> AnyPublisher<AudioResult, Error> {
        let queryMessages = conversationHistory.map { message in
            return message.toChatCompletionMessage()
        }
        return service.chat(messages: queryMessages, responseFormat: .text)
            .flatMap { [weak self] chatMessage -> AnyPublisher<AudioResult, Error> in
                guard let `self` = self else {
                    return Fail(error: AIServiceError.selfDeallocated)
                        .eraseToAnyPublisher()
                }
                return self.performTextToSpeech(text: chatMessage.message)
                    .compactMap { result in
                        if case .tts = result {
                            return result
                        }
                        return nil
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }



}
