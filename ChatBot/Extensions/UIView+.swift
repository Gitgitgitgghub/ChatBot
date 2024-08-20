//
//  UIView+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import Foundation
import UIKit
import SnapKit

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

//MARK: 針對snapKit的extension
extension UIView {
    
    var top: ConstraintItem {
        return snp.top
    }
    
    var leading: ConstraintItem {
        return snp.leading
    }
    
    var trailing: ConstraintItem {
        return snp.trailing
    }
    
    var bottom: ConstraintItem {
        return snp.bottom
    }
    
    var centerX: ConstraintItem {
        return snp.centerX
    }
    
    var centerY: ConstraintItem {
        return snp.centerY
    }
    
}
