//
//  AccountManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/11.
//

import Foundation
import Combine

class AccountManager {
    
    static let shared = AccountManager()
  
    private init(){}
    
    /// 儲存keyInfo
    func saveAPIKey(keyInfo: KeyInfo) {
        MyDefaults.saveKeyInfo(keyInfo: keyInfo)
    }
    
    func needLogin() -> Bool {
        return MyDefaults.loadKeyInfo().key.isEmpty
    }
    
    func login(keyInfo: KeyInfo) -> AnyPublisher<(), Error> {
        let publisher: AnyPublisher<(), Error>
        switch keyInfo.platform {
        case .openAI:
            publisher = OpenAIService(apiKey: keyInfo.key).test()
        case .geminiAI:
            publisher = GeminiAIService(apiKey: keyInfo.key).test()
        }
        return publisher
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.saveAPIKey(keyInfo: keyInfo)
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func logout() {
        saveAPIKey(keyInfo: .init(platform: .openAI, key: ""))
        SpeechVoiceManager.shared.resetAll()
    }
    
    func loadKeyInfo() -> KeyInfo {
        let keyInfo = MyDefaults.loadKeyInfo()
        return keyInfo
    }
    
}

struct KeyInfo: Codable {
    
    let platform: AIPlatform
    let key: String
    
}

private extension UserDefaults {
    
    /// 儲存keyInfo
    func saveKeyInfo(keyInfo: KeyInfo) {
        let encoder = JSONEncoder()
        guard let encodeData = try? encoder.encode(keyInfo) else { return }
        MyDefaults[.userApiKey] = encodeData
    }
    
    /// 讀取SpeechVoiceSeting
    func loadKeyInfo() -> KeyInfo {
        let obj = MyDefaults[.userApiKey]
        let decoder = JSONDecoder()
        guard let obj = try? decoder.decode(KeyInfo.self, from: obj) else { return KeyInfo(platform: .openAI, key: "") }
        return obj
    }
}
