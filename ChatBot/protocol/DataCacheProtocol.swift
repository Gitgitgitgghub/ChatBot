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
    associatedtype Key: Hashable
    
    var cacheManager: CacheManager<Key, ValueType> { get }
    var subscriptions: Set<AnyCancellable> { get set }
    
    // 獲取缓存
    func getCache(forKey key: Key) -> ValueType?
    
    // 設置缓存
    func setCache(_ value: ValueType, forKey key: Key)
    
    // 移除缓存
    func removeCache(forKey key: Key)
    
    // 清空缓存
    func clearCache()
}

extension DataCacheProtocol {
    func getCache(forKey key: Key) -> ValueType? {
        return cacheManager.getCache(forKey: key)
    }
    
    func setCache(_ value: ValueType, forKey key: Key) {
        cacheManager.setCache(value, forKey: key)
    }
    
    func removeCache(forKey key: Key) {
        cacheManager.removeCache(forKey: key)
    }
    
    func clearCache() {
        cacheManager.clearCache()
    }
}

