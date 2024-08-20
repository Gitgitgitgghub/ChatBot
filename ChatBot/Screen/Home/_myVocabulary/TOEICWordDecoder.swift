//
//  TOEICWordDecoder.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation
import Combine

class TOEICWordDecoder {
    
    /// 定義解碼方法
    func decodeWords(from jsonData: Data) -> [WordEntry]? {
        let decoder = JSONDecoder()
        do {
            var wordList = try decoder.decode([WordEntry].self, from: jsonData)
            /// 單字標準化 json裡面有些單字例如"backﬁre" // 使用了连字 ﬁ (U+FB01)
            /// 要把他轉換成普通的f i
            wordList = wordList.map { entry in
                var modifiedEntry = entry
                modifiedEntry.word = entry.word
                    .removeAllLigatures()
                return modifiedEntry
            }
            return wordList
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
    
    func decode() -> AnyPublisher<[WordEntry], Error> {
        return Future { promise in
            DispatchQueue.global().async {
                do {
                    let url = Bundle.main.url(forResource: "TOEICWord", withExtension: "json")!
                    let jsonData = try Data(contentsOf: url)
                    let wordList = self.decodeWords(from: jsonData) ?? []
                    promise(.success(wordList))
                } catch {
                    print("Error reading JSON file: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
