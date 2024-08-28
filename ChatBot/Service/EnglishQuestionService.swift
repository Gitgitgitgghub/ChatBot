//
//  EnglishQuestionService.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/27.
//

import Foundation
import Combine
import OpenAI


class EnglishQuestionService: OpenAIService {
    
    func fetchVocabularyClozeQuestions(vocabularies: [VocabularyModel]) -> AnyPublisher<[EnglishExamQuestion], Error> {
        let clozeQuestionsPublishers = vocabularies.map { vocabulary in
            self.fetchSingleVocabularyClozeQuestion(vocabulary: vocabulary)
        }
        return Publishers.MergeMany(clozeQuestionsPublishers)
            .collect()
            .eraseToAnyPublisher()
    }


    func fetchSingleVocabularyClozeQuestion(vocabulary: VocabularyModel) -> AnyPublisher<EnglishExamQuestion, Error> {
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
                        var response = try JSONDecoder().decode(VocabularyExamQuestion.self, from: jsonData)
                        response.original = vocabulary
                        return EnglishExamQuestion.vocabulayExamQuestion(data: response)
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
    
    func fetchGrammarQuestion(limit: Int) -> AnyPublisher<[EnglishExamQuestion], Error> {
        let publishers = (0..<limit).map { _ in
            fetchSingleGrammarQuestion()
        }
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    func fetchSingleGrammarQuestion() -> AnyPublisher<EnglishExamQuestion, Error> {
        let prompt = """
        Please generate a diverse TOEIC grammar question in JSON format and ensure the grammar question is unique and varied, covering different grammar topics. The sentence structure, options, and correct answer should change every time, and the explanation (reason) should be provided in Traditional Chinese.
        Make sure the JSON structure follows this format:
        {
          "questionText": "[Sentence with a blank space]",
          "options": ["[Option 1]", "[Option 2]", "[Option 3]"],
          "correctAnswer": "[Correct option]",
          "reason": "[Explanation for the correct answer in Traditional Chinese]"
        }
        """
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt3_5Turbo, responseFormat: .jsonObject)
        let publisher = openAI.chats(query: query)
            .tryMap({ chatResult in
                // 解析JSON
                if let text = chatResult.choices.first?.message.content?.string {
                    if let jsonData = text.data(using: .utf8) {
                        let response = try JSONDecoder().decode(GrammaExamQuestion.self, from: jsonData)
                        return EnglishExamQuestion.grammaExamQuestion(data: response)
                    } else {
                        throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert response to data"])
                    }
                } else {
                    throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No valid response from OpenAI"])
                }
            })
            .handleEvents(receiveSubscription: { _ in
                print("Fetching grammar question...")
            }, receiveCancel: {
                print("Grammar question fetch canceled.")
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        return publisher
    }

    
}


