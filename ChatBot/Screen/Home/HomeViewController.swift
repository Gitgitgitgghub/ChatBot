//
//  HomeViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/3.
//

import Foundation
import UIKit


class HomeViewController: UIViewController {
    
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
            case .GrammarExam:
                GrammarPointSelectorViewController().show(in: self) { [weak self] selectedGrammarPoint in
                    guard let `self` = self else { return }
                    print("你選擇了: \(selectedGrammarPoint?.rawValue ?? "nil")")
                    ScreenLoader.toScreen(screen: .englishExam(questionType: .grammar(point: selectedGrammarPoint), vocabularies: []), viewController: self)
                }
            case .readingTest:
                ScreenLoader.toScreen(screen: .englishExam(questionType: .reading, vocabularies: []), viewController: self)
            case .conversation:
                self.showConversationScenarioSelector()
            }
        }
    }
    
    private func showConversationScenarioSelector() {
        let alert = UIAlertController(title: "請選擇對話場景", message: nil, preferredStyle: .actionSheet)
        SystemDefine.Conversation.scenarios.forEach { scenario in
            alert.addAction(.init(title: scenario.scenarioTranslation, style: .default, handler: { _ in
                ScreenLoader.toScreen(screen: .conversation(scenario: scenario), viewController: self)
            }))
        }
        alert.addAction(.init(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    /// 至聊天Vc
    private func toChatVc(function: SystemDefine.HomeEnableFunction) {
        var vc: UIViewController
        switch function {
        case .Chat:
            vc = ScreenLoader.loadScreen(screen: .chat(lauchModel: .normal))
        case .GrammarCorrection:
            vc = ScreenLoader.loadScreen(screen: .chat(lauchModel: .prompt(title: function.title, prompt: function.prompt)))
        default: return
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
