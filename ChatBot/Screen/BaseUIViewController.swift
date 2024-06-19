//
//  BaseUIViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import Foundation
import UIKit
import Combine

class BaseUIViewController: UIViewController {
    
    var subscriptions = Set<AnyCancellable>()
    
    deinit {
        subscriptions.removeAll()
        print("ViewController: \(className) had been deinited")
    }
    
    
}
