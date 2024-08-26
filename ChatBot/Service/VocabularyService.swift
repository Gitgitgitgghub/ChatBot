//
//  VocabularyService.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/13.
//

import Foundation
import OpenAI
import Combine

class VocabularyService: OpenAIService {
    
    
    struct WordDetail: Codable, Equatable {
        static func == (lhs: VocabularyService.WordDetail, rhs: VocabularyService.WordDetail) -> Bool {
            return lhs.kkPronunciation == rhs.kkPronunciation &&
            lhs.sentence == rhs.sentence
        }
        
        let word: String
        let kkPronunciation: String
        let sentence: WordSentence
    }
    
    
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
            .handleEvents(receiveSubscription: { _ in
                print("查單字： \(word)")
            }, receiveCancel: {
                print("取消查單字： \(word)")
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        return publisher
    }
    
    func fetchVocabularyClozeQuestions(vocabularies: [VocabularyModel]) -> AnyPublisher<[VocabulayExamQuestion], Error> {
        let clozeQuestionsPublishers = vocabularies.map { vocabulary in
            self.fetchSingleVocabularyClozeQuestion(vocabulary: vocabulary)
        }
        return Publishers.MergeMany(clozeQuestionsPublishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    
    func fetchSingleVocabularyClozeQuestion(vocabulary: VocabularyModel) -> AnyPublisher<VocabulayExamQuestion, Error> {
        let prompt = """
        請幫我生成一個 JSON 格式的克漏字題目，請使用以下單字來生成題目：
        單字：**\(vocabulary.wordEntry.word)**
        生成的 JSON 結構應符合以下格式：
        {
          "questionText": "[包含___的句子]",
          "options": ["[錯誤選項1]", "[錯誤選項2]", "[正確答案]"],
          "correctAnswer": "[正確答案]"
        }
        """
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt3_5Turbo, responseFormat: .jsonObject)
        let publisher = openAI.chats(query: query)
            .tryMap({ chatResult in
                // 解析JSON
                if let text = chatResult.choices.first?.message.content?.string {
                    if let jsonData = text.data(using: .utf8) {
                        var response = try JSONDecoder().decode(VocabulayExamQuestion.self, from: jsonData)
                        response.original = vocabulary
                        return response
                    } else {
                        throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert response to data"])
                    }
                } else {
                    throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No valid response from OpenAI"])
                }
            })
            .handleEvents(receiveSubscription: { _ in
                print("查克漏字題目： \(vocabulary.wordEntry.word)")
            }, receiveCancel: {
                print("取消查單字： \(vocabulary.wordEntry.word)")
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        return publisher
    }
    
}
