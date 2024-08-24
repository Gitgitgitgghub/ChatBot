//
//  VocabularyManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation
import Combine
import GRDB

class VocabularyManager {
    
    static let share = VocabularyManager()
    let dbQueue = DatabaseManager.shared.dbQueue!
    private var subscriptions = Set<AnyCancellable>()
    
    private init() {}
    
    /// 讀取json裡面的單字並且存到db
    private func initialVocabulary() {
        let decoder = TOEICWordDecoder()
        decoder.decode()
            .flatMap({ words in
                let vocabularies = words.map({ VocabularyModel(word: $0) })
                return self.saveVocabulayPackage(vocabularies: vocabularies)
            })
            .sink { completion in
                if case .failure(let error) = completion {
                    print("讀取json至資料庫 error: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                print("讀取json至資料庫成功")
            }
            .store(in: &subscriptions)
    }
    
    /// 檢查並配置單字資料表
    func checkAndPopulateDatabase() {
        dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            return try VocabularyModel.fetchCount(db)
        }
        .sink { completion in
            if case .failure(let error) = completion {
                print("檢查資料庫是否為空時發生錯誤: \(error.localizedDescription)")
            }
        } receiveValue: { count in
            if count == 0 {
                // 資料庫為空，執行解碼和保存操作
                self.initialVocabulary()
            } else {
                print("資料庫中已有數據，無需再次導入")
            }
        }
        .store(in: &subscriptions)
    }
    
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
    
    /// 取得單字
    /// - Parameters:
    ///   - letter: 字母開頭，nil 為不指定
    ///   - limit: 數量，nil 為不指定
    ///   - isStarOnly: 是否只取出isStar = true
    ///   - useFamiliarity: 是否按照"familiarity" 升序排序
    ///   - useLastViewedTime: 是否按照"lastViewedTime" 升序排序
    /// - Returns: AnyPublisher<[VocabularyModel], Error>
    func fetchVocabulary(letter: String? = nil, limit: Int? = nil, isStarOnly: Bool = false, useFamiliarity: Bool = false, useLastViewedTime: Bool = false) -> AnyPublisher<[VocabularyModel], Error> {
        return dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            var request = VocabularyModel.all()
            // 如果 letter 不為 nil，則進行篩選
            if let letter = letter {
                let pattern = "\(letter)%"
                request = request.filter(sql: "wordEntry ->> 'word' LIKE LOWER(?)", arguments: [pattern])
            }
            // 如果 isStarOnly 為 true，則進行篩選
            if isStarOnly {
                request = request.filter(Column("isStar") == true)
            }
            // 按照 familiarity 和 lastViewedTime 升序排序
            if useFamiliarity && useLastViewedTime {
                request = request.order(
                    Column("familiarity").asc,
                    Column("lastViewedTime").asc
                )
            } else if useFamiliarity {
                request = request.order(Column("familiarity").asc)
            } else if useLastViewedTime {
                request = request.order(Column("lastViewedTime").asc)
            }
            // 限制結果數量
            if let limit = limit {
                request = request.limit(limit)
            }
            return try request
                .fetchAll(db)
        }
        .eraseToAnyPublisher()
    }
    
    /// 取得所有單字的數量
    func countAllVocabulary() -> AnyPublisher<Int, Error> {
        return dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            return try VocabularyModel.fetchCount(db)
        }
        .eraseToAnyPublisher()
    }
    
    /// 取得字母開頭的單字數量
    func countVocabulary(letter: String) -> AnyPublisher<Int, Error> {
        return dbQueue.readPublisher(receiveOn: RunLoop.main) { db in
            let pattern = "\(letter)%"  // 生成 LIKE 查询所需的模式
            return try VocabularyModel
                .filter(sql: "wordEntry ->> 'word' LIKE LOWER(?)", arguments: [pattern])
                .fetchCount(db)
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
