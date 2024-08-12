//
//  VocabularyModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation
import GRDB

class VocabularyModel: Codable, FetchableRecord, PersistableRecord {
    
    var id: Int64?
    var wordEntry: WordEntry
    var familiarity: Int = 0
    var isStar = false
    var lastViewedTime: Date
    
    init(id: Int64? = nil, wordEntry: WordEntry, familiarity: Int, isStar: Bool, lastViewedTime: Date) {
        self.id = id
        self.wordEntry = wordEntry
        self.familiarity = familiarity
        self.isStar = isStar
        self.lastViewedTime = lastViewedTime
    }
    
    func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension VocabularyModel {
    
    /// tableName
    static let databaseTableName = "vocabularys"
    
    convenience init(word: WordEntry) {
        self.init(wordEntry: word, familiarity: 0, isStar: false, lastViewedTime: .now)
    }
    
}
