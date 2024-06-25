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
        tableView.allowsSelection = false
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

protocol MessageCellProtocol: AnyObject {
    
    func cellHeighChange()
    
}

extension ChatViews {
    
    
    //MARK: - 用戶文字訊息Cell
    class UserMessageCell: UITableViewCell, WebImageDownloadDelegate {
        
        
        weak var messageCellProtocol: MessageCellProtocol?
        let messageView = MessageTextView().apply { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            view.cornerRadius = 10
        }
        var result: OpenAIResult?
        private(set) var labelBackgroundColor = UIColor.green.withAlphaComponent(0.8)
        private let parser = AttributedStringParser()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            initUI()
        }
        
        func initUI() {
            contentView.addSubview(messageView)
            messageView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.height.greaterThanOrEqualTo(30)
                make.width.lessThanOrEqualToSuperview().inset(30)
                make.trailing.equalToSuperview().inset(10)
            }
        }
        
        func bindResult(result: OpenAIResult) {
            self.result = result
            parser.webImageDownloadDelegate = self
            setupUI()
        }
        
        func setupUI() {
            guard let result = result else { return }
            switch result {
            case .userChatQuery(_):
                messageView.backgroundColor = labelBackgroundColor
                parser.parseToAttributedString(string: result.message, completion: { [weak self] attr in
                    DispatchQueue.main.async {
                        self?.messageView.messageTextView.attributedText = attr
                    }
                })
            case .chatResult(data: _):
                parser.parseToAttributedString(string: result.message, completion: { [weak self] attr in
                    DispatchQueue.main.async {
                        self?.messageView.messageTextView.attributedText = attr
                    }
                })
            default: break
            }
        }
        
        func imageDownloadComplete() {
            messageView.messageTextView.updateHeight()
            messageCellProtocol?.cellHeighChange()
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
            super.setupUI()
            messageView.backgroundColor = labelBackgroundColor
        }
    }
    
    class MessageTextView: UIView, UITextViewDelegate {
        
        let messageTextView = UITextView().apply { textView in
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.textColor = .white
            textView.textAlignment = .left
            textView.dataDetectorTypes = .link
            textView.cornerRadius = 10
            textView.isScrollEnabled = false
            textView.backgroundColor = .clear
            textView.isFindInteractionEnabled = true
            textView.isUserInteractionEnabled = true
            textView.isEditable = false
        }
        
        var attributedText: NSAttributedString {
            set {
                messageTextView.attributedText = newValue
            }
            get {
                return messageTextView.attributedText
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(messageTextView)
            messageTextView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(10)
            }
            messageTextView.delegate = self
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false // 返回 false，表示讓系統處理超連結的點擊事件
        }
        
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            switch textItem.content {
            case .link(let uRL):
                return .init { _ in
                    UIApplication.shared.open(uRL)
                }
            case .textAttachment(_):
                break
            case .tag(_):
                break
            @unknown default:
                break
            }
            return nil
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
