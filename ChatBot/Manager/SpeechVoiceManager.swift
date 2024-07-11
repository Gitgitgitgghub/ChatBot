//
//  SpeechVoiceManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/10.
//

import Foundation
import AVFAudio


class SpeechVoiceManager {
    
    static let shared = SpeechVoiceManager()
    
    private init(){
        setupVoices()
    }
    let synthesizer = AVSpeechSynthesizer()
    /// 英文語音包
    var englishVoices: [AVSpeechSynthesisVoice] = []
    /// 中文語音包
    var chineseVoices: [AVSpeechSynthesisVoice] = []
    /// 選擇的英文語音
    var selectedEnglishVoice: AVSpeechSynthesisVoice?
    /// 選擇的中文語音
    var selectedChineseVoice: AVSpeechSynthesisVoice?
    /// 想要的語言 英文： 英國 美國 澳洲 加拿大 印度
    let targetLanguages = ["en-GB", "en-US", "en-AU", "en-CA", "en-IN"]
    /// synthesizer的代理
    weak var delegate: AVSpeechSynthesizerDelegate? {
        didSet {
            synthesizer.delegate = delegate
        }
    }
    
    
    private func setupVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        // 先對語音做分類
        for voice in voices {
            if voice.language.hasPrefix("en") && targetLanguages.contains(voice.language) {
                englishVoices.append(voice)
            } else if voice.language.hasPrefix("zh") {
                chineseVoices.append(voice)
            }
        }
    }
    
    //TODO: - 看能不能預先處理好不然第一次播放聲音都很慢
    func prepareSpeechSynthesizer() {
        DispatchQueue.global().async {
            let silentUtterance = AVSpeechUtterance(string: "")
            silentUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            self.synthesizer.speak(silentUtterance)
        }
    }
    
    func speak(utterance: AVSpeechUtterance, voice: AVSpeechSynthesisVoice) {
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}

extension AVSpeechSynthesisVoice {
    
    static let countryNames: [String: String] = [
        "en-GB": "英國",
        "en-US": "美國",
        "en-AU": "澳大利亚",
        "en-CA": "加拿大",
        "en-IN": "印度",
        "zh-CN": "中國",
        "zh-TW": "台湾",
        "zh-HK": "香港"
    ]
    /// 可辨認的國家名稱
    var countryName: String {
        return AVSpeechSynthesisVoice.countryNames[language] ?? "unknown"
    }
    /// 顯示的性別
    var displayGender: String {
        switch gender {
        case .male:
            return "男"
        case .female:
            return "女"
        default:
            return "unknown"
        }
    }
    
}
