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
        return performAPICall(Publishers.MergeMany(clozeQuestionsPublishers)
            .collect()
            .eraseToAnyPublisher())
    }


    private func fetchSingleVocabularyClozeQuestion(vocabulary: VocabularyModel) -> AnyPublisher<EnglishExamQuestion, Error> {
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
                var question = try self.decodeChatResult(VocabularyExamQuestion.self, from: chatResult)
                question.original = vocabulary
                return EnglishExamQuestion.vocabulayExamQuestion(data: question)
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
    
    func fetchGrammarQuestion(grammarPoint: TOEICGrammarPoint?, limit: Int) -> AnyPublisher<[EnglishExamQuestion], Error> {
        let publishers = (0..<limit).map { _ in
            fetchSingleGrammarQuestion(grammarPoint: grammarPoint)
        }
        return performAPICall(Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher())
    }
    
    private func fetchSingleGrammarQuestion(grammarPoint: TOEICGrammarPoint?) -> AnyPublisher<EnglishExamQuestion, Error> {
        let grammarPoint = grammarPoint ?? TOEICGrammarPoint.randomGrammarPoint()
        let grammarPointSubType = grammarPoint.randomSubType()
        let grammar = "針對以下語法點: \(grammarPointSubType)"
        let prompt = """
            請生成一個符合 TOEIC 英語考試的語法題目，格式為 JSON \(grammar)。
            請確保語法題目是獨特且多樣化的，涵蓋不同的語法主題。句子結構、選項、正確答案和問題翻譯應該每次都不同，並且應提供正確答案的解釋（理由），解釋部分應使用繁體中文。
            JSON 結構應嚴格遵循以下格式：
            {
              "questionText": "[問題，包含___的句子]",
              "questionTranslation": "[問題的完整繁體中文翻譯]",
              "options": ["[選項 1]", "[選項 2]", "[選項 3]", "[選項 4]"],
              "correctAnswer": "[正確選項，必須是上述選項之一]",
              "reason": "[正確答案的解釋，使用繁體中文]"
            }
            """
        var grammarPointDescription: String = ""
        if grammarPoint.rawValue == grammarPointSubType {
            grammarPointDescription = "\(grammarPoint.rawValue)"
        }else {
            grammarPointDescription = "\(grammarPoint.rawValue)-\(grammarPointSubType)"
        }
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt3_5Turbo, responseFormat: .jsonObject)
        let publisher = openAI.chats(query: query)
            .tryMap({ chatResult in
                var question = try self.decodeChatResult(GrammarExamQuestion.self, from: chatResult)
                question.grammarPointDescription = grammarPointDescription
                question.ensureOptionsValid()
                return EnglishExamQuestion.grammarExamQuestion(data: question)
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


