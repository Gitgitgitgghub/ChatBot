//
//  VocabulayExamQuestion.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/24.
//

import Foundation


struct VocabulayExamQuestion {
    
    let questionText: String
    let options: [String]
    let correctAnswer: String
    
    // 初始化方法
    init(questionText: String, options: [String], correctAnswer: String) {
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
    }
    
    // 检查答案是否正确
    func isCorrectAnswer(_ selectedAnswer: String?) -> Bool {
        return selectedAnswer == correctAnswer
    }
    
    // 打印问题和选项（调试用途）
    func printQuestion() {
        print("Question: \(questionText)")
        for (index, option) in options.enumerated() {
            print("\(index + 1): \(option)")
        }
    }
    
}
