//
//  ExamQuestion.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/28.
//

import Foundation
import Combine

protocol ExamQuestionProtocol: Codable {
    
    var questionText: String { get }
    var options: [String] { get }
    var correctAnswer: String { get }
    var userSelecedAnswer: String? { get }
    /// 是否回答正確
    func isCorrect() -> Bool
    /// 列印問題
    func printQuestion()
}

extension ExamQuestionProtocol {
    
    
    func isCorrect() -> Bool {
        return userSelecedAnswer == correctAnswer
    }
    
    func printQuestion() {
        print("Question: \(questionText)\n correctAnswer: \(correctAnswer)")
        for (index, option) in options.enumerated() {
            print("\(index + 1): \(option)")
        }
    }
    
}

protocol EnglishQuestionGeneratorProtocol {
    
    func generateQuestion(limit: Int) -> AnyPublisher<[EnglishExamQuestion], Error>
    
}
