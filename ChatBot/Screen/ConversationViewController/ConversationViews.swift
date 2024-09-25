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
    let scenarioView = ScenarioView().apply {
        $0.isVisible = false
    }
    
    override func initUI() {
        view.addSubview(tableView)
        view.addSubview(recordButton)
        view.addSubview(recordingView)
        view.addSubview(scenarioView)
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
        scenarioView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

protocol AudioCellDelegate: AnyObject {
    
    func spekaButtonClicked(indexPath: IndexPath)
    
    func hintButtonClicked(indexPath: IndexPath)
    
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
            $0.lineBreakMode = .byWordWrapping
        }
        let speakButton = UIButton(type: .custom).apply {
            $0.backgroundColor = .fromAppColors(\.darkCoffeeText)
            $0.cornerRadius = 15
            $0.setBackgroundImage(.init(systemName: "speaker.wave.2.circle.fill")?.withTintColor(.fromAppColors(\.lightCoffeeButton), renderingMode: .alwaysOriginal), for: .normal)
        }
        let hintButton = UIButton(type: .custom).apply {
            $0.setTitle("需要提示嗎？", for: .normal)
            $0.setTitleColor(.fromAppColors(\.normalText), for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
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
            contentView.addSubview(hintButton)
            messageLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(10)
                make.width.lessThanOrEqualTo(SystemDefine.Message.maxWidth)
                make.leading.equalToSuperview().inset(10)
            }
            speakButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 30, height: 30))
                make.centerX.equalTo(messageLabel.trailing)
                make.centerY.equalTo(messageLabel.bottom)
            }
            hintButton.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.bottom)
                make.trailing.equalTo(speakButton.leading).offset(-3)
                make.height.equalTo(16)
                make.bottom.equalToSuperview()
            }
            speakButton.addTarget(self, action: #selector(speakButtonClicked), for: .touchUpInside)
            hintButton.addTarget(self, action: #selector(hintButtonClicked), for: .touchUpInside)
        }
        
        func bindAudioResult(audioResult: AudioResult, indexPath: IndexPath) {
            self.indexPath = indexPath
            messageLabel.text = audioResult.text
        }
        
        @objc private func speakButtonClicked() {
            delegate?.spekaButtonClicked(indexPath: indexPath)
        }
        
        @objc private func hintButtonClicked() {
            delegate?.hintButtonClicked(indexPath: indexPath)
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

extension ConversationViews {
    
    class ScenarioView: UIView {
        
        let scenarioLabel = UILabel().apply {
            $0.font = SystemDefine.Message.defaultTextFont
            $0.numberOfLines = 0
        }
        let aiRoleLabel = UILabel().apply {
            $0.font = SystemDefine.Message.defaultTextFont
            $0.numberOfLines = 0
        }
        let userRoleLabel = UILabel().apply {
            $0.font = SystemDefine.Message.defaultTextFont
            $0.numberOfLines = 0
        }
        let closeButton = UIButton(type: .custom).apply {
            $0.setTitle("關閉", for: .normal)
            $0.backgroundColor = .fromAppColors(\.lightCoffeeButton)
            $0.setTitleColor(.fromAppColors(\.darkCoffeeText), for: .normal)
            $0.cornerRadius = 8
        }
        let contentView = UIView().apply {
            $0.backgroundColor = .systemBackground
            $0.cornerRadius = 10
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            backgroundColor = .black.withAlphaComponent(0.4)
            isUserInteractionEnabled = true
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(disapear)))
            addSubview(contentView)
            contentView.addSubview(scenarioLabel)
            contentView.addSubview(aiRoleLabel)
            contentView.addSubview(userRoleLabel)
            contentView.addSubview(closeButton)
            contentView.snp.makeConstraints { make in
                make.width.equalToSuperview().multipliedBy(0.8)
                make.height.greaterThanOrEqualTo(150)
                make.center.equalToSuperview()
            }
            scenarioLabel.snp.makeConstraints { make in
                make.leading.trailing.top.equalToSuperview().inset(20)
            }
            aiRoleLabel.snp.makeConstraints { make in
                make.leading.trailing.equalTo(scenarioLabel)
                make.top.equalTo(scenarioLabel.bottom).offset(10)
            }
            userRoleLabel.snp.makeConstraints { make in
                make.leading.trailing.equalTo(aiRoleLabel)
                make.top.equalTo(aiRoleLabel.bottom).offset(10)
                
            }
            closeButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 100, height: 40))
                make.centerX.equalToSuperview()
                make.top.equalTo(userRoleLabel.bottom).offset(20)
                make.bottom.equalToSuperview().inset(20)
            }
            closeButton.addTarget(self, action: #selector(disapear), for: .touchUpInside)
        }
        
        @objc private func disapear() {
            self.isVisible = true
            self.removeFromSuperview()
        }
        
        func bindScenario(scenario: Scenario) {
            let scenarioString = NSMutableAttributedString(string: "情境：\n" + scenario.scenarioTranslation, attributes: [.foregroundColor : UIColor.fromAppColors(\.darkCoffeeText)]).apply {
                $0.addAttributes([.foregroundColor : UIColor.fromAppColors(\.normalText)], range: .init(location: 0, length: 3))
            }
            let aiRoleString = NSMutableAttributedString(string: "AI扮演：\n" + scenario.aiRoleTranslation, attributes: [.foregroundColor : UIColor.fromAppColors(\.darkCoffeeText)]).apply {
                $0.addAttributes([.foregroundColor : UIColor.fromAppColors(\.normalText)], range: .init(location: 0, length: 5))
            }
            let userRoleString = NSMutableAttributedString(string: "你扮演：\n" + scenario.userRoleTranslation, attributes: [.foregroundColor : UIColor.fromAppColors(\.darkCoffeeText)]).apply {
                $0.addAttributes([.foregroundColor : UIColor.fromAppColors(\.normalText)], range: .init(location: 0, length: 4))
            }
            scenarioLabel.attributedText = scenarioString
            aiRoleLabel.attributedText = aiRoleString
            userRoleLabel.attributedText = userRoleString
        }
        
    }
    
}
