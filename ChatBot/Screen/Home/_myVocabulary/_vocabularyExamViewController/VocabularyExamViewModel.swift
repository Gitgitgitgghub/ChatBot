//
//  VocabularyExamViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/23.
//

import Combine
import Foundation
import UIKit


class VocabularyExamViewModel: BaseViewModel<VocabularyExamViewModel.InputEvent, VocabularyExamViewModel.OutputEvent> {
    
    typealias QuestionType = SystemDefine.VocabularyExam.QuestionType
    
    enum InputEvent {
        case fetchQuestion
        case currentIndexChange(currentIndex: Int)
        case onOptionSelected(question: VocabulayExamQuestion, selectedOption: String?)
        case retakeExam
        case startExam
        case pauseExam
        case resumeExam
        case switchAnswerMode
    }
    
    enum OutputEvent {
        case indexChange(string: String)
        case error(message: String)
        case scrollToNextQuestion
        case updateTimer(string: NSAttributedString)
    }
    
    enum ExamState: Equatable {
        case answerMode
        case preparing
        case ready
        case started
        case paused
        case ended(correctCount: Int, wrongCount: Int)
    }
    
    private let vocabularyManager = VocabularyManager.share
    private var questionType: QuestionType
    /// 當前題目
    private(set) var questions: [VocabulayExamQuestion] = []
    /// 回答正確的題目
    private(set) var correctAnswerQuestions: [VocabulayExamQuestion] = []
    /// 回答錯誤的題目
    private(set) var wrongAnswerQuestions: [VocabulayExamQuestion] = []
    /// 當前題目位置
    private(set) var currentIndex: Int = 0
    /// 最多題目數量
    private let limit = 3
    /// 計時器
    private let timerManager = TimerManager()
    /// 當前考試狀態
    @Published private(set) var examState: ExamState = .preparing
    /// 題目產生器
    private var questionGenerator: EnglishQuestionGenerator
    
    init(questionType: QuestionType, vocabularies: [VocabularyModel]) {
        self.questionType = questionType
        questionGenerator = VocabularyWordQuestionGenerator(vocabularyManager: vocabularyManager, vocabularyService: .init(), questionType: questionType, vocabularies: vocabularies)
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
                case .startExam:
                    self.startExam()
                case .pauseExam:
                    self.pauseExam()
                case .resumeExam:
                    self.resumeExam()
                case .switchAnswerMode:
                    self.switchAnswerMode()
                }
            }
            .store(in: &subscriptions)
        timerManager.$counter
            .receive(on: RunLoop.main)
            .map({ second in
                let fullText = "已用時\(second)秒"
                let attr = NSMutableAttributedString(
                    string: fullText,
                    attributes: [.foregroundColor: UIColor.systemBrown]
                )
                let secondRange = NSRange(location: 3, length: String(second).count)
                attr.addAttribute(.foregroundColor, value: UIColor.systemPink, range: secondRange)
                return attr
            })
            .sink { [weak self] timerText in
                self?.outputSubject.send(.updateTimer(string: timerText))
            }
            .store(in: &subscriptions)
    }
    
    private func switchAnswerMode() {
        examState = .answerMode
    }
    
    private func startExam() {
        examState = .started
        timerManager.startTimer()
    }
    private func pauseExam() {
        // 當考試狀態為.answerMode時按鈕功能會變為重考，其餘才是暫停考試
        if examState == .answerMode {
            retakeExam()
        }else {
            examState = .paused
            timerManager.stopTimer()
            outputSubject.send(.updateTimer(string: .init(string: "已暫停", attributes: [.foregroundColor : UIColor.systemRed])))
        }
    }
    
    private func resumeExam() {
        startExam()
    }
    
    private func retakeExam() {
        questions = wrongAnswerQuestions
        correctAnswerQuestions = []
        wrongAnswerQuestions = []
        timerManager.resetTimer()
        examState = .ready
    }
    
    private func onOptionSelected(question: VocabulayExamQuestion, selectedOption: String?) {
        if let index = questions.firstIndex(where: { $0.questionText == question.questionText }) {
            questions[index].userSelecedAnswer = selectedOption
            let updateQuestion = questions[index]
            let isCorrect = updateQuestion.isCorrect()
            if isCorrect {
                correctAnswerQuestions.append(updateQuestion)
            }else {
                wrongAnswerQuestions.append(updateQuestion)
            }
            if hasNextQuestion() {
                outputSubject.send(.scrollToNextQuestion)
            }else {
                examState = .ended(correctCount: correctAnswerQuestions.count, wrongCount: wrongAnswerQuestions.count)
                timerManager.stopTimer()
            }
            changeFamalirity(question: updateQuestion, isCorrect: isCorrect)
        }
    }
    
    /// 更改熟悉度
    private func changeFamalirity(question: VocabulayExamQuestion, isCorrect: Bool) {
        guard let vocabulary = question.original else { return }
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
        let title = "第\(currentIndex + 1)/\(questions.count)題"
        outputSubject.send(.indexChange(string: title))
    }
    
    private func fetchQuestion() {
        questionGenerator
            .generateQuestion(limit: limit)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.outputSubject.send(.error(message: error.localizedDescription))
                }
            } receiveValue: { [weak self] questions in
                guard let `self` = self else { return }
                self.questions = questions
                examState = .ready
            }
            .store(in: &subscriptions)
    }
    
}
