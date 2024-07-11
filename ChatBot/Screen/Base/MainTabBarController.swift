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
        prepare()
    }
    
    /// 這裡做一些準備工作
    private func prepare() {
        SpeechVoiceManager.shared.prepareSpeechSynthesizer()
    }
    
    /// 創建子視圖控制器
    private func setup() {
        // 這邊是讓tabvc的view從navigationbar下方開始
        edgesForExtendedLayout = .init(rawValue: 0)
        let homeViewController = ScreenLoader.loadScreen(screen: .home)
        let historyViewController = ScreenLoader.loadScreen(screen: .history)
        let myNoteViewController = ScreenLoader.loadScreen(screen: .myNote)
        let settingViewController = ScreenLoader.loadScreen(screen: .setting)
        // 這邊是讓tabvc的子vc的view從tabbar上方開始
        homeViewController.edgesForExtendedLayout = .init(rawValue: 0)
        historyViewController.edgesForExtendedLayout = .init(rawValue: 0)
        homeViewController.tabBarItem = UITabBarItem(title: "首頁", image: .init(systemName: "house"), tag: 0)
        historyViewController.tabBarItem = UITabBarItem(title: "聊天記錄", image: .init(systemName: "clock.fill"), tag: 1)
        myNoteViewController.tabBarItem = UITabBarItem(title: "我的筆記", image: .init(systemName: "note.text"), tag: 2)
        settingViewController.tabBarItem = UITabBarItem(title: "設定", image: .init(systemName: "gear"), tag: 3)
        let viewControllerList = [homeViewController, historyViewController, myNoteViewController, settingViewController]
        viewControllers = viewControllerList
    }

}





