//
//  GeminiAIService.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/13.
//

import Foundation
import Combine
import GoogleGenerativeAI

extension GeminiAIService: AIVocabularyServiceProtocol { }
extension GeminiAIService: AIEnglishQuestonServiceProtocol { }

class GeminiAIService: AIServiceProtocol {
    
    let modelName: String
    var apiKey: String
    
    init(apiKey: String, modelName: String = "gemini-1.5-flash") {
        self.apiKey = apiKey
        self.modelName = modelName
    }
    
    private func generativeModel(responseFormat: AIResponseFormat) -> GenerativeModel {
        let responseMIMEType: String? = responseFormat == .json ? "application/json" : nil
        let config = GenerationConfig(responseMIMEType: responseMIMEType)
        return GenerativeModel(name: modelName, apiKey: apiKey, generationConfig: config)
    }
    
    func chat(messages: [ChatMessage], responseFormat: AIResponseFormat) -> AnyPublisher<ChatMessage, any Error> {
        return Future { promise in
            Task {
                do {
                    let generativeModel = self.generativeModel(responseFormat: responseFormat)
                    let response = try await generativeModel.generateContent(messages.toGeminiModelContent())
                    if let text = response.text {
                        promise(.success(ChatMessage(message: text, role: .ai("model"))))
                    } else {
                        promise(.failure(AIServiceError.noValidResponse))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .print("GeminiService")
        .eraseToAnyPublisher()
    }
    
    func chat(prompt: String, responseFormat: AIResponseFormat) -> AnyPublisher<ChatMessage, any Error> {
        return chat(messages: [.init(message: prompt, role: .user)], responseFormat: responseFormat)
    }
    
    
}
