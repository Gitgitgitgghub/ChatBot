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
        }
    }
    
    /// 想要的語言 英文： 英國 美國 澳洲 加拿大 印度
    let targetLanguages = ["en-GB", "en-US", "en-AU", "en-CA", "en-IN"]
    let synthesizer = AVSpeechSynthesizer()
    /// 英文語音包
    var englishVoices: [AVSpeechSynthesisVoice] = []
    /// 中文語音包
    var chineseVoices: [AVSpeechSynthesisVoice] = []
    /// 聲音設定
    private(set) var voiceSetting: SpeechVoiceSeting!
    
    /// synthesizer的代理
    weak var delegate: AVSpeechSynthesizerDelegate? {
        didSet {
            synthesizer.delegate = delegate
        }
    }
    
    
    private func setupVoices() {
        self.voiceSetting = MyDefaults.loadVoiceSetting()
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
    
    func resetAll() {
        let defaultSetting = SpeechVoiceSeting()
        MyDefaults.saveVoiceSetting(setting: defaultSetting)
        self.voiceSetting = defaultSetting
    }
    
    /// 預先播放聲音(避免第一次播放會卡很久 爬文看是iOS本身bug)
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
        utterance.rate = voiceSetting.voiceRate
        utterance.pitchMultiplier = voiceSetting.voicePitch
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
            utterance.rate = voiceSetting.voiceRate
            utterance.pitchMultiplier = voiceSetting.voicePitch
            utterance.voice = voice
            //utterance.preUtteranceDelay = 0.1
            utterances.append(utterance)
        }
        return utterances
    }
    
    private func getVoiceForText(text: String) -> AVSpeechSynthesisVoice? {
        if text.containsChinese() {
            return AVSpeechSynthesisVoice(identifier: voiceSetting.selectedChineseVoiceId)
        }
        return AVSpeechSynthesisVoice(identifier: voiceSetting.selectedEnglishVoiceId)
    }
    
    /// 保存聲音
    func saveVoice(chIndex: Int, engIndex: Int, rate: Float, pitch: Float) {
        let chId = chineseVoices[chIndex].identifier
        let enId = englishVoices[engIndex].identifier
        voiceSetting.selectedChineseVoiceId = chId
        voiceSetting.selectedEnglishVoiceId = enId
        voiceSetting.voiceRate = rate
        voiceSetting.voicePitch = pitch
        MyDefaults.saveVoiceSetting(setting: voiceSetting)
    }
    
}

struct SpeechVoiceSeting: Codable {
    /// 選擇的中文語音id
    var selectedChineseVoiceId = ""
    /// 選擇的英文語音id
    var selectedEnglishVoiceId = ""
    /// 語速
    var voiceRate: Float = 0.5
    /// 語調
    var voicePitch: Float = 1.0
}

private extension UserDefaults {
    
    /// 儲存SpeechVoiceSeting(Data型式)
    func saveVoiceSetting(setting: SpeechVoiceSeting) {
        let encoder = JSONEncoder()
        guard let encodeData = try? encoder.encode(setting) else { return }
        MyDefaults[.voiceSetting] = encodeData
    }
    
    /// 讀取SpeechVoiceSeting
    func loadVoiceSetting() -> SpeechVoiceSeting {
        let obj = MyDefaults[.voiceSetting]
        let decoder = JSONDecoder()
        guard let obj = try? decoder.decode(SpeechVoiceSeting.self, from: obj) else { return SpeechVoiceSeting() }
        return obj
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
