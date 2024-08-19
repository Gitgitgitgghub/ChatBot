//
//  VocabularyModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation
import GRDB

class VocabularyModel: Codable, FetchableRecord, PersistableRecord, Hashable {
    
    var id: Int64?
    var wordEntry: WordEntry
    var familiarity: Int = 0
    var isStar = false
    var lastViewedTime: Date
    var wordSentences: [WordSentence] = []
    var kkPronunciation: String = ""
    
    init(id: Int64? = nil, wordEntry: WordEntry, familiarity: Int, isStar: Bool, lastViewedTime: Date, examples: [WordSentence], kkPronunciation: String) {
        self.id = id
        self.wordEntry = wordEntry
        self.familiarity = familiarity
        self.isStar = isStar
        self.lastViewedTime = lastViewedTime
        self.wordSentences = examples
        self.kkPronunciation = kkPronunciation
    }
    
    static func == (lhs: VocabularyModel, rhs: VocabularyModel) -> Bool {
        return lhs.wordEntry.word == rhs.wordEntry.word
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wordEntry.word)
    }
    
    func updateLastViewedTime() -> VocabularyModel {
        lastViewedTime = .now
        return self
    }
    
    func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension VocabularyModel {
    
    /// tableName
    static let databaseTableName = "vocabularies"
    
    convenience init(word: WordEntry) {
        self.init(wordEntry: word, familiarity: 0, isStar: false, lastViewedTime: .now, examples: [], kkPronunciation: "")
    }
    
}
