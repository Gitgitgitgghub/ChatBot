//
//  NoActionTextView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/31.
//

import Foundation
import UIKit

class NoActionTextView: UITextView {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
}
