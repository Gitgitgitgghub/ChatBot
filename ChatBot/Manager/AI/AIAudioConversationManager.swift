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
    let audioData: Data?
    let savedAudioURL: URL?
}

/// 對話情境
struct Scenario: Codable {
    /// 情境
    var scenario: String
    /// ai扮演的角色
    var aiRole: String
    /// 用戶的角色
    var userRole: String
    /// 情境
    var scenarioTranslation: String
    /// ai扮演的角色
    var aiRoleTranslation: String
    /// 用戶的角色
    var userRoleTranslation: String
    
    var prompt: String {
        return """
        Scenario: \(scenario). You are now playing the role of \(aiRole), and the user will be playing the role of \(userRole). Your responses must strictly reflect your role as \(aiRole). The entire conversation must be conducted in English. If the user speaks in a language other than English, kindly remind them to use English only. Ensure all responses are specific and accurate, with no placeholders or vague information. Only provide realistic details.
        """
    }
    
    func printScenario() {
        print("scenario: \(scenario)" + "\n" + "aiRole: \(aiRole)" + "\n" + "userRole: \(userRole)")
    }
}

enum AudioResult {
    case stt(result: SpeechResult)
    case tts(result: TextToSpeechResult)
    case initialScenario(role: ChatMessage.Role, content: String)
    
    var text: String {
        switch self {
        case .stt(let result):
            return result.generatedText
        case .tts(let result):
            return result.originalText
        case .initialScenario(_, let content):
            return content
        }
    }
    var audioURL: URL? {
        switch self {
        case .stt(let result):
            return result.audioURL
        case .tts(let result):
            return result.savedAudioURL
        case .initialScenario:
            return nil
        }
    }
    var role: ChatMessage.Role {
        switch self {
        case .stt(let result):
            return result.role
        case .tts(let result):
            return result.role
        case .initialScenario(let role, _):
            return role
        }
    }
    
    func toChatCompletionMessage() -> ChatMessage {
        switch self {
        case .stt(let result):
            return .init(message: result.generatedText, role: result.role)
        case .tts(let result):
            return .init(message: result.originalText, role: result.role)
        case .initialScenario(let role, let content):
            return .init(message: content, role: role)
        }
    }
    
    func printResult() {
        print("AudioResult role:\(role)" + "\n" + "text: \(text)")
    }
}

class AIAudioConversationManager {
    
    
    let service: AIAudioServiceProtocol
    private(set) var scenario: Scenario?
    
    init(service: AIAudioServiceProtocol, scenario: Scenario?) {
        self.service = service
        self.setInitialScenario(initialScenario: scenario)
    }
    private(set) var conversationHistory: [AudioResult] = []
    
    /// 設定初始化情境
    func setInitialScenario(initialScenario: Scenario?) {
        guard let initialScenario = initialScenario else { return }
        self.scenario = initialScenario
        conversationHistory = []
        let initialScenarioMessage = AudioResult.initialScenario(role: .user, content: initialScenario.prompt)
        conversationHistory.append(initialScenarioMessage)
    }
    
    func generateScenario() -> AnyPublisher<Scenario, Error> {
        let prompt = """
        Please generate a simple conversation scenario for English practice in the following JSON format. The scenario should be commonly used in everyday life and not too complex. Avoid store or shopping scenarios. Focus on diverse situations such as home, public transportation, social interactions, etc. Ensure the roles are realistic and suitable for basic conversation practice. Here is the required json format:

        {
          "scenario": "[Scene description]",
          "aiRole": "[Role of the AI]",
          "userRole": "[Role of the user]",
          "scenarioTranslation": "[Translation of the scenario in Traditional Chinese]",
          "aiRoleTranslation": "[Translation of the aiRole in Traditional Chinese]",
          "userRoleTranslation": "[Translation of the userRole in Traditional Chinese]"
        }
        """
        return service.chat(prompt: prompt, responseFormat: .json)
            .tryMap { [weak self] chatMessage in
                guard let `self` = self else { throw AIServiceError.selfDeallocated }
                return try self.service.decodeChatResult(Scenario.self, from: chatMessage.message)
            }
            .eraseToAnyPublisher()
    }
    
    func generateAIResponse() -> AnyPublisher<AudioResult, Error> {
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
        return performSpeechToText(url: audioURL)
            .flatMap { [weak self] userSpeechResult -> AnyPublisher<(userSpeechResult: AudioResult, aiSpeechResult: AudioResult), Error> in
                guard let `self` = self else {
                    return Fail(error: AIServiceError.selfDeallocated)
                        .eraseToAnyPublisher()
                }
                // 更新對話歷史
                self.conversationHistory.append(userSpeechResult)
                return self.generateAIResponse()
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
        return generateAIResponse()
            .eraseToAnyPublisher()
    }
    
    /// 語音轉文字，這邊用來將用戶語音轉文字
    private func performSpeechToText(url: URL, detectEnglish: Bool = false) -> AnyPublisher<AudioResult, Error> {
        let role: ChatMessage.Role = .init(rawValue: self.service.userSymbol)
        return service.speechToText(url: url, detectEnglish: detectEnglish)
            .tryMap { generatedText in
                let result = SpeechResult(role: role, audioURL: url, generatedText: generatedText)
                return AudioResult.stt(result: result)
            }
            .compactMap { result in
                if case .stt = result {
                    return result
                }
                return nil
            }
            .eraseToAnyPublisher()
    }
    
    /// 文字轉語音，這邊用來將AI回覆文字轉語音
    private func performTextToSpeech(text: String) -> AnyPublisher<AudioResult, Error> {
        let role: ChatMessage.Role = .init(rawValue: self.service.aiSymbol)
        return service.textToSpeech(text: text)
            .map { audioData in
                // 保存生成的音頻數據
                if let audioData = audioData {
                    let savedURL = AudioManager.shared.saveAudioToDocumentsDirectory(data: audioData)
                    let result = TextToSpeechResult(role: role, originalText: text, audioData: audioData, savedAudioURL: savedURL)
                    return AudioResult.tts(result: result)
                }else {
                    return AudioResult.tts(result: .init(role: role, originalText: text, audioData: nil, savedAudioURL: nil))
                }
            }
            .eraseToAnyPublisher()
    }



}
