//
//  AIEnglishQuestonServiceProtocol+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/16.
//

import Foundation
import Combine

extension AIEnglishQuestonServiceProtocol {
    
    func fetchVocabularyClozeQuestions(vocabularies: [VocabularyModel]) -> AnyPublisher<[EnglishExamQuestion], Error> {
        let clozeQuestionsPublishers = vocabularies.map { vocabulary in
            self.fetchSingleVocabularyClozeQuestion(vocabulary: vocabulary)
        }
        return Publishers.MergeMany(clozeQuestionsPublishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    func fetchGrammarQuestion(grammarPoint: TOEICGrammarPoint?, limit: Int) -> AnyPublisher<[EnglishExamQuestion], Error> {
        let publishers = (0..<limit).map { _ in
            fetchSingleGrammarQuestion(grammarPoint: grammarPoint)
        }
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }

    func fetchTOEICReadingQuestion() -> AnyPublisher<[EnglishExamQuestion], Error> {
        let prompt = """
        請生成一篇模仿 TOEIC 英語考試閱讀測驗的文章，並按照以下 JSON 格式返回結果。文章應該包含一篇短文及其中文翻譯，並附帶五個相關的問題，每個問題有四個選項，並標明正確答案。問題應該涵蓋不同的閱讀理解技能，例如細節理解、推理、句子重組等。
        返回的 JSON 結構應嚴格遵循以下格式：

        {
          "article": "[英文短文]",
          "articleTranslation": "[中文翻譯]",
          "questions": [
            {
              "questionText": "[問題文本]",
              "options": ["[選項1]", "[選項2]", "[選項3]", "[選項4]"],
              "correctAnswer": "[正確選項文本]",
              "reason": "[正確答案的解釋，應使用繁體中文]"
            }
          ]
        }
        請確保文章和問題是獨特的，並提供符合多益考試難度的題目及解釋，並且確保有五個問題。
        """
        return chat(prompt: prompt, responseFormat: .json)
            .tryMap { [weak self] chatResult in
                guard let `self` = self else { throw AIServiceError.selfDeallocated }
                let questions = try self.decodeChatResult(ReadingExamArticle.self, from: chatResult.message)
                    .toReadingExamQuestions()
                return questions
            }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    private func fetchSingleGrammarQuestion(grammarPoint: TOEICGrammarPoint?) -> AnyPublisher<EnglishExamQuestion, Error> {
        let grammarPoint = grammarPoint ?? TOEICGrammarPoint.randomGrammarPoint()
        let grammarPointSubType = grammarPoint.randomSubType()
        let grammar = "針對以下語法點: \(grammarPointSubType)"
        let prompt = """
            請生成一個符合 TOEIC 英語考試的語法題目，格式為 JSON \(grammar)。
            請確保語法題目是獨特且多樣化的，涵蓋不同的語法主題。句子結構、選項，並且應提供正確答案的解釋（理由），解釋部分應使用繁體中文。
            JSON 結構應嚴格遵循以下格式：
            {
              "questionText": "[問題，包含___的句子]",
              "questionTranslation": "[問題含正確選項的完整繁體中文翻譯]",
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
        let startTime = Date()
        let publisher = chat(prompt: prompt, responseFormat: .json)
            .tryMap({ chatResult in
                var question = try self.decodeChatResult(GrammarExamQuestion.self, from: chatResult.message)
                question.grammarPointDescription = grammarPointDescription
                question.ensureOptionsValid()
                return EnglishExamQuestion.grammarExamQuestion(data: question)
            })
            .catch({ _ in
                return Just(nil)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            })
            .compactMap({ $0 })
            .handleEvents(receiveSubscription: { _ in
                print("Fetching grammar question...")
            }, receiveCompletion: { comepletion in
                if case .failure(let error) = comepletion {
                    print("Grammar question fetch error \(error.localizedDescription).")
                }
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("Grammar question fetch finished. Duration: \(duration) seconds.")
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        return publisher
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
        let publisher = chat(prompt: prompt, responseFormat: .json)
            .tryMap({ chatResult in
                var question = try self.decodeChatResult(VocabularyExamQuestion.self, from: chatResult.message)
                question.original = vocabulary
                return EnglishExamQuestion.vocabulayExamQuestion(data: question)
            })
            .catch({ _ in
                return Just(nil)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            })
            .compactMap({ $0 })
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
