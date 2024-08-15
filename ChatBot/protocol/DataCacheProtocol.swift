//
//  DataCacheProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/15.
//

import Foundation
import Combine

protocol DataCacheProtocol {
    
    associatedtype ValueType
    
    var cache: [String: ValueType] { get set }
    var subscriptions: Set<AnyCancellable> { get set }
    
    // 獲取缓存
    func get(forKey key: String) -> ValueType?
    
    // 設置缓存
    mutating func set(_ value: ValueType, forKey key: String)
    
    // 移除缓存
    mutating func remove(forKey key: String)
    
    // 清空缓存
    mutating func clear()
}

extension DataCacheProtocol {
    
    func get(forKey key: String) -> ValueType? {
        return cache[key]
    }
    
    mutating func set(_ value: ValueType, forKey key: String) {
        cache[key] = value
    }
    
    mutating func remove(forKey key: String) {
        cache.removeValue(forKey: key)
    }
    
    mutating func clear() {
        cache.removeAll()
    }
}
