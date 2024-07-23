//
//  NoteViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/22.
//

import Foundation
import UIKit


class NoteViews: ControllerView {
    
    
    var tableView = UITableView(frame: .zero, style: .plain).apply { tableView in
        tableView.estimatedRowHeight = 50
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
    }
    let addCommentButton = UIButton(type: .custom).apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setBackgroundImage(.init(systemName: "note.text.badge.plus"), for: .normal)
    }
    
    override func initUI() {
        view.addSubview(tableView)
        view.addSubview(addCommentButton)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addCommentButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 50, height: 50))
            make.bottom.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
        }
    }
    
}

extension NoteViews {
    
    class NoteCell: UITableViewCell, UITextViewDelegate {
        
        let noteTextView = UITextView().apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.dataDetectorTypes = .link
            $0.isScrollEnabled = false
            $0.backgroundColor = .clear
            $0.isFindInteractionEnabled = true
            $0.isUserInteractionEnabled = false
            $0.isEditable = false
            $0.cornerRadius = 10
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
            noteTextView.delegate = self
            noteTextView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
            contentView.addSubview(noteTextView)
            noteTextView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.width.equalTo(SystemDefine.Message.maxWidth)
                make.centerX.equalToSuperview()
            }
        }
        
        func bindNote(note: MyNote) {
            noteTextView.attributedText = note.attributedString()
        }
        
        //MARK: - UITextViewDelegate
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false // 返回 false，表示讓系統處理超連結的點擊事件
        }
    }
    
    class CommentCell: UITableViewCell, UITextViewDelegate {
        
        let noteTextView = UITextView().apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.dataDetectorTypes = .link
            $0.isScrollEnabled = false
            $0.backgroundColor = .clear
            $0.isFindInteractionEnabled = true
            $0.isUserInteractionEnabled = false
            $0.isEditable = false
            $0.cornerRadius = 10
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
            noteTextView.delegate = self
            noteTextView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
            contentView.addSubview(noteTextView)
            noteTextView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.width.equalTo(SystemDefine.Message.maxWidth)
                make.centerX.equalToSuperview()
            }
        }
        
        func bindComment(comment: MyComment) {
            noteTextView.attributedText = comment.attributedString()
        }
        
        //MARK: - UITextViewDelegate
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false // 返回 false，表示讓系統處理超連結的點擊事件
        }
    }
    
}
