//
//  EnglishExamViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/23.
//

import Combine
import Foundation
import UIKit


class EnglishExamViewModel: BaseViewModel<EnglishExamViewModel.InputEvent, EnglishExamViewModel.OutputEvent> {
    
    typealias QuestionType = SystemDefine.EnglishExam.QuestionType
    
    enum InputEvent {
        case fetchQuestion
        case currentIndexChange(currentIndex: Int)
        case onOptionSelected(question: EnglishExamQuestion, selectedOption: String?)
        case retakeExam
        case startExam
        case pauseExam
        case resumeExam
        case switchAnswerMode
        case addToNote
    }
    
    enum OutputEvent {
        case indexChange(newIndex: Int)
        case scrollToNextQuestion(index: Int)
        case updateTimer(string: NSAttributedString)
        case toast(message: String)
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
    private(set) var questionType: QuestionType
    /// 原始題目(獲取後不進行編輯)
    private(set) var originalQuestions: [EnglishExamQuestion] = []
    /// 當前題目
    private(set) var questions: [EnglishExamQuestion] = []
    /// 回答正確的題目
    private(set) var correctAnswerQuestions: [EnglishExamQuestion] = []
    /// 回答錯誤的題目
    private(set) var wrongAnswerQuestions: [EnglishExamQuestion] = []
    /// 當前題目位置
    private(set) var currentIndex: Int = 0
    /// 最多題目數量
    private let limit = 10
    /// 計時器
    private let timerManager = TimerManager()
    /// 當前考試狀態
    @Published private(set) var examState: ExamState = .preparing
    /// 題目產生器
    private var questionGenerator: EnglishQuestionGeneratorProtocol
    
    init(questionType: QuestionType, vocabularies: [VocabularyModel]) {
        self.questionType = questionType
        questionGenerator = VocabularyWordQuestionGenerator(vocabularyManager: vocabularyManager, englishQuestionService: AIServiceManager.shared.service as! AIEnglishQuestonServiceProtocol, questionType: questionType, vocabularies: vocabularies)
        super.init()
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
                case .addToNote:
                    self.addToNote()
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
    
    private func addToNote() {
        guard let note = getNote() else {
            outputSubject.send(.toast(message: "該題型未開放加入筆記"))
            return }
        NoteManager.shared.saveNote(note)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.outputSubject.send(.toast(message: error.localizedDescription))
                }
            } receiveValue: { [weak self] _ in
                self?.outputSubject.send(.toast(message: "儲存成功"))
            }
            .store(in: &subscriptions)
    }
    
    private func getNote() -> MyNote? {
        guard let question = questions.getOrNil(index: currentIndex) else { return nil }
        switch question {
        case .vocabulayExamQuestion(_):
            return nil
        case .grammarExamQuestion(let data):
            return data.convertToNote()
        case .readingExamQuestion:
            return originalQuestions.restoreReadingExamArticle()?.convertToNote()
        }
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
    
    /// 重做錯題
    private func retakeExam() {
        var newQuestions: [EnglishExamQuestion]
        switch questionType {
        case .vocabularyWord:
            newQuestions = []
        case .vocabularyCloze:
            newQuestions = []
        case .grammar:
            newQuestions = []
        case .reading:
            // 閱讀測驗第一題是文章所以一定要加入
            newQuestions = [questions.first!]
        }
        // 重新作答要清掉用戶選擇的選項
        wrongAnswerQuestions = wrongAnswerQuestions.map({ $0.clearAnswer() })
        newQuestions.append(contentsOf: wrongAnswerQuestions)
        questions = newQuestions
        correctAnswerQuestions = []
        wrongAnswerQuestions = []
        timerManager.resetTimer()
        examState = .ready
    }
    
    private func onOptionSelected(question: EnglishExamQuestion, selectedOption: String?) {
        if let index = questions.firstIndex(where: { $0.questionText == question.questionText }) {
            let (updatedQuestion, isCorrect) = question.selectAnswer(selectedOption)
            questions[index] = updatedQuestion
            if isCorrect {
                correctAnswerQuestions.append(updatedQuestion)
            }else {
                wrongAnswerQuestions.append(updatedQuestion)
            }
            if let nextIndex = hasNextQuestion() {
                outputSubject.send(.scrollToNextQuestion(index: nextIndex))
            }else {
                examState = .ended(correctCount: correctAnswerQuestions.count, wrongCount: wrongAnswerQuestions.count)
                timerManager.stopTimer()
            }
            changeFamalirity(question: updatedQuestion, isCorrect: isCorrect)
        }
    }
    
    /// 更改熟悉度
    private func changeFamalirity(question: EnglishExamQuestion, isCorrect: Bool) {
        if case .vocabulayExamQuestion(let data) = question {
            guard let vocabulary = data.original else { return }
            let score = isCorrect ? 1 : -1
            vocabulary.familiarity += score
            vocabularyManager.saveVocabulay(vocabulary: vocabulary)
                .sink { _ in
                    
                } receiveValue: { _ in
                    
                }
                .store(in: &subscriptions)
        }
    }
    
    /// 是否還有下一題，優先返回下一題再來才是沒作答的題目
    /// 返回nil 就是作答完畢
    private func hasNextQuestion() -> Int? {
        let isLast = currentIndex == questions.count - 1
        let firstUnseletedQuestionIndex = questions.firstIndex(where: { $0.userSelecedAnswer == nil })
        // 全部作答完畢
        if firstUnseletedQuestionIndex == nil {
            return nil
        }else if !isLast {
            // 並非在最後一題返回下一題index
            return currentIndex + 1
        }
        return firstUnseletedQuestionIndex
    }
    
    private func currentIndexChange(currentIndex: Int) {
        self.currentIndex = currentIndex
        outputSubject.send(.indexChange(newIndex: currentIndex))
    }
    
    private func fetchQuestion() {
        performAction(questionGenerator.generateQuestion(limit: limit))
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.outputSubject.send(.toast(message: error.localizedDescription))
                }
            } receiveValue: { [weak self] questions in
                guard let `self` = self else { return }
                self.questions = questions
                self.originalQuestions = questions
                examState = .ready
            }
            .store(in: &subscriptions)
    }
    
}
