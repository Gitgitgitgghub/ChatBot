//
//  AccountManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/11.
//

import Foundation


class AccountManager {
    
    static let shared = AccountManager()
    
    
    var apiKey: String {
        set {
            MyDefaults[.userApiKey] = newValue
        }
        get {
            return MyDefaults[.userApiKey]
        }
    }
    private init(){}
    
    func saveAPIKey(key: String) {
        apiKey = key
    }
    
    func needLogin() -> Bool {
        return apiKey.isEmpty
    }
    
    func logout() {
        apiKey = ""
        SpeechVoiceManager.shared.resetAll()
    }
}
