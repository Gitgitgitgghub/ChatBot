//
//  VocabularyManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation
import Combine

class VocabularyManager {
    
    static let share = VocabularyManager()
    let dbQueue = DatabaseManager.shared.dbQueue!
    
    private init() {}
    
    /// 取得資料庫中所有單字
    func fetchAllVocabulary() -> AnyPublisher<[VocabularyModel], Error> {
        return dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            return try VocabularyModel.fetchAll(db)
        }
        .eraseToAnyPublisher()
    }
    
    /// 隨機取得資料庫中Ｎ個單字
    func fetchRandomVocabularies(count: Int) -> AnyPublisher<[VocabularyModel], Error> {
        return dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            try VocabularyModel
                .order(sql: "RANDOM()")
                .limit(count)
                .fetchAll(db)
        }
        .eraseToAnyPublisher()
    }
    
    /// 保存單字
    func saveVocabulay(vocabulary: VocabularyModel) -> AnyPublisher<Void, Error> {
        return saveVocabulayPackage(vocabularies: [vocabulary])
    }
    
    /// 保存所有單字
    func saveVocabulayPackage(vocabularies: [VocabularyModel]) -> AnyPublisher<Void, Error> {
        return dbQueue.writePublisher(receiveOn: RunLoop.main) { db in
            for vocabulary in vocabularies {
                try vocabulary.save(db)
            }
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
}
