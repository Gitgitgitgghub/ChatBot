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
        let publishers = Publishers.Sequence(sequence: words)
            .flatMap({ self.fetchSingleWordDetail(word: $0) })
        return publishers
            .collect()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// 拼字檢查，若錯誤可獲取相關建議的單字
    func checkSpelling(forWord word: String) -> AnyPublisher<Result<String, OpenAIError>, Error> {
        let prompt = """
            Please verify if the word "\(word)" is a valid English word. If the word is correct and exists in the English language, return it as 'correctWord'.
            If the word is incorrect, misspelled, or does not exist in English, return 'correctWord' as null and provide a suggested correct spelling in the 'suggestion' field.
            The suggested word must be a valid, commonly recognized English word, not a variation or partial correction of the input. If no valid suggestion is available, return 'suggestion' as null.

            The response should be in this json format:
            {
              "correctWord": null,  // if the word does not exist or is incorrect
              "suggestion": "[Suggested correct word, or null if no valid suggestion]"
            }
            """
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt4_turbo, responseFormat: .jsonObject)
        let publisher = openAI.chats(query: query)
            .tryMap { [weak self] chatResult -> Result<String, OpenAIError> in
                guard let `self` = self else {
                    throw OpenAIError.selfDeallocated
                }
                struct SuggestionResponse: Codable {
                    let correctWord: String?
                    let suggestion: String?
                }
                let suggestion = try self.decodeChatResult(SuggestionResponse.self, from: chatResult)
                if let correctWord = suggestion.correctWord, correctWord != "correctWord" {
                    return .success(correctWord)
                } else {
                    return .failure(.wordNotFound(suggestion: suggestion.suggestion))
                }
            }
            .eraseToAnyPublisher()
        return performAPICall(publisher)
    }

    
    func fetchVocabularyData(forWord word: String) -> AnyPublisher<VocabularyModel, Error> {
        let prompt = """
            Please verify if the word "\(word)" exists. If the word exists, return the word's data in the JSON format below. If the word does not exist at all, return exactly "查無此單字".
            The JSON object should strictly follow this format:
            {
                "wordEntry": {
                    "word": "\(word)",
                    "definitions": [
                        {
                            "part_of_speech": "[Part of speech in Chinese, e.g., 名詞, 動詞]",
                            "definition": "[The word's translation in Chinese]"
                        }
                    ]
                },
                "wordSentences": [
                    {
                        "sentence": "[Example sentence using the word]",
                        "translation": "[Translation of the example sentence in Traditional Chinese]"
                    }
                ],
                "kkPronunciation": "[KK pronunciation of the word]"
            }
            """
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt3_5Turbo, responseFormat: .jsonObject)
        let publisher = openAI.chats(query: query)
            .tryMap { [weak self] chatResult in
                guard let `self` = self else {
                    throw OpenAIError.selfDeallocated
                }
                struct ResponseVocabularyModel: Codable {
                    var wordEntry: WordEntry
                    var wordSentences: [WordSentence]
                    var kkPronunciation: String
                }
                if let text = chatResult.choices.first?.message.content?.string, text.contains("查無此單字") {
                    throw OpenAIError.wordNotFound()
                } else {
                    let tempVocabularyModel = try self.decodeChatResult(ResponseVocabularyModel.self, from: chatResult)
                    return VocabularyModel(wordEntry: tempVocabularyModel.wordEntry, wordSentences: tempVocabularyModel.wordSentences, kkPronunciation: tempVocabularyModel.kkPronunciation)
                }
            }
            .eraseToAnyPublisher()
        return performAPICall(publisher)
    }
    
    func fetchVocabularyModel(forWord word: String) -> AnyPublisher<Result<VocabularyModel, OpenAIError>, Error> {
        let publisher = checkSpelling(forWord: word)
            .flatMap { [weak self] result -> AnyPublisher<Result<VocabularyModel, OpenAIError>, Error> in
                guard let `self` = self else {
                    return Just(.failure(OpenAIError.selfDeallocated))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                switch result {
                case .success(let correctWord):
                    return self.fetchVocabularyData(forWord: correctWord)
                        .map { .success($0) }
                        .eraseToAnyPublisher()
                case .failure(let suggestion):
                    return Just(.failure(suggestion))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
        return performAPICall(publisher)
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
                let response = try self.decodeChatResult(WordDetail.self, from: chatResult)
                return response
            })
            .catch({ _ in
                return Just(nil)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            })
            .compactMap({ $0 })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        return performAPICall(publisher)
    }
    
}
