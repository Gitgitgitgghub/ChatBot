//
//  VocabulayExamQuestion.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/24.
//

import Foundation

protocol ExamQuestion: Codable {
    
    var questionText: String { get set }
    var options: [String] { get set }
    var correctAnswer: String { get set }
    /// 是否回答正確
    func isCorrectAnswer(_ selectedAnswer: String?) -> Bool
    /// 列印問題
    func printQuestion()
}

extension ExamQuestion {
    
    
    func isCorrectAnswer(_ selectedAnswer: String?) -> Bool {
        return selectedAnswer == correctAnswer
    }
    
    func printQuestion() {
        print("Question: \(questionText)")
        for (index, option) in options.enumerated() {
            print("\(index + 1): \(option)")
        }
    }
    
}


struct VocabulayExamQuestion: ExamQuestion {
    
    var questionText: String
    var options: [String]
    var correctAnswer: String
    var original: VocabularyModel?
    
    // 初始化方法
    init(questionText: String, options: [String], correctAnswer: String, original: VocabularyModel?) {
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.original = original
    }
    
    
    
}
