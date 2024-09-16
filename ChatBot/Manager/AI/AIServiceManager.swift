//
//  AIServiceManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/16.
//

import Foundation


class AIServiceManager {
    
    static let shared: AIServiceManager = AIServiceManager()
    private init() {}
    
    var service: AIServiceProtocol {
        let keyinfo = AccountManager.shared.loadKeyInfo()
        switch keyinfo.platform {
        case .openAI:
            return OpenAIService(apiKey: keyinfo.key)
        case .geminiAI:
            return GeminiAIService(apiKey: keyinfo.key)
        }
    }
    
}
