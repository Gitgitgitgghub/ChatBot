//
//  ConversationViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/18.
//

import Foundation


class ConversationViewModel: BaseViewModel<ConversationViewModel.InputEvent, ConversationViewModel.OutputEvent> {
    
    enum InputEvent {
        case startRecording
        case stopRecording
        case userInput(input: String)
        case playAudio(indexPath: IndexPath)
        case release
        case hintButtonClicked(indexPath: IndexPath)
    }
    
    enum OutputEvent {
        case volumeChanged(value: Float)
        case reloadData
        case showScenario(scenario: Scenario?)
        case showTranslation(translation: String)
    }
    /// 播放音檔模式
    enum AudioPlaybackMode {
        /// apple AVSpeechSynthesizer
        case speechSynthesizer
        /// AVAudioPlayer
        case audioPlayer
    }
    private let chatMannager = AIChatManager(service: AIServiceManager.shared.service)
    private let audioMagager = AudioManager.shared
    private let conversationManager = AIAudioConversationManager(service: AIServiceManager.shared.service as! AIAudioServiceProtocol, scenario: nil)
    private(set) var audioResults: [AudioResult] = []
    var audioPlaybackMode: AudioPlaybackMode = .audioPlayer
    
    init(scenario: Scenario?) {
        super.init()
        audioMagager.delegate = self
        initialScenario(initialScenario: scenario)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    override func handleInputEvent(inputEvent: InputEvent) {
        switch inputEvent {
        case .startRecording:
            self.controlRecorder(isStart: true)
        case .stopRecording:
            self.controlRecorder(isStart: false)
        case .userInput(input: let input):
            self.userInput(input: input)
        case .playAudio(indexPath: let indexPath):
            self.playAudio(indexPath: indexPath)
        case .release:
            self.release()
        case .hintButtonClicked(indexPath: let indexPath):
            self.hintButtonClicked(indexPath: indexPath)
        }
    }
    
    private func hintButtonClicked(indexPath: IndexPath) {
        let text = audioResults[indexPath.row].text
        performAction(chatMannager.translation(input: text, to: .TraditionalChinese))
            .sink { _ in
                
            } receiveValue: { [weak self] chatMessage in
                self?.sendOutputEvent(.showTranslation(translation: chatMessage.message))
            }
            .store(in: &subscriptions)
    }
    
    /// 初始化情境
    private func initialScenario(initialScenario: Scenario?) {
        guard let initialScenario = initialScenario else { return }
        conversationManager.setInitialScenario(initialScenario: initialScenario)
        let publisher = conversationManager.generateAIResponse()
        performAction(publisher)
            .sink { _ in
                
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                self.playAudio(audioResult: result)
                self.handleResponse(audioResults: [result])
                self.sendOutputEvent(.showScenario(scenario: conversationManager.scenario))
            }
            .store(in: &subscriptions)
    }
    
    private func release() {
        audioMagager.stopRecording()
        audioMagager.stopAudio()
        audioMagager.deleteAllFilesInDirectory()
    }
    
    private func handleResponse(audioResults: [AudioResult]) {
        for audioResult in audioResults {
            audioResult.printResult()
        }
        self.audioResults.append(contentsOf: audioResults)
        sendOutputEvent(.reloadData)
    }
    
    /// 用輸入匡模擬講話(測試用)
    private func userInput(input: String) {
        performAction(conversationManager.simulateEnglishOnlyConversation(input: input))
            .sink { completion in
                if case .failure(let error) = completion {
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self] result in
                self?.playAudio(audioResult: result)
                self?.handleResponse(audioResults: [result])
            }
            .store(in: &subscriptions)
    }
    private func playAudio(indexPath: IndexPath) {
        playAudio(audioResult: audioResults[indexPath.row])
    }
    
    private func playAudio(audioResult: AudioResult) {
        switch audioPlaybackMode {
        case .speechSynthesizer:
            audioMagager.speech(text: audioResult.text)
        case .audioPlayer:
            if let url = audioResult.audioURL {
                audioMagager.playAudio(from: url)
            }else {
                // google gemini 沒有文字轉語音功能所以還是只能用speechSynthesizer
                audioMagager.speech(text: audioResult.text)
            }
        }
    }
    
    private func controlRecorder(isStart: Bool) {
        isStart ? audioMagager.startRecording() : audioMagager.stopRecording()
    }
    
    
}

extension ConversationViewModel: AudioManagerDelegate {
    
    func didFinishRecordingAt(at url: URL) {
        performAction(conversationManager.simulateEnglishOnlyConversation(audioURL: url))
            .sink { completion in
                if case .failure(let error) = completion {
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self] result in
                self?.playAudio(audioResult: result.aiSpeechResult)
                self?.handleResponse(audioResults: [result.userSpeechResult, result.aiSpeechResult])
            }
            .store(in: &subscriptions)
    }
    
    func volumeChanged(decibels: Float) {
        sendOutputEvent(.volumeChanged(value: decibels))
    }
    
    
}
