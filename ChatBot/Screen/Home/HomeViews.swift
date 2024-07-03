//
//  HomeViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/3.
//

import Foundation
import UIKit


class HomeViews: ControllerView {
    
    var chatButton = UIButton(type: .custom).apply { button in
        button.setTitle("聊天", for: .normal)
        button.backgroundColor = .blue
    }

    
    override func initUI() {
        view.addSubview(chatButton)
        chatButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 100, height: 50))
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(50)
        }
    }
    
}
