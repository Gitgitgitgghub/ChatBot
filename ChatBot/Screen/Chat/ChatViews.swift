//
//  .swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import UIKit
import Kingfisher
import Combine
import SnapKit

class ChatViews: ControllerView {
    
    lazy var messageTableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 100
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
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
    
    func cellHeighChange(indexPath: IndexPath)
    
}

extension ChatViews {
    
    
    //MARK: - ＡＩ文字訊息Cell
    class AIMessageCell: UITableViewCell, UITextViewDelegate {
        
        weak var messageCellProtocol: MessageCellProtocol?
        let messageTextView = UITextView().apply { textView in
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.textColor = .white
            textView.textAlignment = .center
            textView.dataDetectorTypes = .link
            textView.isScrollEnabled = false
            textView.backgroundColor = .clear
            textView.isFindInteractionEnabled = true
            textView.isUserInteractionEnabled = true
            textView.isEditable = false
            textView.cornerRadius = 10
        }
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light)).apply { view in
                view.translatesAutoresizingMaskIntoConstraints = false
                view.cornerRadius = 10
            }
        var messageModel: MessageModel?
        var indexPath: IndexPath?
        var defaultAttr: NSAttributedString {
            return getDefaultAttr()
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
            messageTextView.delegate = self
            messageTextView.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
            messageTextView.attributedText = defaultAttr
            contentView.addSubview(messageTextView)
            contentView.addSubview(blurView)
            messageTextView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.width.lessThanOrEqualTo(SystemDefine.Message.maxWidth)
                make.leading.equalToSuperview().inset(10)
            }
            blurView.snp.makeConstraints { make in
                make.edges.equalTo(messageTextView)
            }
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            messageTextView.cancelDownloadTask()
            messageTextView.attributedText = defaultAttr
            messageTextView.updateHeight()
        }
        
        func bindMessage(messageModel: MessageModel, indexPath: IndexPath) {
            self.messageModel = messageModel
            self.indexPath = indexPath
            blurView.isVisible = false
            setupUI()
        }
        
        func setLoading(indexPath: IndexPath) {
            self.indexPath = indexPath
            blurView.isVisible = false
            messageTextView.attributedText = defaultAttr
        }
        
        func setupUI() {
            guard let messageModel = self.messageModel else { return }
            guard let indexPath = self.indexPath else { return }
            switch messageModel.messageType {
            case .message:
                messageTextView.attributedText = messageModel.attributedString ?? defaultAttr
            case .mock:
                messageTextView.attributedText = messageModel.attributedString ?? defaultAttr
            }
            messageTextView.asyncLoadWebAttachmentImage()
            //blurView.isVisible = messageTextView.attributedText == defaultAttr
        }
        
        private func getDefaultAttr() -> NSAttributedString {
            let defaultString: String = String(self.indexPath?.row ?? -1) + SystemDefine.Message.defaultMessage
            return .init(string: defaultString)
        }
        
        //MARK: - UITextViewDelegate
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false // 返回 false，表示讓系統處理超連結的點擊事件
        }
    }
    
    
    //MARK: - 用戶文字訊息Cell
    class UserMessageCell: AIMessageCell {
        
        override func initUI() {
            super.initUI()
            messageTextView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.width.lessThanOrEqualTo(SystemDefine.Message.maxWidth)
                make.trailing.equalToSuperview().inset(10)
            }
            messageTextView.backgroundColor = .green.withAlphaComponent(0.8)
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
