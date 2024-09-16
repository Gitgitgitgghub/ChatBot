//
//  AIEnglishQuestonServiceProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/16.
//

import Foundation
import Combine

protocol AIEnglishQuestonServiceProtocol: AnyObject where Self: AIServiceProtocol {
    
    /// 取得單字克漏字問題
    func fetchVocabularyClozeQuestions(vocabularies: [VocabularyModel]) -> AnyPublisher<[EnglishExamQuestion], Error>
    /// 取得文法問題
    func fetchGrammarQuestion(grammarPoint: TOEICGrammarPoint?, limit: Int) -> AnyPublisher<[EnglishExamQuestion], Error>
    /// 取得閱讀測驗問題
    func fetchTOEICReadingQuestion() -> AnyPublisher<[EnglishExamQuestion], Error>
}
