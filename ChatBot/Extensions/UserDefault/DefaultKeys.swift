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
    
    static var userApiKey = DefaultsKey<Data>("userApiKey")
    
}

/// 聲音相關
extension DefaultsKeys {
    /// 聲音設定
    static var voiceSetting = DefaultsKey<Data>("voiceSetting")
    
}

