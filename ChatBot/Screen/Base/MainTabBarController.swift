//
//  MainTabBarController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/3.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    /// tab頁面列舉
    enum Tab {
        case Home
        case History
        case MyNote
        case Setting
        case MyVocabulary
        
        var viewController: UIViewController {
            let vc: UIViewController
            switch self {
            case .Home:
                vc = ScreenLoader.loadScreen(screen: .home)
            case .History:
                vc = ScreenLoader.loadScreen(screen: .history)
            case .MyNote:
                vc = ScreenLoader.loadScreen(screen: .myNote)
            case .Setting:
                vc = ScreenLoader.loadScreen(screen: .setting)
            case .MyVocabulary:
                vc = ScreenLoader.loadScreen(screen: .MyVocabulary)
            }
            vc.tabBarItem = self.tabBarItem
            // 這邊是讓tabvc的子vc的view從tabbar上方開始
            vc.edgesForExtendedLayout = .init(rawValue: 0)
            return vc
        }
        
        var tabBarItem: UITabBarItem {
            switch self {
            case .Home:
                return UITabBarItem(title: "首頁", image: .init(systemName: "house"), tag: 0)
            case .MyVocabulary:
                return UITabBarItem(title: "單字", image: .init(systemName: "textformat.abc"), tag: 1)
            case .History:
                return UITabBarItem(title: "聊天記錄", image: .init(systemName: "clock.fill"), tag: 2)
            case .MyNote:
                return UITabBarItem(title: "我的筆記", image: .init(systemName: "note.text"), tag: 3)
            case .Setting:
                return UITabBarItem(title: "設定", image: .init(systemName: "gear"), tag: 4)
            }
        }
    }
    
    private let tabs: [Tab] = [.Home, .MyVocabulary, .History, .MyNote, .Setting]
    private lazy var tabViewControllers = self.tabs.map({ $0.viewController })

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        prepare()
    }
    
    /// 這裡做一些準備工作
    private func prepare() {
        // SpeechVoiceManager初始化一下
        _ = SpeechVoiceManager.shared
    }
    
    /// 創建子視圖控制器
    private func setup() {
        // 這邊是讓tabvc的view從navigationbar下方開始
        edgesForExtendedLayout = .init(rawValue: 0)
        viewControllers = tabViewControllers
    }

}





