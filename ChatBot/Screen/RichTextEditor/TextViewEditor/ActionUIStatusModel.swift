//
//  ActionUIStatusModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/5.
//

import Foundation
import UIKit


struct ActionUIStatusModel {
    
    var bold = false
    var italic = false
    var underline = false
    var strikethrough = false
    var textAlignLeft = true
    var textAlignCenter = false
    var textAlignRight = false
    var fontColor: UIColor = .white
    var highlightColor: UIColor = .clear
    var fontSize: CGFloat = SystemDefine.Message.defaultTextFont.pointSize
    var fontName: String = SystemDefine.Message.defaultTextFont.fontName
    
    var underlineStyle: Any {
        get {
            return (self.underline ? NSUnderlineStyle.single.rawValue :nil) as Any
        }
    }
    var strikethroughLineStyle: Any {
        get {
            return (self.strikethrough ? NSUnderlineStyle.single.rawValue :nil) as Any
        }
    }
    
    mutating func toggleAlignFormat(selectedAction: Action) {
        switch selectedAction {
        case .textAlignLeft:
            textAlignLeft = true
            textAlignCenter = false
            textAlignRight = false
        case .textAlignCenter:
            textAlignLeft = false
            textAlignCenter = true
            textAlignRight = false
        case .textAlignRight:
            textAlignLeft = false
            textAlignCenter = false
            textAlignRight = true
        default:
            break
        }
    }
    
    mutating func toggleActionButton(selectedAction: Action) {
        guard selectedAction.enableToggle() else { return }
        switch selectedAction {
        case .bold:
            bold.toggle()
        case .italic:
            italic.toggle()
        case .underline:
            underline.toggle()
        case .strikethrough:
            strikethrough.toggle()
        case .textAlignLeft, .textAlignCenter, .textAlignRight:
            toggleAlignFormat(selectedAction: selectedAction)
            return
        default: return
        }
    }
    
}

extension ActionUIStatusModel {
    
    enum Action: CaseIterable {
        
        case bold
        case italic
        case underline
        case strikethrough
        case textAlignLeft
        case textAlignCenter
        case textAlignRight
        case insertImage
        case link
        case fontColor
        case highlightColor
        case fontSize
        case fontName
     
        var image: UIImage? {
            switch self {
            case .bold: return.init(systemName: "bold")
            case .italic: return.init(systemName: "italic")
            case .underline: return.init(systemName: "underline")
            case .strikethrough: return.init(systemName: "strikethrough")
            case .textAlignLeft: return.init(systemName: "text.alignleft")
            case .textAlignCenter: return.init(systemName: "text.aligncenter")
            case .textAlignRight: return.init(systemName: "text.alignright")
            case .insertImage: return.init(systemName: "photo")
            case .link: return.init(systemName: "link")
            default: return nil
            }
        }
        /// 動作名稱
        var actionName: String {
            switch self {
            case .bold: return "粗體"
            case .italic: return "斜體"
            case .underline: return "底線"
            case .strikethrough: return "刪除線"
            case .textAlignLeft: return "靠左對齊"
            case .textAlignCenter: return "靠中對齊"
            case .textAlignRight: return "靠右對齊"
            case .insertImage: return "插入圖片"
            case .link: return "插入連結"
            case .fontColor: return "字體顏色"
            case .highlightColor: return "背景顏色"
            case .fontSize: return "字體大小"
            case .fontName: return "字型"
            }
        }
        /// 是否可用
        var enable: Bool {
            return true
        }
        
        static func enableActions() -> [Action] {
            return allCases.filter({ $0.enable })
        }
        
        /// 可否切換至選中狀態
        func enableToggle() -> Bool {
            switch self {
            case .insertImage, .link, .fontColor, .fontSize, .highlightColor, .fontName: return false
            default: return true
            }
        }
    }
    
}
