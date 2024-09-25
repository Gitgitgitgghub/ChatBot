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
    
    var aiSymbol: String = "model"
    var userSymbol: String = "user"
    let modelName: String
    var apiKey: String
    
    init(apiKey: String, modelName: String = "gemini-1.5-pro") {
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
                        promise(.success(ChatMessage(message: text, role: .ai(self.aiSymbol))))
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
    
    func translation(input: String, to language: NaturalLanguage) -> AnyPublisher<ChatMessage, any Error> {
        let prompt = """
                    Just translate the following text to \(language) for me: \(input)
                    """
        return chat(prompt: prompt, responseFormat: .text)
    }
    
}

extension GeminiAIService: AIAudioServiceProtocol {
    
    // gemini不支援
    func textToSpeech(text: String) -> AnyPublisher<Data?, any Error> {
        return Just(nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func speechToText(url: URL, detectEnglish: Bool) -> AnyPublisher<String, any Error> {
        guard let data = try? Data(contentsOf: url) else {
            return Fail(outputType: String.self, failure: AIServiceError.emptyData)
                .eraseToAnyPublisher()
        }
        return Future { promise in
            Task {
                do {
                    let prompt = "Generate a transcript of the speech."
                    let generativeModel = self.generativeModel(responseFormat: .text)
                    let response = try await generativeModel.generateContent([ModelContent(parts: [.text(prompt), .data(mimetype: "audio/mp3", data)])])
                    if let text = response.text {
                        promise(.success(text))
                    } else {
                        promise(.failure(AIServiceError.noValidResponse))
                    }
                
                }catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    
}
