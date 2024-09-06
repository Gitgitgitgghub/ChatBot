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
    let coffeeBackground = UIColor.hex("#4E342E")
    
    // 金色，用於重要的標題文字或需要強調的元素，如按鈕文字、標題
    let goldText = UIColor.hex("#FFD700")
    
    // 奶油色，用於主背景，能夠讓介面保持明亮且溫暖
    let creamBackground = UIColor.hex("#FFF8E1")
    
    // 深咖啡色，用於一般文字或重要的文本內容，具有良好的可讀性
    let darkCoffeeText = UIColor.hex("#3E2723")
    
    // 淺咖啡色，用於次要按鈕背景或淺色區塊，能夠與主背景形成對比
    let lightCoffeeButton = UIColor.hex("#BCAAA4")
    
    // 米色，用於次要按鈕背景或次要區塊背景，保持整體色調一致
    let secondaryButtonBackground = UIColor.hex("#D7CCC8")
    
    // 米色，用於次要文字的顏色，讓次要信息區分開來但不會喧賓奪主
    let secondaryText = UIColor.hex("#FFF8E1")
    
    // 深咖啡色，用於一般段落文字或標籤，保持簡潔且具備良好對比度
    let normalText = UIColor.hex("#5D4037")
    
    // 金色，用於強調標題、重要按鈕或突出信息
    let titleHighlight = UIColor.hex("#FFC107")
    
    private init() {}
    static let shared = AppColors()
}


extension UIColor {
    
    static func fromAppColors(_ keyPath: KeyPath<AppColors, UIColor>) -> UIColor {
            return AppColors.shared[keyPath: keyPath]
    }
}
