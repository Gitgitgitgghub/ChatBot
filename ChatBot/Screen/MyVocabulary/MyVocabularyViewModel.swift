//
//  MyVocabularyViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation


class MyVocabularyViewModel: BaseViewModel<MyVocabularyViewModel.InputEvent, MyVocabularyViewModel.OutputEvent> {
    
    enum InputEvent {
        case initialVocabulary
        case fetchVocabularys
        case toggleExpanding(section: Int)
        case speakWord(indexPath: IndexPath)
        case toggleStar(indexPath: IndexPath)
    }
    
    enum OutputEvent {
        case reloadRows(indexPath: [IndexPath])
        case reloadAll
        case reloadSection(section: Int)
        case toast(message: String)
    }
    
    struct SectionData {
        var title: String
        var vocabularies: [VocabularyModel]
        var isExpanding = false
    }
    
    private let vocabularyManager = VocabularyManager.share
    var sectionDatas: [SectionData] = []
    
    func bindInputEvent() {
        inputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .initialVocabulary:
                    self.initialVocabulary()
                case .fetchVocabularys:
                    self.fetchVocabularys()
                case .toggleExpanding(section: let section):
                    self.toggleExpanding(section: section)
                case .speakWord(indexPath: let indexPath):
                    self.speakWord(indexPath: indexPath)
                case .toggleStar(indexPath: let indexPath):
                    self.toggleStar(indexPath: indexPath)
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
    
    private func toggleExpanding(section: Int) {
        var sectionData = sectionDatas[section]
        sectionData.isExpanding.toggle()
        sectionDatas[section] = sectionData
        outputSubject.send(.reloadSection(section: section))
    }
    
    /// 取得所有單字
    func fetchVocabularys() {
        vocabularyManager.fetchAllVocabulary()
            .map({ [weak self] models in
                // 如果db是空的代表要初始化
                if models.isEmpty {
                    self?.initialVocabulary()
                }
                return models
            })
            .sink { completion in
                if case .failure(let error) = completion {
                    print("initialVocabulary error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] vocabularies in
                self?.groupWordsAtoZ(vocabularies: vocabularies)
                self?.outputSubject.send(.reloadAll)
            }
            .store(in: &subscriptions)
    }
    
    /// 依照Ａ－Ｚ分組
    private func groupWordsAtoZ(vocabularies: [VocabularyModel]) {
        guard vocabularies.isNotEmpty else { return }
        var categorizedWords: [Character: [VocabularyModel]] = [:]
        for vocabulary in vocabularies {
            guard let firstChar = vocabulary.wordEntry.word.uppercased().first else { continue }
            if categorizedWords[firstChar] == nil {
                categorizedWords[firstChar] = [vocabulary]
            } else {
                categorizedWords[firstChar]?.append(vocabulary)
            }
        }
        var temp: [SectionData] = []
        for key in categorizedWords.keys.sorted() {
            let vocabularies = categorizedWords[key] ?? []
            temp.append(.init(title: String(key), vocabularies: vocabularies))
        }
        self.sectionDatas = temp
    }
    
    /// 讀取json裡面的單字並且存到db
    private func initialVocabulary() {
        let decoder = TOEICWordDecoder()
        decoder.decode()
            .flatMap({ words in
                let vocabularies = words.map({ VocabularyModel(word: $0) })
                return self.vocabularyManager.saveVocabulayPackage(vocabularies: vocabularies)
            })
            .sink { completion in
                if case .failure(let error) = completion {
                    print("initialVocabulary error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] _ in
                self?.fetchVocabularys()
            }
            .store(in: &subscriptions)
    }
    
}
