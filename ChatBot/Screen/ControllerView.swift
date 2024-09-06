//
//  ControllerView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import Foundation
import UIKit

protocol ControllerViewProtocol {
    
    var backgroundColor: UIColor { get set }
    var loadingView: LoadingView { get set }
    func initUI()
    
}

class ControllerView: NSObject, ControllerViewProtocol {
    
    var backgroundColor: UIColor = .systemBackground
    var view: UIView
    var loadingView = LoadingView(frame: .init(origin: .zero, size: .init(width: 80, height: 80)), type: .ballScaleMultiple, color: .white, padding: 0)
    
    required init(view: UIView) {
        self.view = view
        super.init()
        self.view.backgroundColor = backgroundColor
        self.addLoadingView()
        initUI()
    }
    
    func initUI() {
        
    }
    
    deinit {
        print("object: \(className) had been deinited")
    }
    
}

//MARK: - ControllerView + loadingView
extension ControllerView {
    
    func addLoadingView() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 150, height: 150))
            make.center.equalToSuperview()
        }
    }
    
    func showLoadingView(status: LoadingStatus, with msg: String? = nil) {
        switch status {
        case .loading(message: let message):
            if let message = msg {
                loadingView.show(withMessage: message)
            }else {
                loadingView.show(withMessage: message)
            }
            view.bringSubviewToFront(loadingView)
        default:
            loadingView.hide()
        }
    }
    
}
