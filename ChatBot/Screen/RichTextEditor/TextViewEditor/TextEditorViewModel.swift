//
//  TextEditorViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/5.
//

import Foundation
import UIKit


class TextEditorViewModel: BaseViewModel<TextEditorViewModel.InputEvent, TextEditorViewModel.OutputEvent> {
    
    typealias Action = ActionUIStatusModel.Action
    enum InputEvent {
        case toggleActionButton(indexPath: IndexPath)
        case addAttribute(key: NSAttributedString.Key?, value: Any?)
        case reapplyTypingAttributes
    }
    enum OutputEvent {
        case typingAttributesChange(typingAttributes: [NSAttributedString.Key : Any])
        case actionUIChange
    }
    
    private(set) var actions: [Action] = Action.enableActions()
    private(set) var actionUIStatusModel: ActionUIStatusModel = .init()
    private(set) var typingAttributes: [NSAttributedString.Key : Any] = [.font : SystemDefine.Message.defaultTextFont,
                                                            .foregroundColor : SystemDefine.Message.textColor]
    var font: UIFont {
        if let font = self.typingAttributes[.font] as? UIFont {
            return font
        }
        return .systemFont(ofSize: 16)
    }
    
    func bindInputEvent() {
        inputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .addAttribute(key: let key, value: let value):
                    self.addAttribute(key: key, value: value)
                case .toggleActionButton(indexPath: let indexPath):
                    self.toggleActionButton(indexPath: indexPath)
                case .reapplyTypingAttributes:
                    self.reapplyTypingAttributes()
                }
            }.store(in: &subscriptions)
    }
    
    private func reapplyTypingAttributes() {
        addAttribute(key: nil, value: nil)
    }
    
    private func addAttribute(key: NSAttributedString.Key?, value: Any?) {
        if let attribute = key {
            typingAttributes[attribute] = value
            handleFontChange(key: attribute, value: value)
        }
        outputSubject.send(.typingAttributesChange(typingAttributes: typingAttributes))
    }
    
    /// 把關於字體相關的參數更新到actions ui上
    private func handleFontChange(key: NSAttributedString.Key, value: Any?) {
        switch key {
        case .foregroundColor:
            guard let value = value as? UIColor else { return }
            actionUIStatusModel.fontColor = value
        case .backgroundColor:
            guard let value = value as? UIColor else { return }
            actionUIStatusModel.highlightColor = value
        case .font:
            actionUIStatusModel.fontSize = font.pointSize
            actionUIStatusModel.fontName = font.familyName
        default: return
        }
        outputSubject.send(.actionUIChange)
    }
    
    func findActionIndex(targetAction: Action) -> Int? {
        for (index, action) in actions.enumerated() {
            switch (action, targetAction) {
            case (.bold, .bold),
                (.italic, .italic),
                (.underline, .underline),
                (.strikethrough, .strikethrough),
                (.textAlignLeft, .textAlignLeft),
                (.textAlignCenter, .textAlignCenter),
                (.textAlignRight, .textAlignRight),
                (.insertImage, .insertImage),
                (.link, .link),
                (.fontColor, .fontColor),
                (.highlightColor, .highlightColor),
                (.fontSize, .fontSize),
                (.fontName, .fontName):
                return index
            default:
                continue
            }
        }
        return nil
    }
    
    /// 處理有切換狀態的按鈕
    private func toggleActionButton(indexPath: IndexPath) {
        actionUIStatusModel.toggleActionButton(selectedAction: actions[indexPath.item])
        outputSubject.send(.actionUIChange)
    }
    
    /// 取得該顯示的字型
    func getFont() -> UIFont {
        let isBold = actionUIStatusModel.bold
        let isItalic = actionUIStatusModel.italic
        if isBold && isItalic {
            return font.boldItalic()
        }else if isBold {
            return font.bold()
        }else if isItalic {
            return font.italic()
        }else {
            return font.withoutTraits()
        }
    }
    
}
