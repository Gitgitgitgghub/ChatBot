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
