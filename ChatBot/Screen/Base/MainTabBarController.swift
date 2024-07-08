//
//  MainTabBarController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/3.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    /// 創建子視圖控制器
    private func setup() {
        // 這邊是讓tabvc的view從navigationbar下方開始
        edgesForExtendedLayout = .init(rawValue: 0)
        let homeViewController = HomeViewController()
        let historyViewController = HistoryViewController()
        // 這邊是讓tabvc的子vc的view從tabbar上方開始
        homeViewController.edgesForExtendedLayout = .init(rawValue: 0)
        historyViewController.edgesForExtendedLayout = .init(rawValue: 0)
        homeViewController.tabBarItem = UITabBarItem(title: "首頁", image: .init(systemName: "house"), tag: 0)
        historyViewController.tabBarItem = UITabBarItem(title: "聊天記錄", image: .init(systemName: "clock.fill"), tag: 1)
        let viewControllerList = [homeViewController, historyViewController]
        viewControllers = viewControllerList
    }

}





