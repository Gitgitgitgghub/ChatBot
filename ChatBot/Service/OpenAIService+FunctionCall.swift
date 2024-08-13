//
//  OpenAIService+FunctionCall.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/13.
//

import Foundation
import OpenAI

extension OpenAIService {
    
    struct WordDetail: Codable {
        let word: String
        let kkPronunciation: String
        let sentence: WordSentence
    }
    
    func fetchWordDetails(words: [String]) async throws -> [WordDetail] {
        // 将单词列表转换为字符串
        let wordsList = words.joined(separator: ", ")
        let prompt = """
            For each word in this list: \(wordsList), return the KK phonetic transcription, a sentence using the word, and the Chinese translation of the sentence.
            Format the result as a JSON array, with each item having this structure:
            {
                "word": "[The word itself]",
                "kkPronunciation": "[KK phonetic transcription]",
                "sentence": {
                    "sentence": "[A sentence using the word]",
                    "translation": "[The Chinese translation of the sentence]"
                }
            }
            Return only the JSON data, with no additional text or explanations.
            """
        // 创建查询请求
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt3_5Turbo)
        // 发送请求
        let response = try await openAI.chats(query: query)
        // 解析响应的 JSON 数据
        if let text = response.choices.first?.message.content?.string {
            if let jsonData = text.data(using: .utf8) {
                let wordDetailsArray = try JSONDecoder().decode([WordDetail].self, from: jsonData)
                return wordDetailsArray
            } else {
                throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert response to data"])
            }
        } else {
            throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No valid response from OpenAI"])
        }
    }
    
}
