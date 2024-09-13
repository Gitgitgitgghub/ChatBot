//
//  VocabulayExamQuestion.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/24.
//

import Foundation
import UIKit



enum EnglishExamQuestion: ExamQuestionProtocol {
    
    case vocabulayExamQuestion(data: VocabularyExamQuestion)
    case grammarExamQuestion(data: GrammarExamQuestion)
    case readingExamQuestion(data: ReadingExamQuestion)
    
    var questionText: String {
        switch self {
        case .vocabulayExamQuestion(let data):
            return data.questionText
        case .grammarExamQuestion(let data):
            return data.questionText
        case .readingExamQuestion(data: let data):
            return data.questionText
        }
    }
    var options: [String] {
        switch self {
        case .vocabulayExamQuestion(let data):
            return data.options
        case .grammarExamQuestion(let data):
            return data.options
        case .readingExamQuestion(let data):
            return data.options
        }
    }
    var correctAnswer: String {
        switch self {
        case .vocabulayExamQuestion(let data):
            return data.correctAnswer
        case .grammarExamQuestion(let data):
            return data.correctAnswer
        case .readingExamQuestion(let data):
            return data.correctAnswer
        }
    }
    
    var userSelecedAnswer: String? {
        switch self {
        case .vocabulayExamQuestion(let data):
            return data.userSelecedAnswer
        case .grammarExamQuestion(let data):
            return data.userSelecedAnswer
        case .readingExamQuestion(let data):
            return data.userSelecedAnswer
        }
    }
}

//MARK: 對[EnglishExamQuestion] extension
extension Array where Element == EnglishExamQuestion {
    
    func questionNumbers() -> [String] {
        var result: [String] = []
        for (index, question) in self.enumerated() {
            switch question {
            // 閱讀測驗
            case .readingExamQuestion(let data):
                if data.isArticle() {
                    result.append("題")
                } else {
                    result.append("\(index)")
                }
            default:
                result.append("\(index + 1)")
            }
        }
        return result
    }
    
    // 還原成ReadingExamArticle
    func restoreReadingExamArticle() -> ReadingExamArticle? {
        var articleText: String?
        var articleTranslation: String?
        var readingQuestions: [ReadingExamQuestion] = []
        for question in self {
            if case .readingExamQuestion(let data) = question {
                if data.isArticle() {
                    articleText = data.questionText
                    articleTranslation = data.reason
                } else {
                    readingQuestions.append(data)
                }
            }
        }
        guard let articleText = articleText, let articleTranslation = articleTranslation else {
            return nil
        }
        return ReadingExamArticle(
            article: articleText,
            articleTranslation: articleTranslation,
            questions: readingQuestions
        )
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
        case .readingExamQuestion(var data):
            data.userSelecedAnswer = selectedOption
            updatedQuestion = .readingExamQuestion(data: data)
        }
        return (updatedQuestion, updatedQuestion.isCorrect())
    }
    
    func clearAnswer() -> EnglishExamQuestion {
        return selectAnswer(nil).updatedQuestion
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
    
    /// 確保選項的正確性
    /// 因為有時候選項沒有正確答案
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
    
    func convertToNote() -> MyNote? {
        let title = grammarPointDescription
        var noteBody = "\(questionText)\n"
        for option in options {
            noteBody.append(option)
            noteBody.append("\n")
        }
        noteBody.append(displayReason)
        return MyNote(title: title ?? "", attributedString: .init(string: noteBody, attributes: [.font: SystemDefine.Message.defaultTextFont,
                                                                                                 .foregroundColor: UIColor.white]))
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

//MARK: - 閱讀測驗
struct ReadingExamArticle: Codable {
    
    let article: String
    let articleTranslation: String
    let questions: [ReadingExamQuestion]
    
    /// 將article也轉換成ReadingExamQuestion方便處理
    func toReadingExamQuestions() -> [EnglishExamQuestion] {
        let articleQuestion = EnglishExamQuestion.readingExamQuestion(data: ReadingExamQuestion(
            questionText: self.article,
            options: [],
            correctAnswer: "",
            userSelecedAnswer: "",
            reason: articleTranslation
        ))
        var allQuestions = [articleQuestion]
        allQuestions.append(contentsOf: questions.map({ EnglishExamQuestion.readingExamQuestion(data: $0) }))
        return allQuestions
    }
    
    func convertToNote() -> MyNote? {
        let title = "閱讀測驗"
        let noteBody = NSMutableAttributedString(string: article + "\n\n" + articleTranslation, attributes: [.font: SystemDefine.Message.defaultTextFont,
                                                                        .foregroundColor: UIColor.white])
        guard let note = MyNote(title: title, attributedString: noteBody)
        else { return nil }
        for question in questions {
            let questionText = question.questionText
            let reasonText = "\n\n\(question.reason)"
            var optionText = ""
            for option in question.options {
                optionText += "\n\n\(option)"
            }
            let body = questionText + reasonText + optionText
            let attr = NSMutableAttributedString(string: body,
                                                 attributes: [.font: SystemDefine.Message.defaultTextFont,
                                                                            .foregroundColor: UIColor.white])
            if let range = body.range(of: question.correctAnswer) {
                let nsRange = NSRange(range, in: body)
                attr.addAttribute(.foregroundColor, value: UIColor.systemGreen, range: nsRange)
            }
            if let comment = MyComment(attributedString: attr) {
                note.comments.append(comment)
            }
        }
        return note
    }
    
    func printQuestion() {
        print("文章:\n\(article)")
        print("-------------------------------------------------------------")
        for question in questions {
            question.printQuestion()
        }
    }
}

struct ReadingExamQuestion: Codable, ExamQuestionProtocol {
    
    var questionText: String
    var options: [String]
    var correctAnswer: String
    var userSelecedAnswer: String?
    var reason: String
    
    func isArticle() -> Bool {
        return options.isEmpty && correctAnswer.isEmpty
    }
}

