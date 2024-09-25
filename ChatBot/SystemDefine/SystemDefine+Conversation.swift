//
//  SystemDefine+Conversation.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/25.
//

import Foundation


extension SystemDefine {
    
    struct Conversation {
        
        static let scenarios: [Scenario] = [
            Scenario(
                scenario: "Ordering at a coffee shop",
                description: "You walk into a coffee shop and want to order a coffee and some snacks.",
                aiRole: "Cafe staff",
                userRole: "Customer",
                scenarioTranslation: "在咖啡店點餐",
                descriptionTranslation: "你走進一家咖啡館，想點一杯咖啡和一些小吃。",
                aiRoleTranslation: "咖啡館的店員",
                userRoleTranslation: "顧客"
            ),
            Scenario(
                scenario: "Confirming gate and time at the airport",
                description: "You are at the airport ready to board and need to confirm the gate and time.",
                aiRole: "Airport boarding staff",
                userRole: "Passenger",
                scenarioTranslation: "在機場確認登機口與時間",
                descriptionTranslation: "你在機場準備登機，但需要確認登機口和時間。",
                aiRoleTranslation: "機場登機服務人員",
                userRoleTranslation: "旅客"
            ),
            Scenario(
                scenario: "Checking in at a hotel",
                description: "You arrive at a hotel to check in.",
                aiRole: "Hotel receptionist",
                userRole: "Guest",
                scenarioTranslation: "在酒店辦理入住",
                descriptionTranslation: "你抵達一家酒店準備辦理入住手續。",
                aiRoleTranslation: "酒店櫃台接待員",
                userRoleTranslation: "客人"
            ),
            Scenario(
                scenario: "Attending a job interview",
                description: "You are attending a job interview in English, and the interviewer asks about your background and experience.",
                aiRole: "Interviewer",
                userRole: "Job applicant",
                scenarioTranslation: "參加工作面試",
                descriptionTranslation: "你參加一場英文的工作面試，面試官會詢問你的背景和工作經驗。",
                aiRoleTranslation: "面試官",
                userRoleTranslation: "求職者"
            ),
            Scenario(
                scenario: "Asking for travel recommendations at a tourist center",
                description: "You are at a tourist information center in a foreign city, asking for local sightseeing recommendations.",
                aiRole: "Tourist information agent",
                userRole: "Tourist",
                scenarioTranslation: "在旅遊中心詢問旅遊建議",
                descriptionTranslation: "你在一個外國城市的旅遊資訊中心詢問當地的觀光建議。",
                aiRoleTranslation: "旅遊資訊員",
                userRoleTranslation: "遊客"
            )
        ]

        
    }
    
}
