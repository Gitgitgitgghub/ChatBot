//
//  Array+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/28.
//

import Foundation

extension Array where Element: Hashable {
    /// 取兩個陣列相同數值
    func commonElements(with other: [Element]) -> [Element] {
        let set1 = Set(self)
        let set2 = Set(other)
        let commonSet = set1.intersection(set2)
        return Array(commonSet)
    }
}


extension Array {
    
    /// 陣列分割成Ｎ個一組的陣列
    func chunked(by chunkSize: Int) -> [[Element]] {
        guard count != 0 else { return [[]] }
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
    
    /// 若取不到值則返回nil
    func getOrNil(index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
    
    /// 取代
    mutating func replace(index: Int, with: Element) {
        guard index >= 0, index < count else { return }
        self[index] = with
    }
    
    /// 取代最後一個
    mutating func replaceLast(with: Element) {
        replace(index: self.count - 1, with: with)
    }
    
    /// 取代第一個
    mutating func replaceFirst(with: Element) {
        replace(index: 0, with: with)
    }
}
