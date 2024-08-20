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
        case currentIndexPathChange(index: Int)
    }
    
    enum OutputEvent {
        case scrollTo(index: Int)
        case toast(message: String)
        case reloadCurrentIndex
    }
    
    let vocabularies: [VocabularyModel]
    let startIndex: Int
    let openAI: VocabularyService
    let vocabularyManager = VocabularyManager.share
    private(set) var displayEnable = false
    private(set) var isFetching = false
    private(set) var currentIndex: Int = 0
    private var fetchWordDetailsSubject = PassthroughSubject<[VocabularyModel], Never>()
    private var cacheManager = CacheManager<VocabularyModel, AnyPublisher<VocabularyService.WordDetail, Error>>()
    private var memoryCache: [Int: VocabularyModel] = [:]
    
    init(vocabularies: [VocabularyModel], startIndex: Int, openAI: VocabularyService) {
        self.vocabularies = vocabularies
        self.startIndex = startIndex
        self.openAI = openAI
    }
    
    deinit {
        cacheManager.clearCache()
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
                case .currentIndexPathChange(index: let index):
                    self.currentIndexPathChange(index: index)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func currentIndexPathChange(index: Int) {
        currentIndex = index
        let vocabulary = vocabularies[currentIndex]
            .updateLastViewedTime()
        vocabularyManager.saveVocabulay(vocabulary: vocabulary)
            .sink { _ in
                
            } receiveValue: { _ in
                
            }
            .store(in: &subscriptions)
    }
    
    private func initialVocabularies() {
        setupFetchWordDetailsPipeline()
        fetchVocabularies(index: startIndex)
        displayEnable = true
        outputSubject.send(.scrollTo(index: startIndex))
    }
    
    private func fetchVocabularies(index: Int) {
        let startIndex = index
        let numbers = generateAlternatingNumbers(start: startIndex, count: 3)
        var temp: [VocabularyModel] = []
        for number in numbers {
            if let vocabulary = self.vocabularies.getOrNil(index: number) {
                if vocabulary.wordSentences.isEmpty {
                    temp.append(vocabulary)
                    memoryCache[number] = vocabulary
                }
            }
        }
        if temp.isNotEmpty {
            print("請求單字資料 from: \(startIndex) count: \(temp.count)")
            fetchWordDetails(words: temp)
        }
    }
    
    private func fetchWordDetails(words: [VocabularyModel]) {
        fetchWordDetailsSubject.send(words)
    }

    private func setupFetchWordDetailsPipeline() {
        fetchWordDetailsSubject
            .flatMap { [weak self] words -> AnyPublisher<VocabularyService.WordDetail, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "self is nil", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                return Publishers.Sequence(sequence: words)
                    .flatMap { word in
                        let wordKey = word.wordEntry.word
                        if let cachedPublisher = self.cacheManager.getCache(forKey: word) {
                            return cachedPublisher
                        } else {
                            let publisher = self.openAI.fetchSingleWordDetail(word: wordKey)
                                .handleEvents(receiveCompletion: { [weak self] _ in
                                    guard let `self` = self else { return }
                                    self.cacheManager.removeCache(forKey: word)
                                })
                                .share()
                                .eraseToAnyPublisher()
                            self.cacheManager.setCache(publisher, forKey: word)
                            return publisher
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .flatMap({ [weak self] wordDetail -> AnyPublisher<(key: Int, value: VocabularyModel), Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "self is nil", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                return self.handelWordDetailsResponse(wordDetail: wordDetail)
            })
            .flatMap({ [weak self] changeVocabulary -> AnyPublisher<Int, Error> in
                guard let `self` = self else {
                    return Fail(error: NSError(domain: "self is nil", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                return self.saveChangeVocabulary(changeData: changeVocabulary)
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
            } receiveValue: { [weak self] index in
                self?.reloadCurrentIndex(index: index)
            }
            .store(in: &subscriptions)
    }
    
    private func reloadCurrentIndex(index: Int) {
        guard index == currentIndex else { return }
        outputSubject.send(.reloadCurrentIndex)
    }

    
    private func needToSave(existingSentence: [WordSentence], newSentence: WordSentence) -> Bool {
        return existingSentence.isEmpty || existingSentence.last?.sentence ?? "" != newSentence.sentence
    }
    
    /// 處理ai回覆的資料
    /// 找到對應的voicabularies並把sentnece設定進去
    // 修改后的 handelWordDetailsResponse 处理单个单词的响应
    private func handelWordDetailsResponse(wordDetail: VocabularyService.WordDetail) -> AnyPublisher<(key: Int, value: VocabularyModel), Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "self is nil", code: -1, userInfo: nil)))
                return
            }
            for (i, vocabulary) in memoryCache {
                guard vocabulary.wordEntry.word == wordDetail.word else { continue }
                vocabulary.kkPronunciation = wordDetail.kkPronunciation
                if needToSave(existingSentence: vocabulary.wordSentences, newSentence: wordDetail.sentence) {
                    vocabulary.wordSentences.append(wordDetail.sentence)
                    promise(.success((i, vocabulary)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func saveChangeVocabulary(changeData: (key: Int, value: VocabularyModel)) -> AnyPublisher<Int, Error> {
        return vocabularyManager.saveVocabulay(vocabulary: changeData.value)
            .map({ changeData.key })
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

