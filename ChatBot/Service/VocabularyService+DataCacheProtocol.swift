//
//  VocabularyService+DataCacheProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/13.
//

import Foundation
import OpenAI
import Combine

class VocabularyService: OpenAIService, DataCacheProtocol {
    
    typealias ValueType = AnyPublisher<WordDetail, Error>
    
    struct WordDetail: Codable {
        let word: String
        let kkPronunciation: String
        let sentence: WordSentence
    }
    
    var cache: [String: AnyPublisher<WordDetail, Error>] = [:]
    var subscriptions: Set<AnyCancellable> = .init()
    
    /// 查詢多單字 kk音標，句子，翻譯
    /// 因為一次帶多個給ai慢到會timeout
    /// 所以改採並行機制
    func fetchWordDetails(words: [String]) -> AnyPublisher<[WordDetail], Error> {
        let publishers = words.compactMap { word in
            return fetchSingleWordDetail(word: word)
                .eraseToAnyPublisher()
        }
        let mergePublisher = Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
        return mergePublisher
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// 查詢單一單字 kk音標，句子，翻譯
    func fetchSingleWordDetail(word: String) -> AnyPublisher<WordDetail, Error> {
        // 如果缓存中存在，直接返回
        if let cachedPublisher = get(forKey: word) {
            return cachedPublisher
        }
        print("查單字： \(word)")
        // prompt很重要一定要明確要求他返回ＪＳＯＮ
        let prompt = """
        請將以下單詞的 KK 音標、例句以及例句的翻譯提供出來，翻譯請使用繁體中文：
        單詞: \(word)
        請按照以下格式返回JSON，並確保使用繁體中文：
        {
            "word": "\(word)",
            "kkPronunciation": "KK 音標",
            "sentence": {
                "sentence": "使用該單詞的例句",
                "translation": "例句的繁體中文翻譯"
            }
        }
        """
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt3_5Turbo, responseFormat: .jsonObject)
        let publisher = openAI.chats(query: query)
            .tryMap({ chatResult in
                // 解析JSON
                if let text = chatResult.choices.first?.message.content?.string {
                    if let jsonData = text.data(using: .utf8) {
                        let response = try JSONDecoder().decode(WordDetail.self, from: jsonData)
                        return response
                    } else {
                        throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert response to data"])
                    }
                } else {
                    throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No valid response from OpenAI"])
                }
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()
        set(publisher, forKey: word)
        return publisher
    }
    
    func set(_ value: AnyPublisher<WordDetail, any Error>, forKey key: String) {
        cache[key] = value
    }
    
}
