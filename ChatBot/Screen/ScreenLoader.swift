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
        /// 設定畫面
        case setting
        /// 我的筆記
        case myNote
        /// html 文字編輯
        case HTMLEditor(attr: NSAttributedString, delegate: HtmlEditorViewControllerDelegate)
    }
    
    static func loadScreen(screen: Screen) -> UIViewController {
        switch screen {
        case .login: return LoginViewController()
        case .chat(lauchModel: let lauchModel): return ChatViewController(chatLaunchMode: lauchModel)
        case .mainTab: return UINavigationController(rootViewController: MainTabBarController())
        case .home: return HomeViewController()
        case .history: return HistoryViewController()
        case .setting: return SettingViewController()
        case .myNote: return MyNoteViewController()
        case .HTMLEditor(attr: let attr, delegate: let delegate): return HtmlEditorViewController(attr: attr, delegate: delegate)
        }
    }
}
