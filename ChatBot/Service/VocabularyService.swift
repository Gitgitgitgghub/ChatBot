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
    
    /// 用來保存API給的臨時單字資料
    struct APIResponseVocabularyModel: Codable {
        var wordEntry: WordEntry?
        var wordSentences: [WordSentence] = []
        var kkPronunciation: String = ""
        var suggestion: String?
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            suggestion = try container.decodeIfPresent(String.self, forKey: .suggestion)
            if suggestion != nil && suggestion!.isNotEmpty {
                return
            }
            wordEntry = try container.decodeIfPresent(WordEntry.self, forKey: .wordEntry)
            wordSentences = try container.decodeIfPresent([WordSentence].self, forKey: .wordSentences) ?? []
            kkPronunciation = try container.decodeIfPresent(String.self, forKey: .kkPronunciation) ?? ""
        }
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
    
    func fetchVocabularyModel(forWord word: String) -> AnyPublisher<Result<VocabularyModel, OpenAIError>, Error> {
        let prompt = """
            Please verify if the word "\(word)" is a correct English word. If the word is correct, return the word as is. If the word is incorrect, suggest the correct spelling of the word. If the word exists, return the word's data as well in the following JSON format:
            {
                "wordEntry": {
                    "word": "\(word)",
                    "definitions": [
                        {
                            "part_of_speech": "[Part of speech, e.g., noun, verb, etc.]",
                            "definition": "[Definition of the word]"
                        }
                    ]
                },
                "wordSentences": [
                    {
                        "sentence": "[Example sentence using the word]",
                        "translation": "[Translation of the example sentence in Traditional Chinese]"
                    }
                ],
                "kkPronunciation": "[KK pronunciation of the word]",
                "suggestion": "[Suggested correct spelling if the word is misspelled or not found]"
            }
            
            If the word does not exist, return exactly "查無此單字". If the word is misspelled, return a suggestion for the correct spelling.
            """
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt3_5Turbo, responseFormat: .jsonObject)
        let publisher = openAI.chats(query: query)
            .tryMap({ chatResult -> Result<VocabularyModel, OpenAIError> in
                if let text = chatResult.choices.first?.message.content?.string, text.contains("查無此單字") {
                    return .failure(.wordNotFound())
                } else {
                    let response = try self.decodeChatResult(APIResponseVocabularyModel.self, from: chatResult)
                    if let wordEntry = response.wordEntry {
                        let vocabulary = VocabularyModel(wordEntry: wordEntry, wordSentences: response.wordSentences, kkPronunciation: response.kkPronunciation)
                        return .success(vocabulary)
                    }else {
                        return .failure(.wordNotFound(suggestion: response.suggestion))
                    }
                }
            })
            .handleEvents(receiveSubscription: { _ in
                print("Fetching vocabulary model for word: \(word)")
            }, receiveCancel: {
                print("Vocabulary model fetch canceled.")
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
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
    
}
