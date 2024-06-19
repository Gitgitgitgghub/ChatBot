//
//  NSObject+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation

protocol Applyable {}

extension Applyable {
    @discardableResult
    func apply(_ closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }
}

extension NSObject: Applyable {
    class var className: String {
        return String(describing: self)
    }
    
    var className: String {
        return type(of: self).className
    }
    
}

