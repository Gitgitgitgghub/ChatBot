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
        case home_history
        /// 設定畫面
        case home_setting
        /// 我的筆記
        case home_myNote
        /// 我的單字頁面
        case home_myVocabulary
        /// html富文本編輯器
        case HTMLEditor(content: Data?, inputBackgroundColor: UIColor, delegate: HtmlEditorViewControllerDelegate)
        /// 筆記畫面
        case note(myNote: MyNote)
        /// 富文本編輯器
        case textEditor(content: Data?,inputBackgroundColor: UIColor, delegate: TextEditorViewControllerDelegate)
        /// 單字內頁
        case vocabulary(vocabularies: [VocabularyModel], startIndex: Int)
        /// 翻卡測驗
        case flipCard
    }
    
    static func loadScreen(screen: Screen) -> UIViewController {
        switch screen {
        case .login: return LoginViewController()
        case .chat(lauchModel: let lauchModel): return ChatViewController(chatLaunchMode: lauchModel)
        case .mainTab: return UINavigationController(rootViewController: MainTabBarController())
        case .home: return HomeViewController()
        case .home_history: return HistoryViewController()
        case .home_setting: return SettingViewController()
        case .home_myNote: return MyNoteViewController()
        case .HTMLEditor(content: let content, let color, delegate: let delegate): 
            return HtmlEditorViewController(content: content, inputBackgroundColor: color, delegate: delegate)
        case .note(myNote: let myNote): return NoteViewController(myNote: myNote)
        case .textEditor(content: let content, inputBackgroundColor: let inputBackgroundColor, let delegate):
            return TextEditorViewController(content: content, inputBackgroundColor: inputBackgroundColor, delegate: delegate)
        case .home_myVocabulary: return MyVocabularyViewController()
        case .vocabulary(vocabularies: let vocabularies, startIndex: let startIndex): return VocabularyViewController(vocabularies: vocabularies, startIndex: startIndex)
        case .flipCard: return FlipCardViewContoller()
        }
    }
}
