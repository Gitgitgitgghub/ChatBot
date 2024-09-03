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
        case searchVocabulary(text: String)
        case fetchVocabularyModel
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
    private let vocabularyService = VocabularyService()
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
                case .searchVocabulary(text: let text):
                    self.searchVocabulary(text: text)
                case .fetchVocabularyModel:
                    self.fetchVocabularyModel()
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
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.global(), latest: true)
            .sink { [weak self] text in
                self?.startSearch(text: text)
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
    
    /// 開始執行搜索，優先搜索本地資料庫
    private func startSearch(text: String) {
        guard displayMode == .searchMode else { return }
        vocabularyManager.fetchVocabulary(letter: text)
            .sink { _ in
                
            } receiveValue: { [weak self] vocabularies in
                guard let `self` = self else { return }
                // 如果查到單字不是空的就直接刷新否則就請求api
                self.searchDatas = vocabularies
                self.outputSubject.send(.reloadAll)
                self.outputSubject.send(.setEmptyButtonVisible(isVisible: vocabularies.isEmpty))
            }
            .store(in: &subscriptions)
    }
    
    /// 透過openAI 查詢單字資料
    private func fetchVocabularyModel() {
        guard searchSubject.value.isNotEmpty else { return }
        vocabularyService.fetchVocabularyModel(forWord: searchSubject.value)
            .sink { [weak self] completion in
                if case .failure(let failure) = completion {
                    print("fetchVocabularyModel failure: \(failure.localizedDescription)")
                    self?.outputSubject.send(.toast(message: failure.localizedDescription))
                }
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let vocabularyModel):
                    self.searchDatas = [vocabularyModel]
                    self.outputSubject.send(.reloadAll)
                case .failure(let error):
                    if case .wordNotFound(let suggestion) = error {
                        // 這邊多這麼多判斷是因為，suggestion有時候是空字串，有時候會給你一串提示並非單字
                        if let suggestion = suggestion,
                           suggestion.isNotEmpty,
                           !suggestion.contains(" ") {
                            self.outputSubject.send(.wordNotFound(sggestion: suggestion))
                        }else {
                            self.outputSubject.send(.toast(message: error.localizedDescription))
                        }
                    }else {
                        self.outputSubject.send(.toast(message: error.localizedDescription))
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
}
