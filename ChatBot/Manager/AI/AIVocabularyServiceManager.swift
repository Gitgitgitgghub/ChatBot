//
//  AIVocabularyServiceManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/13.
//

import Foundation
import Combine

typealias WordDetail = AIVocabularyServiceManager.WordDetail
typealias SuggestionResponse = AIVocabularyServiceManager.SuggestionResponse
typealias ResponseVocabularyModel = AIVocabularyServiceManager.ResponseVocabularyModel


class AIVocabularyServiceManager {
    
    struct WordDetail: Codable, Equatable {
        static func == (lhs: AIVocabularyServiceManager.WordDetail, rhs: AIVocabularyServiceManager.WordDetail) -> Bool {
            return lhs.kkPronunciation == rhs.kkPronunciation &&
            lhs.sentence == rhs.sentence
        }
        
        let word: String
        let kkPronunciation: String
        let sentence: WordSentence
    }
    
    struct SuggestionResponse: Codable {
        let correctWord: String?
        let suggestion: String?
    }
    
    struct ResponseVocabularyModel: Codable {
        var wordEntry: WordEntry
        var wordSentences: [WordSentence]
        var kkPronunciation: String
    }
    
    let service: AIVocabularyServiceProtocol
    
    init(service: AIVocabularyServiceProtocol) {
        self.service = service
    }
    
    func fetchWordDetails(words: [String]) -> AnyPublisher<[WordDetail], any Error> {
        return service.fetchWordDetails(words: words)
    }
    
    func checkSpelling(forWord word: String) -> AnyPublisher<Result<String, AIServiceError>, any Error> {
        return service.checkSpelling(forWord: word)
    }
    
    func fetchVocabularyData(forWord word: String) -> AnyPublisher<VocabularyModel, any Error> {
        return service.fetchVocabularyData(forWord: word)
    }
    
    func fetchVocabularyModel(forWord word: String) -> AnyPublisher<Result<VocabularyModel, AIServiceError>, any Error> {
        return service.fetchVocabularyModel(forWord: word)
    }
    
    func fetchSingleWordDetail(word: String) -> AnyPublisher<WordDetail, any Error> {
        return service.fetchSingleWordDetail(word: word)
    }
    
}
