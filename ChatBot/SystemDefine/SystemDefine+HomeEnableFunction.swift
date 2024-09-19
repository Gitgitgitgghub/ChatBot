//
//  SystemDefine+HomeEnableFunction.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/18.
//

import Foundation

//MARK: - 首頁按鈕功能
extension SystemDefine {
    
    /// 首頁按鈕功能
    enum HomeEnableFunction: RawRepresentable, CaseIterable {
        
        /// 聊天
        case Chat
        /// 語法糾正
        case GrammarCorrection
        /// 文法考試
        case GrammarExam
        /// 閱讀測驗
        case readingTest
        /// 語音對話
        case conversation
        
        var rawValue: Int {
            switch self {
            case .Chat: return 0
            case .GrammarCorrection: return 1
            case .GrammarExam: return 2
            case .readingTest: return 3
            case .conversation: return 4
            }
        }
        var title: String {
            switch self {
            case .Chat: return "聊天"
            case .GrammarCorrection: return "語法糾正"
            case .GrammarExam: return "文法考試"
            case .readingTest: return "閱讀測驗"
            case .conversation: return "語音對話"
            }
        }
        var enable: Bool {
            switch self {
            case .Chat: return true
            case .GrammarCorrection: return true
            case .GrammarExam: return true
            case .readingTest: return true
            case .conversation: return true
            }
        }
        var prompt: String {
            switch self {
            case .GrammarCorrection: return "Help me correct the grammar mistakes in the following English sentence. List the corrected sentence directly, then list each mistake in Traditional Chinese, including why it's wrong and how to fix it."
            default: return ""
            }
        }
        
        typealias RawValue = Int
        
        init?(rawValue: Int) {
            switch rawValue {
            case 0: self = .Chat
            case 1: self = .GrammarCorrection
            case 2: self = .GrammarExam
            case 3: self = .readingTest
            case 4: self = .conversation
            default: return nil
            }
        }
    }
    
}
