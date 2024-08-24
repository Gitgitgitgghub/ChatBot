//
//  VocabularyExamViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/23.
//

import Combine
import Foundation


class VocabularyExamViewModel: BaseViewModel<VocabularyExamViewModel.InputEvent, VocabularyExamViewModel.OutputEvent> {
    
    enum InputEvent {
        case fetchQuestion
        case currentIndexChange(currentIndex: Int)
        case onOptionSelected(question: VocabulayExamQuestion, selectedOption: String?)
        case retakeExam
    }
    
    enum OutputEvent {
        case reloadUI
        case indexChange(string: String)
        case notEnough
        case scrollToNextQuestion
        case examCompleted(correctCount: Int, wrongCount: Int)
    }
    /// 排序方式
    private(set) var sortOption: SystemDefine.VocabularyExam.SortOption
    /// 搜索的字母
    private(set) var letter: String
    private let vocabularyManager = VocabularyManager.share
    /// 當前題目
    private(set) var questions: [VocabulayExamQuestion] = []
    /// 回答正確的題目
    private(set) var correctAnswerQuestions: [VocabulayExamQuestion] = []
    /// 回答錯誤的題目
    private(set) var wrongAnswerQuestions: [VocabulayExamQuestion] = []
    /// 當前題目位置
    private(set) var currentIndex: Int = 0
    /// 單字原始資料
    private(set) var originalData: [String : VocabularyModel] = [:]
    /// 最多題目數量
    private let limit = 30
    
    init(sortOption: SystemDefine.VocabularyExam.SortOption, letter: String) {
        self.sortOption = sortOption
        self.letter = letter
    }
    
    func bindInputEvent() {
        inputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .fetchQuestion:
                    self.fetchQuestion()
                case .currentIndexChange(currentIndex: let currentIndex):
                    self.currentIndexChange(currentIndex: currentIndex)
                case .onOptionSelected(question: let question, selectedOption: let selectedOption):
                    self.onOptionSelected(question: question, selectedOption: selectedOption)
                case .retakeExam:
                    self.retakeExam()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func retakeExam() {
        questions = wrongAnswerQuestions
        correctAnswerQuestions = []
        wrongAnswerQuestions = []
        outputSubject.send(.reloadUI)
    }
    
    private func onOptionSelected(question: VocabulayExamQuestion, selectedOption: String?) {
        let isCorrect = question.isCorrectAnswer(selectedOption)
        if isCorrect {
            correctAnswerQuestions.append(question)
        }else {
            wrongAnswerQuestions.append(question)
        }
        if hasNextQuestion() {
            outputSubject.send(.scrollToNextQuestion)
        }else {
            outputSubject.send(.examCompleted(correctCount: correctAnswerQuestions.count, wrongCount: wrongAnswerQuestions.count))
        }
        changeFamalirity(question: question, isCorrect: isCorrect)
    }
    
    /// 更改熟悉度
    private func changeFamalirity(question: VocabulayExamQuestion, isCorrect: Bool) {
        guard let vocabulary = originalData[question.questionText] else { return }
        let score = isCorrect ? 1 : -1
        vocabulary.familiarity += score
        vocabularyManager.saveVocabulay(vocabulary: vocabulary)
            .sink { _ in
                
            } receiveValue: { _ in
                
            }
            .store(in: &subscriptions)
    }
    
    /// 是否還有下一題
    private func hasNextQuestion() -> Bool {
        return currentIndex < questions.count - 1
    }
    
    private func currentIndexChange(currentIndex: Int) {
        self.currentIndex = currentIndex
        let title = "第\(currentIndex + 1)題"
        outputSubject.send(.indexChange(string: title))
    }
    
    private func fetchQuestion() {
        let letter = (self.letter == "隨機") ? nil : self.letter
        let publish: AnyPublisher<[VocabularyModel], Error>
        switch sortOption {
        case .familiarity:
            publish = vocabularyManager.fetchVocabulary(letter: letter, limit: self.limit, useFamiliarity: true)
        case .lastWatchTime:
            publish = vocabularyManager.fetchVocabulary(letter: letter, limit: self.limit, useLastViewedTime: true)
        case .star:
            publish = vocabularyManager.fetchVocabulary(letter: letter, limit: self.limit, isStarOnly: true)
        }
        publish
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: { [weak self] results in
                self?.convertToDictionary(vocabularies: results)
                self?.generateQuestionAndReloadUI()
            })
            .store(in: &subscriptions)
    }
    
    /// 單字串轉換成字典
    private func convertToDictionary(vocabularies: [VocabularyModel]) {
        for vocabulary in vocabularies {
            originalData[vocabulary.wordEntry.word] = vocabulary
        }
    }
    
    /// 產生題目，至少要三個單字才能產生
    private func generateQuestionAndReloadUI() {
        guard originalData.values.count >= 3 else {
            outputSubject.send(.notEnough)
            return
        }
        let vocabularies = Array(originalData.values).shuffled()
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
            let question = VocabulayExamQuestion(questionText: questionWord, options: options, correctAnswer: correctDefinition)
            questions.append(question)
        }
        self.questions = questions
        outputSubject.send(.reloadUI)
    }
    
}
