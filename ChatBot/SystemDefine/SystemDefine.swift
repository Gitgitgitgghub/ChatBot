//
//  SystemDefine.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import UIKit



let godzilla = "https://cdn.wowscreen.com.tw/uploadfile/202309/goods_030567_395649.jpg"

let swiftImage = "https://developer.apple.com/assets/elements/icons/swift/swift-96x96_2x.png"

let kanahei = "https://flipa-production.s3-ap-southeast-1.amazonaws.com/uploads/beautynew_image/24413/1/_775x400_24413.jpg"

//    static let godzilla = "https://image-cdn.hypb.st/https%3A%2F%2Fhk.hypebeast.com%2Ffiles%2F2024%2F04%2F17%2Fgodzilla-minus-one-amazon-prime-video-japan-release-date-1-1.jpg?fit=max&cbr=1&q=90&w=750&h=500"

let mockString: String = """
當然可以！以下是一些我認為很不錯的Swift學習影片推薦：
\(godzilla) \(swiftImage)
1. CodeWithChris的Swift教學影片系列：https://www.youtube.com/watch?v=pfyNl0rkzHc&list=PLMtAZTFekceAevR31HO5SKtkVEH0Q-FI2
2. Sean Allen的Swift Tutorial影片：https://www.youtube.com/watch?v=qdPgJCM9ZDg&list=RDqdPgJCM9ZDg&start_radio=1
3. Brian Advent的iOS開發教學影片（包含Swift）：https://www.youtube.com/channel/UCjKLauK-fLKmVlYSknbERkw

希望這些影片能幫助你順利學習Swift！祝你學習順利！
"""

let mockString2: String = kanahei

class SystemDefine {
    
    
    static let shared: SystemDefine = .init()
    //var apiToken: String = ""
    
    private init() {
        
    }
    
    
}

typealias LoadingStatus = SystemDefine.LoadingStatus
typealias AIPlatform = SystemDefine.AIPLatform

extension SystemDefine {
    
    //MARK: AI平台
    enum AIPLatform: Codable {
        case openAI
        case geminiAI
    }
    
    //MARK: - 訊息類相關變數
    struct Message {
        /// 預設訊息
        static let defaultMessage = "        \n\n\n\n\n\n\n"
        /// 訊息最小高度
        //static let minimumHeight: CGFloat = 50
        /// 訊息最大寬度
        static let maxWidth: CGFloat = UIScreen.main.bounds.width - 40
        /// 訊息最小寬度
        static let minimumWidth: CGFloat = 150
        /// 字體顏色
        static let textColor: UIColor = .white
        /// 預設字體
        static let defaultTextFont: UIFont = .init(name: "Arial", size: 16)!
        /// 支援的font
        static let fontList = [
                "Arial",
                "Verdana",
                "Times New Roman",
                "Georgia",
                "Courier New"
            ]
        /// ai訊息的背景顏色
        static let aiMgsBackgroundColor = UIColor.fromAppColors(\.coffeeBackground)
        /// 用戶訊息的背景顏色
        static let userMgsBackgroundColor = UIColor.fromAppColors(\.lightCoffeeButton)
    }
    
    
    //MARK: - 讀取狀態
    enum LoadingStatus {
        case none
        case loading(message: String = "")
        case success
        case error(error: Error)
    }
    
}


