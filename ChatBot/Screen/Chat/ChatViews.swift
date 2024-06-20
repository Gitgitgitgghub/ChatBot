//
//  .swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import UIKit
import Kingfisher

class ChatViews: ControllerView {
    
    lazy var messageTableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 30
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()
    let chatInputView = ChatInputView().apply { view in
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func initUI() {
        view.backgroundColor = .white
        view.addSubview(messageTableView)
        view.addSubview(chatInputView)
        chatInputView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.height.equalTo(50)
        }
        messageTableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(chatInputView.snp.top)
        }
    }
    
    func textFieldDidBeginEditing(keyboardHeight: CGFloat) {
        chatInputView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(keyboardHeight - 10)
        }
    }
    
    func textFieldDidEndEditing() {
        chatInputView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
        }
    }
}

protocol MessageCellProtocol where Self: UITableViewCell {
    
    var result: OpenAIResult? { get set }
    
    func initUI()
    
    func bindResult(result: OpenAIResult)
    
}

extension ChatViews {
    
    //MARK: - 用戶圖片訊息Cell
    class UserImageCell: UITableViewCell, MessageCellProtocol {
        
        var labelBackgroundColor: UIColor = .green.withAlphaComponent(0.8)
        var result: OpenAIResult?
        
        let imageResultView = ImageResultView().apply { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            view.cornerRadius = 10
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            initUI()
        }
        
        func initUI() {
            addSubview(imageResultView)
            imageResultView.snp.remakeConstraints { make in
                make.top.trailing.bottom.equalToSuperview().inset(10)
                make.height.greaterThanOrEqualTo(296)
                make.width.lessThanOrEqualToSuperview().inset(30)
            }
        }
        
        func bindResult(result: OpenAIResult) {
            self.result = result
            setupUI()
        }
        
        func setupUI() {
            guard let result = result else { return }
//            switch result {
//            case .userChatQuery(let message):
//                <#code#>
//            case .chatResult(let data):
//                <#code#>
//            case .imageResult(let prompt, let data):
//                <#code#>
//            }
        }
    }
    
    //MARK: - 系統圖片訊息Cell
    class SystemImageCell: UserImageCell {
        
        override func initUI() {
            super.initUI()
            imageResultView.snp.remakeConstraints { make in
                make.top.leading.bottom.equalToSuperview().inset(10)
                make.height.greaterThanOrEqualTo(296)
                make.width.lessThanOrEqualToSuperview().inset(30)
            }
        }
        
        override func setupUI() {
            guard let result = result else { return }
            switch result {
            case .imageResult(let prompt, let data):
                imageResultView.promptLabel.backgroundColor = labelBackgroundColor
                imageResultView.promptLabel.text = "prompt: \(prompt)"
                imageResultView.contentImageView.loadImage(url: data.data.first?.url, indicatorType: .activity)
            default: break
            }
        }
    }
    
    //MARK: - 用戶文字訊息Cell
    class UserMessageCell: UITableViewCell, MessageCellProtocol {
        
        let messageView = MessageResultView().apply { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            view.cornerRadius = 10
        }
        var result: OpenAIResult?
        private(set) var labelBackgroundColor = UIColor.green.withAlphaComponent(0.8)
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            initUI()
        }
        
        func initUI() {
            addSubview(messageView)
            messageView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.height.greaterThanOrEqualTo(30)
                make.width.lessThanOrEqualToSuperview().inset(30)
                make.trailing.equalToSuperview().inset(10)
            }
        }
        
        func bindResult(result: OpenAIResult) {
            self.result = result
            setupUI()
        }
        
        func setupUI() {
            guard let result = result else { return }
            switch result {
            case .userChatQuery(let message):
                messageView.backgroundColor = labelBackgroundColor
                messageView.messageLabel.text = message
            default: break
            }
        }
    }
    
    //MARK: - 系統文字訊息Cell
    class SystemMessageCell: UserMessageCell {
        
        override var labelBackgroundColor: UIColor {
            return UIColor.blue.withAlphaComponent(0.8)
        }
        
        override func initUI() {
            super.initUI()
            messageView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.height.greaterThanOrEqualTo(30)
                make.width.lessThanOrEqualToSuperview().inset(30)
                make.leading.equalToSuperview().inset(10)
            }
        }
        
        override func setupUI() {
            guard let result = result else { return }
            switch result {
            case .chatResult:
                messageView.backgroundColor = labelBackgroundColor
                messageView.messageLabel.text = result.message
            default: break
            }
        }
    }
    
    class MessageResultView: UIView {
        
        let messageLabel = PaddingLabel(withInsets: .init(top: 10, left: 20, bottom: 10, right: 20)).apply { label in
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .white
            label.textAlignment = .left
            label.numberOfLines = 0
            label.cornerRadius = 10
        }
        override var backgroundColor: UIColor? {
            didSet {
                messageLabel.backgroundColor = backgroundColor
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(messageLabel)
            messageLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    class ImageResultView: UIView {
        let promptLabel = PaddingLabel(withInsets: .init(top: 10, left: 20, bottom: 10, right: 20)).apply { label in
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .white
            label.textAlignment = .left
            label.numberOfLines = 0
            label.cornerRadius = 10
        }
        let contentImageView: UIImageView = UIImageView().apply { imageView in
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.cornerRadius = 10
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func commonInit() {
            addSubview(promptLabel)
            addSubview(contentImageView)
            promptLabel.snp.makeConstraints { make in
                make.top.leading.equalToSuperview()
                make.height.greaterThanOrEqualTo(30)
                make.width.lessThanOrEqualToSuperview().inset(30)
            }
            contentImageView.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 256, height: 256))
                make.top.equalTo(promptLabel.snp.bottom).offset(5)
                make.leading.equalToSuperview()
            }
        }
        
    }
}
