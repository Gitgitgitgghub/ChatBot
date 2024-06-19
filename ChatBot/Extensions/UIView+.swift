//
//  UIView+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import Foundation
import UIKit

extension UIView {
    
    var isVisible: Bool {
        set {
            self.isHidden = !newValue
        }
        get {
            return !self.isHidden
        }
    }
    
    var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = true
        }
        get {
            return layer.cornerRadius
        }
    }
    
}
