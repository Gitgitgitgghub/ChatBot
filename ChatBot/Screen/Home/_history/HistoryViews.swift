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
        var image: UIImage? = .init(systemName: "square.and.pencil")?.withTintColor(.fromAppColors(\.darkCoffeeText), renderingMode: .alwaysOriginal).resizeToFit(maxWidth: 25, maxHeight: 25)
        button.setImage(image, for: .normal)
        button.cornerRadius = 25
        button.backgroundColor = .fromAppColors(\.lightCoffeeButton)
    }
    
    override func initUI() {
        view.addSubview(tableView)
        view.addSubview(editButton)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        editButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 50, height: 50))
            make.trailing.bottom.equalToSuperview().inset(15)
        }
    }
}

//MARK: - 聊天室Ｃell
extension HistoryViews {
    
    class ChatRoomCell: UITableViewCell {
        
        private var roleLabel = UILabel().apply { label in
            label.numberOfLines = 1
            label.textColor = .fromAppColors(\.darkCoffeeText)
        }
        private var messageLabel = UILabel().apply { label in
            label.numberOfLines = 3
            label.textColor = .fromAppColors(\.normalText)
        }
        private var lastUpdateLabel = UILabel().apply { label in
            label.numberOfLines = 1
            label.textColor = .fromAppColors(\.secondaryText)
            label.font = .boldSystemFont(ofSize: 14)
        }
        private(set) var chatRoom: ChatRoom?
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
            backgroundColor = .fromAppColors(\.secondaryButtonBackground)
            contentView.addSubview(roleLabel)
            contentView.addSubview(messageLabel)
            contentView.addSubview(lastUpdateLabel)
            roleLabel.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().inset(10)
            }
            messageLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(10)
                make.top.equalTo(roleLabel.snp.bottom).offset(3)
                make.height.greaterThanOrEqualTo(20)
            }
            lastUpdateLabel.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.snp.bottom).offset(5)
                make.bottom.trailing.equalToSuperview().inset(10)
            }
        }
        
        func bindChatRoom(chatRoom: ChatRoom) {
            self.chatRoom = chatRoom
            setupUI()
        }
        
        private func setupUI() {
            do {
                guard let chatRoom = chatRoom else { return }
                lastUpdateLabel.text = dateFormatter.string(from: chatRoom.lastUpdate)
                try DatabaseManager.shared.dbQueue.read { db in
                    guard let lastMessage = try chatRoom.messages.fetchAll(db).last else { return }
                    switch lastMessage.role {
                    case .system, .tool:
                        roleLabel.text = "系統："
                    case .user:
                        roleLabel.text = "你："
                    case .assistant:
                        roleLabel.text = "AI："
                    }
                    messageLabel.text = lastMessage.message
                }
            }catch {
                
            }
            
        }
        
    }
    
}
