//
//  ConversationViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/18.
//

import Foundation
import UIKit

class ConversationViews: ControllerView {
    
    let recordingView = RecordingView().apply {
        $0.isVisible = false
    }
    let recordButton = UIButton(type: .custom).apply {
        $0.cornerRadius = 30
        $0.setImage(.init(systemName: "mic.fill")?.withTintColor(.fromAppColors(\.darkCoffeeText), renderingMode: .alwaysOriginal), for: .normal)
        $0.backgroundColor = .fromAppColors(\.lightCoffeeButton)
    }
    let tableView = UITableView(frame: .zero, style: .plain).apply {
        $0.separatorStyle = .none
    }
    
    override func initUI() {
        view.addSubview(tableView)
        view.addSubview(recordButton)
        view.addSubview(recordingView)
        recordingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        recordButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 60, height: 60))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(30)
        }
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

protocol AudioCellDelegate: AnyObject {
    
    func spekaButtonClicked(indexPath: IndexPath)
    
}

//MARK: Cell
extension ConversationViews {
    
    class SystemCell: UITableViewCell {
        
        let messageLabel = PaddingLabel(withInsets: .init(top: 10, left: 10, bottom: 10, right: 10)).apply {
            $0.font = SystemDefine.Message.defaultTextFont
            $0.textColor = .white
            $0.numberOfLines = 0
            $0.cornerRadius = 10
            $0.backgroundColor = SystemDefine.Message.aiMgsBackgroundColor
        }
        let speakButton = UIButton(type: .custom).apply {
            $0.backgroundColor = .fromAppColors(\.darkCoffeeText)
            $0.cornerRadius = 15
            $0.setBackgroundImage(.init(systemName: "speaker.wave.2.circle.fill")?.withTintColor(.fromAppColors(\.lightCoffeeButton), renderingMode: .alwaysOriginal), for: .normal)
        }
        var indexPath: IndexPath = .init(row: 0, section: 0)
        weak var delegate: AudioCellDelegate?
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func initUI() {
            contentView.addSubview(messageLabel)
            contentView.addSubview(speakButton)
            messageLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.width.lessThanOrEqualTo(SystemDefine.Message.maxWidth)
                make.leading.equalToSuperview().inset(10)
            }
            speakButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 30, height: 30))
                make.centerX.equalTo(messageLabel.trailing)
                make.centerY.equalTo(messageLabel.bottom)
            }
            speakButton.addTarget(self, action: #selector(speakButtonClicked), for: .touchUpInside)
        }
        
        func bindAudioResult(audioResult: AudioResult, indexPath: IndexPath) {
            self.indexPath = indexPath
            messageLabel.text = audioResult.text
        }
        
        @objc private func speakButtonClicked() {
            delegate?.spekaButtonClicked(indexPath: indexPath)
        }
        
    }
    
    class UserCell: SystemCell {
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func initUI() {
            super.initUI()
            messageLabel.backgroundColor = SystemDefine.Message.userMgsBackgroundColor
            messageLabel.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.width.lessThanOrEqualTo(SystemDefine.Message.maxWidth)
                make.trailing.equalToSuperview().inset(10)
            }
            speakButton.snp.remakeConstraints { make in
                make.size.equalTo(CGSize(width: 30, height: 30))
                make.centerX.equalTo(messageLabel.leading)
                make.centerY.equalTo(messageLabel.bottom)
            }
        }
        
    }
    
}
