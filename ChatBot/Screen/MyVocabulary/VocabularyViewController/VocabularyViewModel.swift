//
//  VocabularyViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/13.
//

import Foundation

class VocabularyViewModel: BaseViewModel<VocabularyViewModel.InputEvent, VocabularyViewModel.OutputEvent> {
    
    enum InputEvent {
        
    }
    
    enum OutputEvent {
        case scrollTo(index: Int)
    }
    
    let vocabularies: [VocabularyModel]
    let startIndex: Int
    let openAI: OpenAIService
    private(set) var displayEnable = false
    
    init(vocabularies: [VocabularyModel], startIndex: Int, openAI: OpenAIService) {
        self.vocabularies = vocabularies
        self.startIndex = startIndex
        self.openAI = openAI
    }
    
    func fetchVocabularies() {
        displayEnable = true
        outputSubject.send(.scrollTo(index: startIndex))
        Task {
                do {
                    let details = try await openAI.fetchWordDetails(words: ["apple", "rain"])
                    for detail in details {
                        print("word: \(detail.word)")
                        print("KK Phonetic: \(detail.kkPronunciation)")
                        print("Sentence: \(detail.sentence.sentence)")
                        print("Translation: \(detail.sentence.translation)")
                    }
                } catch {
                    print("Failed to get word details: \(error)")
                }
            }
    }
    
    func bindInput() {
        inputSubject
            .sink { event in
                
            }
            .store(in: &subscriptions)
    }
    
}
