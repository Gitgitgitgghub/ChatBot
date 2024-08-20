//
//  SettingViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/11.
//

import Foundation
import UIKit


class SettingViews: ControllerView {
    
    var tableView = UITableView(frame: .zero, style: .grouped).apply { tableView in
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func initUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}
