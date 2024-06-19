//
//  ChatInputView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/18.
//

import UIKit

class ChatInputView: UIView {
    
    lazy var messageInputTextField: UITextView = {
        let view = UITextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.keyboardType = .default
        view.returnKeyType = .default
        view.textAlignment = .left
        view.font = .systemFont(ofSize: 15)
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    lazy var sendButton: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setBackgroundImage(.init(systemName: "paperplane.circle.fill"), for: .normal)
        return view
    }()
    lazy var functionButton: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setBackgroundImage(.init(systemName: "plus.square"), for: .normal)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        addSubview(messageInputTextField)
        addSubview(sendButton)
        addSubview(functionButton)
        functionButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        sendButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.trailing.equalToSuperview().inset(3)
            make.centerY.equalToSuperview()
        }
        messageInputTextField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5)
            make.leading.equalTo(functionButton.snp.trailing).offset(3)
            make.trailing.equalTo(sendButton.snp.leading).offset(-3)
        }
    }

}
