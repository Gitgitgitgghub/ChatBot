//
//  VocabulayExamQuestion.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/24.
//

import Foundation



enum EnglishExamQuestion: ExamQuestionProtocol {
    
    case vocabulayExamQuestion(data: VocabularyExamQuestion)
    case grammarExamQuestion(data: GrammarExamQuestion)
    
    var questionText: String {
        switch self {
        case .vocabulayExamQuestion(let data):
            return data.questionText
        case .grammarExamQuestion(let data):
            return data.questionText
        }
    }
    var options: [String] {
        switch self {
        case .vocabulayExamQuestion(let data):
            return data.options
        case .grammarExamQuestion(let data):
            return data.options
        }
    }
    var correctAnswer: String {
        switch self {
        case .vocabulayExamQuestion(let data):
            return data.correctAnswer
        case .grammarExamQuestion(let data):
            return data.correctAnswer
        }
    }
    
    var userSelecedAnswer: String? {
        switch self {
        case .vocabulayExamQuestion(let data):
            return data.userSelecedAnswer
        case .grammarExamQuestion(let data):
            return data.userSelecedAnswer
        }
    }
}

extension EnglishExamQuestion {
    
    func selectAnswer(_ selectedOption: String?) -> (updatedQuestion: EnglishExamQuestion, isCorrect: Bool) {
        var updatedQuestion: EnglishExamQuestion
        switch self {
        case .vocabulayExamQuestion(var data):
            data.userSelecedAnswer = selectedOption
            updatedQuestion = .vocabulayExamQuestion(data: data)
        case .grammarExamQuestion(var data):
            data.userSelecedAnswer = selectedOption
            updatedQuestion = .grammarExamQuestion(data: data)
        }
        return (updatedQuestion, updatedQuestion.isCorrect())
    }
    
}

struct GrammarExamQuestion: Codable {
    
    var questionText: String
    var questionTranslation: String
    var grammarPointDescription: String?
    var options: [String]
    var correctAnswer: String
    var userSelecedAnswer: String?
    var reason: String?
    var displayReason: String {
        var str = ""
        str.append(questionTranslation)
        if let grammarPoint = grammarPointDescription {
            str.append("\n本題考點為:\(grammarPoint)")
        }
        str.append("\n解釋:\n\(reason ?? "")")
        return str
    }
    
    init(questionText: String, questionTranslation: String, options: [String], correctAnswer: String, reason: String? = nil) {
        self.questionText = questionText
        self.questionTranslation = questionTranslation
        self.options = options
        self.correctAnswer = correctAnswer
        self.reason = reason
    }
    
    mutating func ensureOptionsValid() {
        guard self.options.isNotEmpty else { return }
        let currectAndswer = self.correctAnswer.replacingOccurrences(of: " ", with: "")
        let options = self.options.map({ $0.replacingOccurrences(of: " ", with: "") })
        for option in options {
            if option == currectAndswer {
                return
            }
        }
        self.options[0] = currectAndswer
        self.options.shuffle()
    }
    
}


struct VocabularyExamQuestion: Codable {
    
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
    
    // 自定CodingKeys
    enum CodingKeys: String, CodingKey {
        case questionText
        case options
        case correctAnswer
        case userSelecedAnswer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.questionText = try container.decode(String.self, forKey: .questionText)
        self.options = try container.decode([String].self, forKey: .options)
        self.correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
        self.userSelecedAnswer = try container.decodeIfPresent(String.self, forKey: .userSelecedAnswer)
        self.original = nil  // original 不参与解码，设置为 nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(questionText, forKey: .questionText)
        try container.encode(options, forKey: .options)
        try container.encode(correctAnswer, forKey: .correctAnswer)
        try container.encodeIfPresent(userSelecedAnswer, forKey: .userSelecedAnswer)
    }
}

