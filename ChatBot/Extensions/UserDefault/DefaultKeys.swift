//
//  DefaultKeys.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/11.
//

import Foundation
import AVFAudio


/// 帳號相關
extension DefaultsKeys {
    
    static var userApiKey = DefaultsKey<String>("userApiKey")
    
}

/// 聲音相關
extension DefaultsKeys {
    
    static var chineseVoiceId = DefaultsKey<String>("chineseVoice")
    static var englishVoiceId = DefaultsKey<String>("englishVoice")
    /// 語調
    static var voicePitch = DefaultsKey<Float>("voicePitch")
    /// 語速
    static var voiceRate = DefaultsKey<Float>("voiceRate")
    
}

