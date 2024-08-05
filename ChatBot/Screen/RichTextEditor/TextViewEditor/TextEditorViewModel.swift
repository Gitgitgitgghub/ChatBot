//
//  TextEditorViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/5.
//

import Foundation
import UIKit


class TextEditorViewModel: BaseViewModel<TextEditorViewModel.InputEvent, TextEditorViewModel.OutputEvent> {
    
    typealias Action = TextEditorViewController.Action
    enum InputEvent {
        case toggleActionButton(indexPath: IndexPath)
        case addAttribute(key: NSAttributedString.Key?, value: Any?)
        case reapplyTypingAttributes
    }
    enum OutputEvent {
        case typingAttributesChange(typingAttributes: [NSAttributedString.Key : Any])
        case actionUIChange
    }
    
    private(set) var actions: [Action] = [
        .bold(isSeleted: false),
        .italic(isSeleted: false),
        .underline(isSeleted: false),
        .strikethrough(isSeleted: false),
        .textAlignLeft(isSeleted: false),
        .textAlignCenter(isSeleted: false),
        .textAlignRight(isSeleted: false),
        .insertImage,
        .link,
        .fontColor(color: UIColor.white),
        .highlightColor(color: UIColor.clear),
        .fontSize(size: 16),
        .fontName(foneName: "Arial"),
    ]
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
            if let index = findActionIndex(targetAction: .fontColor(color: .clear)) {
                actions[index] = .fontColor(color: value)
            }
        case .backgroundColor:
            guard let value = value as? UIColor else { return }
            if let index = findActionIndex(targetAction: .highlightColor(color: .clear)) {
                actions[index] = .highlightColor(color: value)
            }
        case .font:
            if let sizeIndex = findActionIndex(targetAction: .fontSize(size: 0)) {
                actions[sizeIndex] = .fontSize(size: font.pointSize)
            }
            if let fontNameIndex = findActionIndex(targetAction: .fontName(foneName: "")) {
                actions[fontNameIndex] = .fontName(foneName: font.familyName)
            }
            
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
        var action = actions[indexPath.item]
        guard action.enableToggle() else { return }
        switch action {
        case .bold(isSeleted: let isSeleted):
            action = .bold(isSeleted: !isSeleted)
        case .italic(isSeleted: let isSeleted):
            action = .italic(isSeleted: !isSeleted)
        case .underline(isSeleted: let isSeleted):
            action = .underline(isSeleted: !isSeleted)
        case .strikethrough(isSeleted: let isSeleted):
            action = .strikethrough(isSeleted: !isSeleted)
        case .textAlignLeft, .textAlignCenter, .textAlignRight:
            toggleAlignFormat(action: action)
            return
        default: return
        }
        actions[indexPath.item] = action
        outputSubject.send(.actionUIChange)
    }
    
    private func toggleAlignFormat(action: Action) {
        actions = actions.map { action in
            switch action {
            case .textAlignLeft, .textAlignCenter, .textAlignRight:
                return action.setSelected(action == action)
            default:
                return action
            }
        }
        outputSubject.send(.actionUIChange)
    }
    
    /// 取得該顯示的字型
    func getFont() -> UIFont {
        var isBold = false
        var isItalic = false
        for action in actions {
            switch action {
            case .bold(let isSeleted): isBold = isSeleted
            case .italic(let isSeleted): isItalic = isSeleted
            default: break
            }
        }
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
    
    func getNSUnderlineStyle() -> NSUnderlineStyle? {
        guard let index = findActionIndex(targetAction: .underline(isSeleted: false)) else { return nil }
        let action = actions[index]
        if case .underline(let isSelected) = action {
            return isSelected ? nil : .single
        }
        return nil
    }
    
    func getStrikethroughlineStyle() -> NSUnderlineStyle? {
        guard let index = findActionIndex(targetAction: .strikethrough(isSeleted: false)) else { return nil }
        let action = actions[index]
        if case .strikethrough(let isSelected) = action {
            return isSelected ? nil : .single
        }
        return nil
    }
    
}
