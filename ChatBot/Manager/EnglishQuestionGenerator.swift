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
    private let vocabularyService: VocabularyService
    private var questionType: QuestionType
    private let letter: String
    private let sortOption: SystemDefine.VocabularyExam.SortOption
    ///
    private(set) var vocabularies: [VocabularyModel]
    
    init(vocabularyManager: VocabularyManager, vocabularyService: VocabularyService, questionType: QuestionType, vocabularies: [VocabularyModel] = []) {
        self.vocabularyManager = vocabularyManager
        self.vocabularyService = vocabularyService
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
        
        return fetchVocabularies(limit: limit)
            .tryMap { [weak self] vocabularies in
                guard let `self` = self else { return [] }
                return try self.convertVocabulriesToQuestions(vocabularies: vocabularies)
            }
            .eraseToAnyPublisher()
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
                return self.vocabularyService.fetchVocabularyClozeQuestions(vocabularies: vocabularies)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchVocabularies(limit: Int) -> AnyPublisher<[VocabularyModel], Error> {
        ///
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
            // 使用当前的 vocabulary 生成问题
            let questionWord = vocabulary.wordEntry.word
            let correctDefinition = vocabulary.wordEntry.definitions.randomElement()?.definition.replacingOccurrences(of: " ", with: "") ?? ""
            // 随机选择两个错误的定义作为错误选项
            let otherVocabularies = vocabularies.filter { $0 != vocabulary }.shuffled()
            let wrongDefinition1 = otherVocabularies.randomElement()?.wordEntry.definitions.randomElement()?.definition.replacingOccurrences(of: " ", with: "") ?? ""
            let wrongDefinition2 = otherVocabularies.randomElement()?.wordEntry.definitions.randomElement()?.definition.replacingOccurrences(of: " ", with: "") ?? ""
            // 将正确答案和错误答案混合在一起
            let options = [correctDefinition, wrongDefinition1, wrongDefinition2].shuffled()
            // 创建一个 VocabulayExamQuestion 对象并添加到 questions 数组中
            let question = VocabulayExamQuestion(questionText: questionWord, options: options, correctAnswer: correctDefinition, original: vocabulary)
            questions.append(question)
        }
        return questions
    }
    
    
}
