//
//  FlipCardViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/20.
//

import Foundation


class FlipCardViewModel: BaseViewModel<FlipCardViewModel.InputEvent, FlipCardViewModel.OutputEvent> {
    
    enum InputEvent {
        case fetchVocabularies
        case flipCard(index: Int)
        case currentPageChange(index: Int)
        case toggleStar(index: Int)
    }
    
    enum OutputEvent {
        case flipCard(index: Int)
        case toast(message: String)
        case reloadCurrent
    }
    
    let maxCount = 30
    /// 單字資料源
    @Published var vocabularies: [VocabularyModel] = []
    /// 卡片翻轉狀態
    private(set) var flippedStates: [Int: Bool] = [:]
    private let vocabularyManager = VocabularyManager.share
    
    override func handleInputEvent(inputEvent: InputEvent) {
        switch inputEvent {
        case .fetchVocabularies:
            self.fetchVocabularies()
        case .flipCard(index: let index):
            self.flipCard(index: index)
        case .currentPageChange(index: let index):
            self.currentPageChange(index: index)
        case .toggleStar(let index):
            self.toggleStar(index: index)
        }
    }
    
    private func currentPageChange(index: Int) {
        let vocabulary = vocabularies[index]
        vocabulary.updateLastViewedTime()
        vocabularyManager.saveVocabulay(vocabulary: vocabulary)
            .sink { _ in
                
            } receiveValue: { _ in
                
            }
            .store(in: &subscriptions)
    }
    
    private func toggleStar(index: Int) {
        let vocabulary = vocabularies[index]
        vocabulary.isStar.toggle()
        vocabularyManager.saveVocabulay(vocabulary: vocabulary)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    vocabulary.isStar.toggle()
                    self?.sendOutputEvent(.toast(message: "操作失敗：\(error.localizedDescription)"))
                }
            } receiveValue: { [weak self] _ in
                self?.sendOutputEvent(.reloadCurrent)
            }
            .store(in: &subscriptions)
    }
    
    private func flipCard(index: Int) {
        var current = flippedStates[index] ?? false
        current.toggle()
        flippedStates[index] = current
        sendOutputEvent(.flipCard(index: index))
    }
    
    private func fetchVocabularies() {
        vocabularyManager.fetchRandomVocabularies(count: maxCount)
            .sink { _ in
                
            } receiveValue: { [weak self] results in
                self?.vocabularies = results
            }
            .store(in: &subscriptions)
    }
    
}
