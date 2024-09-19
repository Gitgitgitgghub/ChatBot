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
    }
    
    enum OutputEvent {
        case volumeChanged(value: Float)
        case reloadData
    }
    
    private let audioMagager = AudioManager.shared
    private let audioServiceManager = AIAudioServiceManager(service: OpenAIService(apiKey: openAIKey), initialScenario: "")
    private(set) var audioResults: [AudioResult] = []
    
    override init() {
        super.init()
        audioMagager.delegate = self
        initialScenario()
    }
    
    func bindInputEvent() {
        inputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .startRecording:
                    self.controlRecorder(isStart: true)
                case .stopRecording:
                    self.controlRecorder(isStart: false)
                case .userInput(input: let input):
                    self.userInput(input: input)
                }
            }
            .store(in: &subscriptions)
    }
    
    /// 初始化情境
    private func initialScenario() {
        performAction(audioServiceManager.generateAIResponseWithInitialScenario())
            .sink { _ in
                
            } receiveValue: { [weak self] result in
                self?.playAudio(audioResult: result)
                self?.handleResponse(audioResults: [result])
            }
            .store(in: &subscriptions)
    }
    
    private func handleResponse(audioResults: [AudioResult]) {
        self.audioResults.append(contentsOf: audioResults)
        outputSubject.send(.reloadData)
    }
    
    /// 用輸入匡模擬講話(測試用)
    private func userInput(input: String) {
        performAction(audioServiceManager.simulateEnglishOnlyConversation(input: input))
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
    
    private func playAudio(audioResult: AudioResult) {
        guard let url = audioResult.audioURL else { return }
        audioMagager.playAudio(from: url)
    }
    
    private func controlRecorder(isStart: Bool) {
        isStart ? audioMagager.startRecording() : audioMagager.stopRecording()
    }
    
    
}

extension ConversationViewModel: AudioManagerDelegate {
    
    func didFinishRecordingAt(at url: URL) {
        performAction(audioServiceManager.simulateEnglishOnlyConversation(audioURL: url))
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
        outputSubject.send(.volumeChanged(value: decibels))
    }
    
    
}
