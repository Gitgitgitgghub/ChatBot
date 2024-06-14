//
//  ControllerView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import Foundation
import UIKit

protocol ControllerViewProtocol {
    
    func initUI()
    
}

class ControllerView: ControllerViewProtocol {
    
    var view: UIView
    
    required init(view: UIView) {
        self.view = view
        initUI()
    }
    
    func initUI() {
        
    }
    
}
