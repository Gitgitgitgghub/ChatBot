//
//  extensions.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import Foundation

func delay(delay: Double, block: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
}

func unwrap<T>(_ lhs: T?, _ rhs: T) -> T {
    if let unwrappedLhs = lhs {
        return unwrappedLhs
    }
    return rhs
}


extension String {
    
    /// 字串加密成base64
    func encodeToBase64() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    /// 從base64 decode回原始字串
    func decodeFromBase64() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
