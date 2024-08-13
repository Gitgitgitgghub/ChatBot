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
    
    func fetchAllVocabulary() -> AnyPublisher<[VocabularyModel], Error> {
        return dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            return try VocabularyModel.fetchAll(db)
        }
        .eraseToAnyPublisher()
    }
    
    /// 保存單字
    func saveVocabulay(vocabulary: VocabularyModel) -> AnyPublisher<Void, Error> {
        return saveVocabulayPackage(vocabularys: [vocabulary])
    }
    
    /// 保存所有單字
    func saveVocabulayPackage(vocabularys: [VocabularyModel]) -> AnyPublisher<Void, Error> {
        return dbQueue.writePublisher(receiveOn: RunLoop.main) { db in
            for vocabulary in vocabularys {
                try vocabulary.save(db)
            }
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
}
