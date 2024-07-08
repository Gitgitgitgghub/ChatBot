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
    
    func showToast(title: String = "", message: String, autoDismiss after: Double = 1.5, completion: (() -> ())? = nil) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(vc, animated: true)
        delay(delay: after) {
            vc.dismiss(animated: true)
            completion?()
        }
    }
    
}
