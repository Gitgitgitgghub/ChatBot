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
        case currentIndexChange(index: Int)
        case toggleStar(index: Int)
        case fetchMoreSentence(index: Int)
    }
    
    enum OutputEvent {
        case toast(message: String)
        case changeTitle(title: String)
        case updateStar(isStar: Bool)
        case reloadUI(scrollTo: Int? = nil, isStar: Bool)
    }
    
    let vocabularies: [VocabularyModel]
    let startIndex: Int
    let openAI: VocabularyService
    let vocabularyManager = VocabularyManager.share
    private(set) var displayEnable = false
    private(set) var isFetching = false
    private(set) var currentIndex: Int = 0
    private var fetchWordDetailsSubject = PassthroughSubject<[VocabularyModel], Never>()
    private var cacheManager = CacheManager<String, AnyPublisher<Int, Error>>()
    //private var memoryCache: [Int: VocabularyModel] = [:]
    
    init(vocabularies: [VocabularyModel], startIndex: Int, openAI: VocabularyService) {
        self.vocabularies = vocabularies
        self.startIndex = startIndex
        self.openAI = openAI
        self.currentIndex = startIndex
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
                case .currentIndexChange(index: let index):
                    self.currentIndexChange(index: index)
                case .toggleStar(index: let index):
                    self.toggleStar(index: index)
                case .fetchMoreSentence(index: let index):
                    self.fetchMoreSentence(index: index)
                }
            }
            .store(in: &subscriptions)
    }
    
    /// 切換星星
    func toggleStar(index: Int) {
        let vocabulary = vocabularies[index]
        vocabulary.isStar.toggle()
        vocabularyManager.saveVocabulay(vocabulary: vocabulary)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    vocabulary.isStar.toggle()
                    self?.outputSubject.send(.toast(message: "操作失敗：\(error.localizedDescription)"))
                }
            } receiveValue: { [weak self] _ in
                self?.outputSubject.send(.updateStar(isStar: vocabulary.isStar))
            }
            .store(in: &subscriptions)
    }
    
    /// 讀取單字更多句子
    func fetchMoreSentence(index: Int) {
        let vocabulary = vocabularies[index]
        fetchWordDetails(words: [vocabulary])
    }
    
    /// 變更naviation title
    private func updateUI() {
        let prefix = "字卡堆"
        let suffix = vocabularies.first?.wordEntry.word.first?.uppercased() ?? ""
        let total = vocabularies.count
        let index = currentIndex + 1
        outputSubject.send(.changeTitle(title: prefix + suffix + ":" + "(\(index)/\(total))"))
        outputSubject.send(.updateStar(isStar: vocabularies[currentIndex].isStar))
    }
    
    private func currentIndexChange(index: Int) {
        currentIndex = index
        updateUI()
        let vocabulary = vocabularies[currentIndex]
        vocabulary.updateLastViewedTime()
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
        outputSubject.send(.reloadUI(scrollTo: startIndex, isStar: vocabularies[startIndex].isStar))
        updateUI()
    }
    
    private func fetchVocabularies(index: Int) {
        let startIndex = index
        let numbers = generateAlternatingNumbers(start: startIndex, count: 3)
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
        fetchWordDetailsSubject.send(words)
    }

    /// 設定背景讀取單字訊息的流程
    private func setupFetchWordDetailsPipeline() {
        fetchWordDetailsSubject
            .flatMap { [weak self] words -> AnyPublisher<Int, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "self is nil", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                return Publishers.Sequence(sequence: words)
                    .flatMap { word in
                        let wordKey = word.wordEntry.word
                        /// 如果有被cache的publisher就使用
                        if let cachedPublisher = self.cacheManager.getCache(forKey: wordKey) {
                            return cachedPublisher
                        } else {
                            let publisher = self.openAI.fetchSingleWordDetail(word: wordKey)
                                .flatMap({ [weak self] wordDetail -> AnyPublisher<Int, Error> in
                                    guard let self = self else {
                                        return Fail(error: NSError(domain: "self is nil", code: -1, userInfo: nil)).eraseToAnyPublisher()
                                    }
                                    // 處理response 最後會得到該單字的index
                                    return self.handelWordDetailsResponse(wordDetail: wordDetail)
                                })
                                .handleEvents(receiveCompletion: { [weak self] _ in
                                    guard let `self` = self else { return }
                                    // 完成後不管成功失敗都要移除
                                    self.cacheManager.removeCache(forKey: wordKey)
                                })
                                .share()
                                .eraseToAnyPublisher()
                            self.cacheManager.setCache(publisher, forKey: wordKey)
                            return publisher
                        }
                    }
                    .eraseToAnyPublisher()
            }
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
        outputSubject.send(.reloadUI(isStar: vocabularies[index].isStar))
    }
    
    /// 處理ai回覆的資料
    /// 找到對應的voicabularies並把sentnece設定進去
    /// 回傳該單字對應的index
    private func handelWordDetailsResponse(wordDetail: VocabularyService.WordDetail) -> AnyPublisher<Int, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "self is nil", code: -1, userInfo: nil)))
                return
            }
            /// 改變資料並且存進ＤＢ
            for (i, vocabulary) in vocabularies.enumerated() {
                guard vocabulary.wordEntry.word == wordDetail.word else { continue }
                vocabulary.kkPronunciation = wordDetail.kkPronunciation
                _ = vocabulary.addNewSentence(newSentence: wordDetail.sentence)
                self.vocabularyManager.saveVocabulay(vocabulary: vocabulary)
                    .sink { _ in
                        
                    } receiveValue: { _ in
                        promise(.success(i))
                    }
                    .store(in: &self.subscriptions)
            }
        }
        .eraseToAnyPublisher()
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

