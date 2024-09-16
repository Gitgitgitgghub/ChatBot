//
//  MyVocabularyViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation
import Combine


class MyVocabularyViewModel: BaseViewModel<MyVocabularyViewModel.InputEvent, MyVocabularyViewModel.OutputEvent> {
    
    enum InputEvent {
        case initialVocabulary
        case toggleExpanding(section: Int)
        case toggleStar(indexPath: IndexPath)
        case reloadExpandingSection
        case searchVocabularyDatabase(text: String)
        case fetchVocabularyModel(word: String? = nil)
    }
    
    enum OutputEvent {
        case reloadRows(indexPath: [IndexPath])
        case reloadAll
        case reloadSections(sections: [Int])
        case toast(message: String)
        case setEmptyButtonVisible(isVisible: Bool)
        case wordNotFound(sggestion: String?)
    }
    
    struct SectionData {
        var letter: String
        var vocabularies: [VocabularyModel]
        var count: Int
        var isExpanding = false
        
        mutating func updateVocabularies(vocabularies: [VocabularyModel]) {
            self.vocabularies = vocabularies
            self.count = vocabularies.count
        }
    }
    
    /// 顯示模式
    enum DisplayMode {
        case normalMode
        case searchMode
    }
    private let vocabularyServiceManager = AIVocabularyServiceManager(service: AIServiceManager.shared.service as! AIVocabularyServiceProtocol)
    private let vocabularyManager = VocabularyManager.share
    /// 資料源
    private(set) var sectionDatas: [SectionData] = []
    /// 搜尋結果資料源
    private(set) var searchDatas: [VocabularyModel] = []
    private let searchSubject = CurrentValueSubject<String, Never>("")
    private(set) var displayMode: DisplayMode = .normalMode
    
    
    func bindInputEvent() {
        inputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .initialVocabulary:
                    self.initialVocabulary()
                case .toggleExpanding(section: let section):
                    self.toggleExpanding(section: section)
                case .toggleStar(indexPath: let indexPath):
                    self.toggleStar(indexPath: indexPath)
                case .reloadExpandingSection:
                    self.reloadExpandingSection()
                case .searchVocabularyDatabase(text: let text):
                    self.searchVocabulary(text: text)
                case .fetchVocabularyModel(let word):
                    self.fetchVocabularyModel(word: word)
                }
            }
            .store(in: &subscriptions)
        setupSearchPipeline()
    }
    
    func toggleStar(indexPath: IndexPath) {
        let vocabulary = sectionDatas[indexPath.section].vocabularies[indexPath.row]
        vocabulary.isStar.toggle()
        vocabularyManager.saveVocabulay(vocabulary: vocabulary)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    vocabulary.isStar.toggle()
                    self?.outputSubject.send(.toast(message: "操作失敗：\(error.localizedDescription)"))
                }
            } receiveValue: { [weak self] _ in
                self?.outputSubject.send(.reloadRows(indexPath: [indexPath]))
            }
            .store(in: &subscriptions)
    }
    
    private func reloadExpandingSection() {
        switch displayMode {
        case .normalMode:
            guard let expandingIndex = sectionDatas.firstIndex(where: { $0.isExpanding }) else { return }
            fetchExpandingSectionVocabulary(expandingIndex: expandingIndex) { [weak self] in
                self?.outputSubject.send(.reloadSections(sections: [expandingIndex]))
            }
        case .searchMode:
            searchVocabulary(text: searchSubject.value)
        }
    }
    
    private func toggleExpanding(section: Int) {
        //即將展開
        var willExpandingSection = -1
        //即將收起
        var willCloseSection = -1
        //一次只能展開一組
        for (i, var sectionData) in sectionDatas.enumerated() {
            if sectionData.isExpanding {
                willCloseSection = i
            }
            if i == section {
                sectionData.isExpanding.toggle()
            }else {
                sectionData.isExpanding = false
            }
            if sectionData.isExpanding {
                willExpandingSection = i
            }
            sectionDatas[i] = sectionData
        }
        var reloadSections: [Int] = []
        if willCloseSection >= 0 {
            reloadSections.append(willCloseSection)
        }
        if willExpandingSection >= 0 {
            reloadSections.append(willExpandingSection)
            fetchExpandingSectionVocabulary(expandingIndex: willExpandingSection) { [weak self] in
                self?.outputSubject.send(.reloadSections(sections: reloadSections))
            }
        }else {
            outputSubject.send(.reloadSections(sections: reloadSections))
        }
    }
    
    /// 取得展開中的section的單字資料並更新
    private func fetchExpandingSectionVocabulary(expandingIndex: Int, completion: @escaping () -> ()) {
        var expandingSection = sectionDatas[expandingIndex]
        vocabularyManager.fetchVocabulary(letter: expandingSection.letter)
            .sink { _ in
                
            } receiveValue: { results in
                expandingSection.updateVocabularies(vocabularies: results)
                self.sectionDatas[expandingIndex] = expandingSection
                completion()
            }
            .store(in: &subscriptions)
    }
    
    private func initialVocabulary() {
        createSectionDatas()
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch counts: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] sectionDataArray in
                guard let `self` = self else { return }
                self.sectionDatas = sectionDataArray
                self.outputSubject.send(.reloadAll)
            }
            .store(in: &subscriptions)
    }
    
    /// 創建一組Ａ－Ｚ的section Data array
    private func createSectionDatas() -> AnyPublisher<[SectionData], Error> {
        let sectionDatas = (65...90).map { asciiValue in
            let letter = String(UnicodeScalar(asciiValue)!)
            return SectionData(letter: letter, vocabularies: [], count: 0, isExpanding: false)
        }
        let countPublishers = sectionDatas.map { section in
            vocabularyManager.countVocabulary(letter: section.letter)
                .map { count in
                    SectionData(letter: section.letter, vocabularies: [], count: count)
                }
        }
        return Publishers.MergeMany(countPublishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
}

//MARK: - 搜尋相關的功能
extension MyVocabularyViewModel {
    
    /// 設定searchBar 輸入文字的頻率與流程
    private func setupSearchPipeline() {
        searchSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.global())
            .sink { [weak self] text in
                self?.startSearchDatabase(text: text)
            }
            .store(in: &subscriptions)
    }
    
    /// 輸入文字
    private func searchVocabulary(text: String) {
        if text.isEmpty {
            displayMode = .normalMode
            outputSubject.send(.reloadAll)
            self.outputSubject.send(.setEmptyButtonVisible(isVisible: false))
        }else {
            displayMode = .searchMode
            searchSubject.send(text)
        }
    }
    
    /// 開始執行搜索本地資料庫
    private func startSearchDatabase(text: String, completion: ((_ isEmpty: Bool) -> ())? = nil) {
        guard displayMode == .searchMode else { return }
        vocabularyManager.fetchVocabulary(letter: text)
            .sink { _ in
                
            } receiveValue: { [weak self] vocabularies in
                guard let `self` = self else { return }
                self.searchDatas = vocabularies
                self.outputSubject.send(.reloadAll)
                self.outputSubject.send(.setEmptyButtonVisible(isVisible: vocabularies.isEmpty))
                completion?(vocabularies.isEmpty)
            }
            .store(in: &subscriptions)
    }
    
    /// 拿取單字資料，當word = nil 會使用searchSubject.value 去執行checkSpellingAndFetchVocabularyModel
    private func fetchVocabularyModel(word: String?) {
        if let word = word {
            // 一樣先搜索本地資料庫，找不到才透過ＡＰＩ
            startSearchDatabase(text: word) { [weak self] isEmpty in
                guard let `self` = self else { return }
                if isEmpty {
                    performAction(vocabularyServiceManager.fetchVocabularyData(forWord: word))
                        .sink { [weak self] completion in
                            if case .failure(let failure) = completion {
                                print("fetchVocabularyData failure: \(failure.localizedDescription)")
                                self?.outputSubject.send(.toast(message: failure.localizedDescription))
                            }
                        } receiveValue: { vocabularyModel in
                            self.fetchVocabularyComplete(vocabularyModel: vocabularyModel)
                        }
                        .store(in: &subscriptions)
                }
            }
        }else {
            checkSpellingAndFetchVocabularyModel()
        }
    }
    
    /// 先檢查有無此單字再做查詢
    private func checkSpellingAndFetchVocabularyModel() {
        guard searchSubject.value.isNotEmpty else { return }
        performAction(vocabularyServiceManager.fetchVocabularyModel(forWord: searchSubject.value))
            .sink { [weak self] completion in
                if case .failure(let failure) = completion {
                    print("checkSpellingAndFetchVocabularyModel failure: \(failure.localizedDescription)")
                    self?.outputSubject.send(.toast(message: failure.localizedDescription))
                }
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let vocabularyModel):
                    self.fetchVocabularyComplete(vocabularyModel: vocabularyModel)
                case .failure(let error):
                    if case .wordNotFound(let suggestion) = error {
                        self.outputSubject.send(.wordNotFound(sggestion: suggestion))
                    }else {
                        self.outputSubject.send(.toast(message: error.localizedDescription))
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    /// 成功要到單字時要做的事情
    private func fetchVocabularyComplete(vocabularyModel: VocabularyModel) {
        vocabularyManager.saveVocabulay(vocabulary: vocabularyModel)
            .sink { _ in
                
            } receiveValue: { _ in
                
            }
            .store(in: &subscriptions)
        self.searchDatas = [vocabularyModel]
        self.outputSubject.send(.reloadAll)
        self.outputSubject.send(.setEmptyButtonVisible(isVisible: false))
    }
    
}
