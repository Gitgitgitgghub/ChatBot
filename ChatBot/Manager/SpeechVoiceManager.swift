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
        DispatchQueue.global().async {
            self.setupVoices()
            self.setDelaultValue()
        }
    }
    /// 想要的語言 英文： 英國 美國 澳洲 加拿大 印度
    let targetLanguages = ["en-GB", "en-US", "en-AU", "en-CA", "en-IN"]
    let synthesizer = AVSpeechSynthesizer()
    /// 英文語音包
    var englishVoices: [AVSpeechSynthesisVoice] = []
    /// 中文語音包
    var chineseVoices: [AVSpeechSynthesisVoice] = []
    /// 選擇的英文語音id
    private(set) var selectedEnglishVoiceId: String {
        set {
            MyDefaults[.englishVoiceId] = newValue
        }
        get {
            return MyDefaults[.englishVoiceId]
        }
    }
    /// 選擇的中文語音id
    private(set) var selectedChineseVoiceId: String {
        set {
            MyDefaults[.chineseVoiceId] = newValue
        }
        get {
            return MyDefaults[.chineseVoiceId]
        }
    }
    
    /// 語調
    private(set) var voicePitch: Float {
        set {
            MyDefaults[.voicePitch] = newValue
        }
        get {
            return MyDefaults[.voicePitch]
        }
    }
    /// 語速
    private(set) var voiceRate: Float {
        set {
            MyDefaults[.voiceRate] = newValue
        }
        get {
            return MyDefaults[.voiceRate]
        }
    }
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
    
    
    private func setDelaultValue() {
        if selectedChineseVoiceId.isEmpty {
            selectedChineseVoiceId = chineseVoices.first?.identifier ?? ""
        }
        if selectedEnglishVoiceId.isEmpty {
            selectedEnglishVoiceId = englishVoices.first?.identifier ?? ""
        }
        if voiceRate == 0 {
            voiceRate = 0.5
        }
        if voicePitch == 0 {
            voicePitch = 1.0
        }
    }
    
    func resetAll() {
        MyDefaults[.voiceRate] = .zero
        MyDefaults[.voicePitch] = .zero
        MyDefaults[.chineseVoiceId] = ""
        MyDefaults[.englishVoiceId] = ""
        setDelaultValue()
    }
    
    //TODO: - 看能不能預先處理好不然第一次播放聲音都很慢
    func prepareSpeechSynthesizer() {
        let silentUtterance = AVSpeechUtterance(string: "see you tomorrow")
        silentUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        silentUtterance.volume = 0
        self.synthesizer.speak(silentUtterance)
    }
    
    func speak(utterance: AVSpeechUtterance, voice: AVSpeechSynthesisVoice) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        utterance.voice = voice
        synthesizer.speak(utterance)
    }
    
    /// 播放自動判斷該用中文還英文播放
    func speak(text: String) {
        let text = cleanText(text)
        guard let voice = getVoiceForText(text: text) else {
            print("speak text 找不到對應的聲音: \(text)")
            return
        }
        // preUtteranceDelay 方式製造停頓(目前聽起來比較自然)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = voiceRate
        utterance.pitchMultiplier = voicePitch
        utterance.voice = voice
        utterance.preUtteranceDelay = 0.1
        synthesizer.speak(utterance)
        // 分割的方式來製造停頓
//        let utterances = getAVSpeechUtterances(text: text, voice: voice)
//        for utterance in utterances {
//            synthesizer.speak(utterance)
//        }
    }
    
    /// 清除字串中的標點符號不然會一起唸出來＝＝
    private func cleanText(_ text: String) -> String {
        let punctuationCharacterSet = CharacterSet.punctuationCharacters
        let cleanedText = text.components(separatedBy: punctuationCharacterSet).joined(separator: "")
        return cleanedText.lowercased()
    }
    
    /// 取得依照空白或者斷行分割字串的AVSpeechUtterance(目的是讓聲音有停頓)
    private func getAVSpeechUtterances(text: String, voice: AVSpeechSynthesisVoice) -> [AVSpeechUtterance] {
        let components = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        var utterances: [AVSpeechUtterance] = []
        for component in components {
            let utterance = AVSpeechUtterance(string: component)
            utterance.rate = voiceRate
            utterance.pitchMultiplier = voicePitch
            utterance.voice = voice
            //utterance.preUtteranceDelay = 0.1
            utterances.append(utterance)
        }
        return utterances
    }
    
    private func getVoiceForText(text: String) -> AVSpeechSynthesisVoice? {
        if text.containsChinese() {
            return AVSpeechSynthesisVoice(identifier: selectedChineseVoiceId)
        }
        return AVSpeechSynthesisVoice(identifier: selectedEnglishVoiceId)
    }
    
    /// 保存聲音
    func saveVoice(chIndex: Int, engIndex: Int, rate: Float, pitch: Float) {
        let chId = chineseVoices[chIndex].identifier
        let enId = englishVoices[engIndex].identifier
        selectedChineseVoiceId = chId
        selectedEnglishVoiceId = enId
        voiceRate = rate
        voicePitch = pitch
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
    
    func displayName(number: Int) -> String {
        return countryName + displayGender + " \(number)"
    }
    
}
