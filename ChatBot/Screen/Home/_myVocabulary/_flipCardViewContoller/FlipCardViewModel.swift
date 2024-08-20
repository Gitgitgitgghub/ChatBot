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
    }
    
    enum OutputEvent {
        case flipCard(index: Int)
    }
    
    let maxCount = 30
    /// 單字資料源
    @Published var vocabularies: [VocabularyModel] = []
    /// 卡片翻轉狀態
    private(set) var flippedStates: [Int: Bool] = [:]
    private let vocabularyManager = VocabularyManager.share
    
    func bindInputEvent() {
        inputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .fetchVocabularies:
                    self.fetchVocabularies()
                case .flipCard(index: let index):
                    self.flipCard(index: index)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func flipCard(index: Int) {
        var current = flippedStates[index] ?? false
        current.toggle()
        flippedStates[index] = current
        outputSubject.send(.flipCard(index: index))
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
