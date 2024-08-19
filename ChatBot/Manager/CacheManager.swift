//
//  CacheManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/19.
//

import Foundation

class CacheManager<Key: Hashable, ValueType> {
    
    private(set) var cache: [Key: ValueType] = [:]
    
    func getCache(forKey key: Key) -> ValueType? {
        return cache[key]
    }
    
    func setCache(_ value: ValueType, forKey key: Key) {
        cache[key] = value
    }
    
    func removeCache(forKey key: Key) {
        cache.removeValue(forKey: key)
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

