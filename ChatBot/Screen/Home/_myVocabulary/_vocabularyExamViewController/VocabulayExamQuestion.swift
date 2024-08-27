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
    var userSelecedAnswer: String? { get set }
    /// 是否回答正確
    func isCorrect() -> Bool
    /// 列印問題
    func printQuestion()
}

extension ExamQuestion {
    
    
    func isCorrect() -> Bool {
        guard let userSelecedAnswer = self.userSelecedAnswer else { return false }
        return userSelecedAnswer == correctAnswer
    }
    
    func printQuestion() {
        print("Question: \(questionText)")
        for (index, option) in options.enumerated() {
            print("\(index + 1): \(option)")
        }
    }
    
}

struct GrammaExamQuestion: ExamQuestion {
    
    var questionText: String
    var options: [String]
    var correctAnswer: String
    var userSelecedAnswer: String?
    var reason: String?
    
}


struct VocabulayExamQuestion: ExamQuestion {
    
    var questionText: String
    var options: [String]
    var correctAnswer: String
    var userSelecedAnswer: String?
    var original: VocabularyModel?
    
    // 初始化方法
    init(questionText: String, options: [String], correctAnswer: String) {
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
    }
    
}
