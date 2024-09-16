//
//  AIVocabularyServiceProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/16.
//

import Foundation
import Combine

protocol AIVocabularyServiceProtocol: AnyObject where Self: AIServiceProtocol {
    
    /// 查詢多單字 kk音標，句子，翻譯
    /// 因為一次帶多個給ai慢到會timeout
    /// 所以改採並行機制
    func fetchWordDetails(words: [String]) -> AnyPublisher<[WordDetail], Error>
    /// 拼字檢查，若錯誤可獲取相關建議的單字
    func checkSpelling(forWord word: String) -> AnyPublisher<Result<String, AIServiceError>, Error>
    
    func fetchVocabularyData(forWord word: String) -> AnyPublisher<VocabularyModel, Error>
    
    func fetchVocabularyModel(forWord word: String) -> AnyPublisher<Result<VocabularyModel, AIServiceError>, Error>
    
    /// 查詢單一單字 kk音標，句子，翻譯
    func fetchSingleWordDetail(word: String) -> AnyPublisher<WordDetail, Error>
}
