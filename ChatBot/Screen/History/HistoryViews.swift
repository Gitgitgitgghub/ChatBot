//
//  HistoryViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/8.
//

import Foundation
import UIKit


class HistoryViews : ControllerView {
    
    var tableView = UITableView(frame: .zero, style: .plain).apply { tableView in
        tableView.estimatedRowHeight = 50
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
    }
    var editButton = UIButton(type: .custom).apply { button in
        button.setBackgroundImage(.init(systemName: "square.and.pencil"), for: .normal)
    }
    
    override func initUI() {
        view.addSubview(tableView)
        view.addSubview(editButton)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        editButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 30, height: 30))
            make.trailing.bottom.equalToSuperview().inset(15)
        }
    }
}

//MARK: - 聊天室Ｃell
extension HistoryViews {
    
    class ChatRoomCell: UITableViewCell {
        
        private var roleLabel = UILabel().apply { label in
            label.numberOfLines = 1
        }
        private var messageLabel = UILabel().apply { label in
            label.numberOfLines = 3
            label.textColor = .darkGray.withAlphaComponent(0.8)
        }
        private var lastUpdateLabel = UILabel().apply { label in
            label.numberOfLines = 1
            label.textColor = .red.withAlphaComponent(0.8)
        }
        private(set) var chatRoom: MyChatRoom?
        private let dateFormatter = DateFormatter().apply { formatter in
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            initUI()
        }
        
        private func initUI() {
            contentView.addSubview(roleLabel)
            contentView.addSubview(messageLabel)
            contentView.addSubview(lastUpdateLabel)
            roleLabel.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().inset(10)
            }
            lastUpdateLabel.snp.makeConstraints { make in
                make.bottom.trailing.equalToSuperview().inset(10)
            }
            messageLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(10)
                make.top.equalTo(roleLabel.snp.bottom).offset(3)
                make.bottom.equalTo(lastUpdateLabel.snp.top).offset(3)
            }
        }
        
        func bindChatRoom(chatRoom: MyChatRoom) {
            self.chatRoom = chatRoom
            setupUI()
        }
        
        private func setupUI() {
            guard let chatRoom = chatRoom else { return }
            guard let lastMessage = chatRoom.sortedMessages.last else { return }
            switch lastMessage.role {
            case .system, .tool:
                roleLabel.text = "系統："
                roleLabel.textColor = .gray.withAlphaComponent(0.8)
            case .user:
                roleLabel.text = "你："
                roleLabel.textColor = .green.withAlphaComponent(0.8)
            case .assistant:
                roleLabel.text = "ＡＩ："
                roleLabel.textColor = .blue.withAlphaComponent(0.8)
            }
            messageLabel.text = lastMessage.message
            if let lastUpdate = chatRoom.lastUpdate {
                lastUpdateLabel.text = dateFormatter.string(from: lastUpdate)
            }
        }
        
    }
    
}
