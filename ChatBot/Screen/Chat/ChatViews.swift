//
//  .swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import UIKit

class ChatViews: ControllerView {

    
    lazy var messageTableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 30
        return tableView
    }()
    
    lazy var messageInputTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "input some messages"
        textField.keyboardType = .default
        textField.returnKeyType = .send
        textField.borderStyle = .roundedRect
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }()
    
    lazy var requestCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .red
        label.textColor = .white
        label.textAlignment = .center
        label.text = "request count: 0"
        return label
    }()
    
    override func initUI() {
        view.backgroundColor = .white
        view.addSubview(messageTableView)
        view.addSubview(messageInputTextField)
        view.addSubview(requestCountLabel)
        messageInputTextField.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.height.equalTo(50)
        }
        messageTableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(requestCountLabel.snp.bottom)
            make.bottom.equalTo(messageInputTextField.snp.top)
        }
        requestCountLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
    }
}

extension ChatViews {
    
    class MessageCell: UITableViewCell {
        
        private lazy var messageLabel: PaddingLabel = {
            let label = PaddingLabel(withInsets: .init(top: 10, left: 20, bottom: 10, right: 20))
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .white
            label.textAlignment = .left
            label.numberOfLines = 0
            label.layer.cornerRadius = 10
            label.layer.masksToBounds = true
            return label
        }()
        private(set) var message: MessageModel?
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            initUI()
        }
        
        private func initUI() {
            contentView.addSubview(messageLabel)
        }
        
        func bindMessage(message: MessageModel) {
            self.message = message
            setupUI()
            messageLabel.text = message.message
        }
        
        private func setupUI() {
            guard let message = message else { return }
            messageLabel.backgroundColor = message.isUser ? .green.withAlphaComponent(0.8) : .blue.withAlphaComponent(0.8)
            messageLabel.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.height.greaterThanOrEqualTo(30)
                make.width.lessThanOrEqualToSuperview().inset(30)
                if message.isUser {
                    make.trailing.equalToSuperview().inset(10)
                }else {
                    make.leading.equalToSuperview().inset(10)
                }
            }
        }
    }
    
}
