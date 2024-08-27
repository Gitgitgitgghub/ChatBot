//
//  EnglishQuestionGenerator.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/26.
//

import Foundation
import Combine


protocol EnglishQuestionGenerator {
    
    func generateQuestion(limit: Int) -> AnyPublisher<[VocabulayExamQuestion], Error>
    
}

class VocabularyWordQuestionGenerator: EnglishQuestionGenerator {
    
    typealias QuestionType = SystemDefine.VocabularyExam.QuestionType
    
    private let vocabularyManager: VocabularyManager
    private let englishQuestion: EnglishQuestionService
    private var questionType: QuestionType
    private let letter: String
    private let sortOption: SystemDefine.VocabularyExam.SortOption
    ///
    private(set) var vocabularies: [VocabularyModel]
    
    init(vocabularyManager: VocabularyManager, englishQuestion: EnglishQuestionService, questionType: QuestionType, vocabularies: [VocabularyModel] = []) {
        self.vocabularyManager = vocabularyManager
        self.englishQuestion = englishQuestion
        self.questionType = questionType
        self.vocabularies = vocabularies
        switch questionType {
        case .vocabularyWord(letter: let letter, sortOption: let sortOption):
            self.letter = letter
            self.sortOption = sortOption
        case .vocabularyCloze(letter: let letter, sortOption: let sortOption):
            self.letter = letter
            self.sortOption = sortOption
        }
    }
    
    func generateQuestion(limit: Int) -> AnyPublisher<[VocabulayExamQuestion], any Error> {
        switch questionType {
        case .vocabularyWord:
            return generateNormalQuestion(limit: limit)
        case .vocabularyCloze:
            return generateClozeQuestion(limit: limit)
        }
    }
    
    /// 普通的選擇題
    func generateNormalQuestion(limit: Int) -> AnyPublisher<[VocabulayExamQuestion], any Error> {
        return fetchVocabularies(limit: limit)
            .tryMap { [weak self] vocabularies in
                guard let `self` = self else { return [] }
                return try self.convertVocabulriesToQuestions(vocabularies: vocabularies)
            }
            .eraseToAnyPublisher()
    }
    
    /// 克漏字
    func generateClozeQuestion(limit: Int) -> AnyPublisher<[VocabulayExamQuestion], Error> {
        return fetchVocabularies(limit: limit)
            .flatMap { vocabularies -> AnyPublisher<[VocabulayExamQuestion], Error> in
                return self.englishQuestion.fetchVocabularyClozeQuestions(vocabularies: vocabularies)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchVocabularies(limit: Int) -> AnyPublisher<[VocabularyModel], Error> {
        /// 若有帶單字進來就不用查資料庫
        guard vocabularies.isEmpty else {
            return Just(self.vocabularies)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        let letter = (self.letter == "隨機") ? nil : self.letter
        let publish: AnyPublisher<[VocabularyModel], Error>
        switch sortOption {
        case .familiarity:
            publish = vocabularyManager.fetchVocabulary(letter: letter, limit: limit, useFamiliarity: true)
        case .lastWatchTime:
            publish = vocabularyManager.fetchVocabulary(letter: letter, limit: limit, useLastViewedTime: true)
        case .star:
            publish = vocabularyManager.fetchVocabulary(letter: letter, limit: limit, isStarOnly: true)
        }
        return publish
    }
    
    /// 產生題目，至少要三個單字才能產生
    private func convertVocabulriesToQuestions(vocabularies: [VocabularyModel]) throws -> [VocabulayExamQuestion] {
        guard vocabularies.count >= 3 else {
            throw NSError(domain: "題目數量不足", code: -1)
        }
        let vocabularies = vocabularies.shuffled()
        var questions: [VocabulayExamQuestion] = []
        for vocabulary in vocabularies {
            let questionWord = vocabulary.wordEntry.word
            let correctDefinition = vocabulary.wordEntry.definitions.randomElement()?.definition.replacingOccurrences(of: " ", with: "") ?? ""
            var wrongDefinitions: Set<String> = []
            let otherVocabularies = vocabularies.filter { $0 != vocabulary }.shuffled()
            // 選擇兩個不同的錯誤定義
            while wrongDefinitions.count < 2 {
                if let wrongDefinition = otherVocabularies.randomElement()?.wordEntry.definitions.randomElement()?.definition.replacingOccurrences(of: " ", with: ""),
                   wrongDefinition != correctDefinition {
                    wrongDefinitions.insert(wrongDefinition)
                }
            }
            
            let options = [correctDefinition] + Array(wrongDefinitions).shuffled()
            var question = VocabulayExamQuestion(questionText: questionWord, options: options.shuffled(), correctAnswer: correctDefinition)
            question.original = vocabulary
            questions.append(question)
        }
        return questions
    }
    
    
}
