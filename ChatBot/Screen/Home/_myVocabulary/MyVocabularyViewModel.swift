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
        case speakWord(indexPath: IndexPath)
        case toggleStar(indexPath: IndexPath)
        case reloadExpandingSection
    }
    
    enum OutputEvent {
        case reloadRows(indexPath: [IndexPath])
        case reloadAll
        case reloadSections(sections: [Int])
        case toast(message: String)
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
    
    private let vocabularyManager = VocabularyManager.share
    private(set) var sectionDatas: [SectionData] = []
    
    func bindInputEvent() {
        inputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .initialVocabulary:
                    self.initialVocabulary()
                case .toggleExpanding(section: let section):
                    self.toggleExpanding(section: section)
                case .speakWord(indexPath: let indexPath):
                    self.speakWord(indexPath: indexPath)
                case .toggleStar(indexPath: let indexPath):
                    self.toggleStar(indexPath: indexPath)
                case .reloadExpandingSection:
                    self.reloadExpandingSection()
                }
            }
            .store(in: &subscriptions)
    }
    
    func speakWord(indexPath: IndexPath) {
        guard let word = sectionDatas.getOrNil(index: indexPath.section)?.vocabularies.getOrNil(index: indexPath.row)?.wordEntry.word else { return }
        SpeechVoiceManager.shared.speak(text: word)
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
        guard let expandingIndex = sectionDatas.firstIndex(where: { $0.isExpanding }) else { return }
        fetchExpandingSectionVocabulary(expandingIndex: expandingIndex) { [weak self] in
            self?.outputSubject.send(.reloadSections(sections: [expandingIndex]))
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
