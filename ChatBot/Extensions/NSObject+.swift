//
//  NSObject+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation


extension NSObject {
    class var className: String {
        return String(describing: self)
    }
    
    var className: String {
        return type(of: self).className
    }
    
}
