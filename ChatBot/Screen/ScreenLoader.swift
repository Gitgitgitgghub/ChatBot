//
//  ScreenLoader.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/3.
//

import Foundation
import UIKit



class ScreenLoader {
    
    enum Screen {
        /// 登入畫面
        case login
        /// 聊天畫面
        case chat(lauchModel: ChatViewController.ChatLaunchMode)
        /// tab
        case mainTab
        /// 首頁
        case home
        /// 聊天歷史
        case history
    }
    
    static func loadScreen(screen: Screen) -> UIViewController {
        switch screen {
        case .login: return LoginViewController()
        case .chat(lauchModel: let lauchModel): return ChatViewController(chatLaunchMode: lauchModel)
        case .mainTab: return UINavigationController(rootViewController: MainTabBarController())
        case .home: return HomeViewController()
        case .history: return HistoryViewController()
        }
    }
}
