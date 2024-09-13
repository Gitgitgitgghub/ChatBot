//
//  CacheManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/19.
//

import Foundation

class CacheManager<Key: Hashable, ValueType> {
    
    private var cache: [Key: ValueType] = [:]
    /// 鍵的array主要用來判斷插入順序
    private var keysQueue: [Key] = []
    /// 最大數量
    private let maxCacheSize: Int
    private let queue = DispatchQueue(label: "com.cacheManager.queue", attributes: .concurrent)
    
    init(maxCacheSize: Int = 64) {
        self.maxCacheSize = maxCacheSize
    }

    func getCache(forKey key: Key) -> ValueType? {
        return queue.sync {
            return cache[key]
        }
    }

    func setCache(_ value: ValueType, forKey key: Key) {
        // 執行序安全自己用一個queue來處理 先進先出
        queue.async(flags: .barrier) {
            if self.cache[key] == nil, self.cache.count >= self.maxCacheSize {
                self.evictCache()
            }
            self.cache[key] = value
            self.keysQueue.append(key)
        }
    }

    func removeCache(forKey key: Key) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
            self.keysQueue.removeAll { $0 == key }
        }
    }

    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
            self.keysQueue.removeAll()
        }
    }

    private func evictCache() {
        if let oldestKey = keysQueue.first {
            cache.removeValue(forKey: oldestKey)
            keysQueue.removeFirst()
        }
    }
}


