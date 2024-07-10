//
//  HomeViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/3.
//

import Foundation
import UIKit


class HomeViewController: BaseUIViewController {
    
    private lazy var views = HomeViews(view: self.view)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    private func initUI() {
        views.functionClickListener = { function in
            switch function {
            case .Chat:
                self.toChatVc(function: .Chat)
            case .GrammarCorrection:
                self.toChatVc(function: .GrammarCorrection)
            }
        }
    }
    
    /// 至聊天Vc
    private func toChatVc(function: SystemDefine.HomeEnableFunction) {
        var vc: UIViewController
        switch function {
        case .Chat:
            vc = ScreenLoader.loadScreen(screen: .chat(lauchModel: .normal))
        case .GrammarCorrection:
            vc = ScreenLoader.loadScreen(screen: .chat(lauchModel: .prompt(title: function.title, prompt: function.prompt)))
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
