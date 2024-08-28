//
//  EnglishQuestionGenerator.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/26.
//

import Foundation
import Combine




class VocabularyWordQuestionGenerator: EnglishQuestionGeneratorProtocol {
    
    typealias QuestionType = SystemDefine.EnglishExam.QuestionType
    
    private let vocabularyManager: VocabularyManager
    private let englishQuestionService: EnglishQuestionService
    private var questionType: QuestionType
    private var letter: String?
    private var sortOption: SystemDefine.EnglishExam.SortOption?
    ///
    private(set) var vocabularies: [VocabularyModel]
    
    init(vocabularyManager: VocabularyManager, englishQuestionService: EnglishQuestionService, questionType: QuestionType, vocabularies: [VocabularyModel] = []) {
        self.vocabularyManager = vocabularyManager
        self.englishQuestionService = englishQuestionService
        self.questionType = questionType
        self.vocabularies = vocabularies
        switch questionType {
        case .vocabularyWord(letter: let letter, sortOption: let sortOption):
            self.letter = letter
            self.sortOption = sortOption
        case .vocabularyCloze(letter: let letter, sortOption: let sortOption):
            self.letter = letter
            self.sortOption = sortOption
        default: break
        }
    }
    
    func generateQuestion(limit: Int) -> AnyPublisher<[EnglishExamQuestion], any Error> {
        switch questionType {
        case .vocabularyWord:
            return generateNormalQuestion(limit: limit)
        case .vocabularyCloze:
            return generateClozeQuestion(limit: limit)
        case .gramma(let type):
            return generateGrammaQuestion(type: type, limit: limit)
        }
    }
    
    func generateGrammaQuestion(type: String, limit: Int) -> AnyPublisher<[EnglishExamQuestion], any Error> {
        return englishQuestionService.fetchGrammarQuestion(limit: limit)
    }
    
    /// 普通的選擇題
    func generateNormalQuestion(limit: Int) -> AnyPublisher<[EnglishExamQuestion], any Error> {
        return fetchVocabularies(limit: limit)
            .tryMap { [weak self] vocabularies in
                guard let `self` = self else { return [] }
                return try self.convertVocabulriesToQuestions(vocabularies: vocabularies)
            }
            .eraseToAnyPublisher()
    }
    
    /// 克漏字
    func generateClozeQuestion(limit: Int) -> AnyPublisher<[EnglishExamQuestion], Error> {
        return fetchVocabularies(limit: limit)
            .flatMap { vocabularies -> AnyPublisher<[EnglishExamQuestion], Error> in
                return self.englishQuestionService.fetchVocabularyClozeQuestions(vocabularies: vocabularies)
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
        guard let sortOption = self.sortOption else {
            return Just([])
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
    private func convertVocabulriesToQuestions(vocabularies: [VocabularyModel]) throws -> [EnglishExamQuestion] {
        guard vocabularies.count >= 3 else {
            throw NSError(domain: "題目數量不足", code: -1)
        }
        let vocabularies = vocabularies.shuffled()
        var questions: [EnglishExamQuestion] = []
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
            var question = VocabularyExamQuestion(questionText: questionWord, options: options.shuffled(), correctAnswer: correctDefinition)
            question.original = vocabulary
            questions.append(EnglishExamQuestion.vocabulayExamQuestion(data: question))
        }
        return questions
    }
    
    
}
