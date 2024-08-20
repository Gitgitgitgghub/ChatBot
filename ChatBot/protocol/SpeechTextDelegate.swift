//
//  SpeechTextDelegate.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/20.
//

import Foundation


protocol SpeechTextDelegate: AnyObject {
    
    /// 播放傳入字串
    func speak(text: String)
    
}

extension SpeechTextDelegate {
    
    func speak(text: String) {
        SpeechVoiceManager.shared.speak(text: text)
    }
    
}

