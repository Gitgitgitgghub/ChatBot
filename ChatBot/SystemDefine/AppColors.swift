//
//  AppColors.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/6.
//

import Foundation
import UIKit

import UIKit

class AppColors {
    
    // 深咖啡色，用於 NavigationBar 背景或深色背景的區塊
    let coffeeBackground = #colorLiteral(red: 0.3812614679, green: 0.2670597434, blue: 0.236638397, alpha: 1)
    
    // 金色，用於重要的標題文字或需要強調的元素，如按鈕文字、標題
    let goldText = #colorLiteral(red: 1, green: 0.8632914424, blue: 0, alpha: 1)
    
    // 奶油色，用於主背景，能夠讓介面保持明亮且溫暖
    let creamBackground = #colorLiteral(red: 1, green: 0.9763762355, blue: 0.9051827788, alpha: 1)
    
    // 深咖啡色，用於一般文字或重要的文本內容，具有良好的可讀性
    let darkCoffeeText = #colorLiteral(red: 0.3124428093, green: 0.2051022947, blue: 0.1825570464, alpha: 1)
    
    // 淺咖啡色，用於次要按鈕背景或淺色區塊，能夠與主背景形成對比
    let lightCoffeeButton = #colorLiteral(red: 0.7858310342, green: 0.7239536643, blue: 0.7024849653, alpha: 1)

    // 米色，用於次要按鈕背景或次要區塊背景，保持整體色調一致
    let secondaryButtonBackground = #colorLiteral(red: 0.8741380572, green: 0.8377121687, blue: 0.8241562247, alpha: 1)
    
    // 米色，用於次要文字的顏色，讓次要信息區分開來但不會喧賓奪主
    let secondaryText = #colorLiteral(red: 1, green: 0.9763762355, blue: 0.9051827788, alpha: 1)
    
    // 深咖啡色，用於一般段落文字或標籤，保持簡潔且具備良好對比度
    let normalText = #colorLiteral(red: 0.4426271915, green: 0.3207788467, blue: 0.2784533799, alpha: 1)
    
    // 金色，用於強調標題、重要按鈕或突出信息
    let titleHighlight = #colorLiteral(red: 1, green: 0.7939539552, blue: 0, alpha: 1)
    
    private init() {}
    static let shared = AppColors()
}


extension UIColor {
    
    static func fromAppColors(_ keyPath: KeyPath<AppColors, UIColor>) -> UIColor {
            return AppColors.shared[keyPath: keyPath]
    }
}
