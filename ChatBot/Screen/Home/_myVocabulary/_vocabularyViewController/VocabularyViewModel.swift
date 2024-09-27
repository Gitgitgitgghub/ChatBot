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
    let vocabularyServiceManager = AIVocabularyServiceManager(service: AIServiceManager.shared.service as! AIVocabularyServiceProtocol)
    let vocabularyManager = VocabularyManager.share
    private(set) var displayEnable = false
    private(set) var isFetching = false
    private(set) var currentIndex: Int = 0
    private var fetchWordDetailsSubject = PassthroughSubject<[VocabularyModel], Never>()
    private var cacheManager = CacheManager<String, AnyPublisher<Int, Error>>()
    
    init(vocabularies: [VocabularyModel], startIndex: Int) {
        self.vocabularies = vocabularies
        self.startIndex = startIndex
        self.currentIndex = startIndex
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    deinit {
        cacheManager.clearCache()
    }
    
    override func handleInputEvent(inputEvent: InputEvent) {
        switch inputEvent {
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
    
    /// 切換星星
    func toggleStar(index: Int) {
        let vocabulary = vocabularies[index]
        vocabulary.isStar.toggle()
        vocabularyManager.saveVocabulay(vocabulary: vocabulary)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    vocabulary.isStar.toggle()
                    self?.sendOutputEvent(.toast(message: "操作失敗：\(error.localizedDescription)"))
                }
            } receiveValue: { [weak self] _ in
                self?.sendOutputEvent(.updateStar(isStar: vocabulary.isStar))
            }
            .store(in: &subscriptions)
    }
    
    /// 讀取單字更多句子
    func fetchMoreSentence(index: Int) {
        let vocabulary = vocabularies[index]
        performAction(getPublisherFromCache(wordKey: vocabulary.wordEntry.word), message: "正讀取更多單字")
            .sink { _ in
                
            } receiveValue: { [weak self] index in
                self?.reloadCurrentIndex(index: index)
            }
            .store(in: &subscriptions)
    }
    
    /// 變更naviation title
    private func updateUI() {
        let prefix = "字卡堆"
        let suffix = vocabularies.first?.wordEntry.word.first?.uppercased() ?? ""
        let total = vocabularies.count
        let index = currentIndex + 1
        sendOutputEvent(.changeTitle(title: prefix + suffix + ":" + "(\(index)/\(total))"))
        sendOutputEvent(.updateStar(isStar: vocabularies[currentIndex].isStar))
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
        sendOutputEvent(.reloadUI(scrollTo: startIndex, isStar: vocabularies[startIndex].isStar))
        updateUI()
    }
    
    private func fetchVocabularies(index: Int) {
        let startIndex = index
        let numbers = Array.generateAlternatingNumbers(start: startIndex, count: 3)
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
            .flatMap { [unowned self] words -> AnyPublisher<Int, Error> in
                return Publishers.Sequence(sequence: words)
                    .flatMap { [unowned self] word in
                        self.getPublisherFromCache(wordKey: word.wordEntry.word)
                    }
                    .eraseToAnyPublisher()
            }
            .sink { completion in
                if case .failure(let error) = completion {
                    print("查找單字句子失敗：\(error)")
                }
            } receiveValue: { [weak self] index in
                self?.reloadCurrentIndex(index: index)
            }
            .store(in: &subscriptions)
    }
    
    private func getPublisherFromCache(wordKey: String) -> AnyPublisher<Int, Error> {
        /// 如果有被cache的publisher就使用
        if let cachedPublisher = self.cacheManager.getCache(forKey: wordKey) {
            return cachedPublisher
        } else {
            let publisher = self.vocabularyServiceManager.fetchSingleWordDetail(word: wordKey)
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
    
    private func reloadCurrentIndex(index: Int) {
        guard index == currentIndex else { return }
        sendOutputEvent(.reloadUI(isStar: vocabularies[index].isStar))
    }
    
    /// 處理ai回覆的資料
    /// 找到對應的voicabularies並把sentnece設定進去
    /// 回傳該單字對應的index
    private func handelWordDetailsResponse(wordDetail: WordDetail) -> AnyPublisher<Int, Error> {
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
    
}

