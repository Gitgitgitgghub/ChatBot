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
        views.chatButton.addTarget(self, action: #selector(toChatVc), for: .touchUpInside)
    }
    
    /// 至聊天Vc
    @objc private func toChatVc() {
        let vc = ScreenLoader.loadScreen(screen: .chat(lauchModel: .normal))
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
