//
//  UITextView+.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/24.
//

import Foundation
import UIKit
import SDWebImage


extension UITextView {
    func updateHeight() {
        let size = self.sizeThatFits(CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
        if let heightConstraint = self.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.constant = size.height
        }
    }
}


