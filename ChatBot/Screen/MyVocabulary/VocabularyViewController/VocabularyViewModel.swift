//
//  VocabularyViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/13.
//

import Foundation
import Combine

class VocabularyViewModel: BaseViewModel<VocabularyViewModel.InputEvent, VocabularyViewModel.OutputEvent> {
    
    enum InputEvent {
        case initialVocabularies
        case fetchVocabularies(index: Int)
    }
    
    enum OutputEvent {
        case scrollTo(index: Int)
        case toast(message: String)
        case reloadCurrentIndex
    }
    
    let vocabularies: [VocabularyModel]
    let startIndex: Int
    let openAI: OpenAIService
    let vocabularyManager = VocabularyManager.share
    private(set) var displayEnable = false
    private(set) var isFetching = false
    
    init(vocabularies: [VocabularyModel], startIndex: Int, openAI: OpenAIService) {
        self.vocabularies = vocabularies
        self.startIndex = startIndex
        self.openAI = openAI
    }
    
    func bindInput() {
        inputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .fetchVocabularies(let index):
                    self.fetchVocabularies(index: index)
                case .initialVocabularies:
                    self.initialVocabularies()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func initialVocabularies() {
        fetchVocabularies(index: startIndex)
        displayEnable = true
        outputSubject.send(.scrollTo(index: startIndex))
    }
    
    private func fetchVocabularies(index: Int) {
        guard !isFetching else { return }
        let startIndex = index
        let numbers = generateAlternatingNumbers(start: startIndex, count: 10)
        var temp: [VocabularyModel] = []
        for number in numbers {
            if let vocabulary = self.vocabularies.getOrNil(index: number) {
                if vocabulary.wordSentences.isEmpty {
                    temp.append(vocabulary)
                }
            }
        }
        if temp.isNotEmpty {
            print("請求單字資料 from: \(startIndex) count: \(temp.count)")
            fetchWordDetails(words: temp)
        }
    }
    
    private func fetchWordDetails(words: [VocabularyModel]) {
        openAI.fetchWordDetails(words: words.map { $0.wordEntry.word })
            .flatMap({ [weak self] wordDetails -> AnyPublisher<[VocabularyModel], Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "self is nil", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                return self.handelWordDetailsResponse(wordDetails: wordDetails)
            })
            .flatMap({ [weak self] changeVocabularies -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "self is nil", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                return self.saveChangeVocabularies(vocabularies: changeVocabularies)
            })
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.isFetching = true
            }, receiveCompletion: { [weak self] _ in
                self?.isFetching = false
            })
            .sink { completion in
                if case .failure(let error) = completion {
                    print("查找單字句子失敗：\(error)")
                }
            } receiveValue: { [weak self] in
                self?.outputSubject.send(.reloadCurrentIndex)
            }
            .store(in: &subscriptions)
    }
    
    /// 處理ai回覆的資料
    /// 找到對應的voicabularies並把sentnece設定進去
    private func handelWordDetailsResponse(wordDetails: [OpenAIService.WordDetail]) -> AnyPublisher<[VocabularyModel], Error> {
        Future { [weak self] promise in
            guard let `self` = self else {
                promise(.success([]))
                return
            }
            let detailDict = Dictionary(uniqueKeysWithValues: wordDetails.map { ($0.word, $0) })
            print("得到單字資料 count: \(detailDict.count)")
            var changes: [VocabularyModel] = []
            for i in 0..<self.vocabularies.count {
                let vocabulary = self.vocabularies[i]
                if let match = detailDict[vocabulary.wordEntry.word] {
                    vocabulary.kkPronunciation = match.kkPronunciation
                    vocabulary.wordSentences.append(match.sentence)
                    changes.append(vocabulary)
                }
            }
            
            promise(.success(changes))
        }
        .eraseToAnyPublisher()
    }
    
    private func saveChangeVocabularies(vocabularies: [VocabularyModel]) -> AnyPublisher<Void, Error> {
        return vocabularyManager.saveVocabulayPackage(vocabularies: vocabularies)
    }
    
    /// 生成一串數字
    /// 例如: start 50 ,count 10 會給 [50, 49, 51, 48, 52, 47, 53, 46, 54, 45]
    /// - Parameters:
    ///   - start: 從哪裡開始
    ///   - count: 要生成幾個
    /// - Returns: 一串數字
    private func generateAlternatingNumbers(start: Int, count: Int) -> [Int] {
        var numbersArray: [Int] = []
        let currentNumber = start
        for i in 0..<count {
            if i % 2 == 0 {
                // 偶数索引，递增
                numbersArray.append(currentNumber + i / 2)
            } else {
                // 奇数索引，递减
                numbersArray.append(currentNumber - (i / 2 + 1))
            }
        }
        return numbersArray
    }
    
}
