//
//  extensions.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import Foundation
import UIKit

func delay(delay: Double, block: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
}

func unwrap<T>(_ lhs: T?, _ rhs: T) -> T {
    if let unwrappedLhs = lhs {
        return unwrappedLhs
    }
    return rhs
}


extension String {
    
    /// 字串加密成base64
    func encodeToBase64() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    /// 從base64 decode回原始字串
    func decodeFromBase64() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    var isNotEmpty: Bool {
        return !isEmpty
    }
    
    func containsChinese() -> Bool {
        for scalar in unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }
    
    /// 使用 Unicode 正規化形式 NFKD 將連字分解為獨立的字符"ﬁﬂﬃﬄ"
    func removeAllLigatures() -> String {
        let decomposedString = self.precomposedStringWithCompatibilityMapping
        // 去掉重音符
        return decomposedString.folding(options: .diacriticInsensitive, locale: .current)
    }
}

extension FileManager {
    
    static var documentsDirectory: URL {
        return `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
}

extension UIColor {
    
    var hexColor: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
    
    // 使用 RGB 和 Alpha 初始化颜色
    static func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> UIColor {
        return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
    
    // 使用 HEX 代码初始化颜色
    static func hex(_ hex: String, alpha: CGFloat = 1.0) -> UIColor {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 处理 # 前缀
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }
        
        // 确保格式正确
        assert(hexFormatted.count == 6, "Invalid hex code used.")
        
        // 将 HEX 代码转为 RGB 值
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
}

extension UIFont{
    
    func withTraits(_ traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = fontDescriptor
            .withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    
    func bold() -> UIFont {
        return withTraits(.traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(.traitItalic)
    }
    
    func boldItalic() -> UIFont {
        return withTraits([.traitBold, .traitItalic])
    }
    
    func withoutTraits() -> UIFont {
        return withTraits([])
    }
    
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    
    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
}

extension UIStackView {
    
    func removeAllArrangedSubView() {
        for view in arrangedSubviews {
            view.removeFromSuperview()
        }
    }
    
}
