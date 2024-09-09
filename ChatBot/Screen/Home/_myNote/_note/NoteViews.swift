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
        var image: UIImage? = .init(systemName: "note.text.badge.plus")?.withTintColor(.fromAppColors(\.darkCoffeeText), renderingMode: .alwaysOriginal).resizeToFit(maxWidth: 25, maxHeight: 25)
        $0.setImage(image, for: .normal)
        $0.cornerRadius = 25
        $0.backgroundColor = .fromAppColors(\.lightCoffeeButton)
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

protocol NoteCellDelegate: AnyObject {
    
    func layoutDidChanged()
    
}

extension NoteViews {
    
    class NoteCell: UITableViewCell, UITextViewDelegate, NSLayoutManagerDelegate {
        
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
        weak var noteCellDelegate: NoteCellDelegate?
        
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
            noteTextView.layoutManager.delegate = self
            noteTextView.backgroundColor = SystemDefine.Message.aiMgsBackgroundColor
            contentView.addSubview(noteTextView)
            noteTextView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.leading.trailing.equalToSuperview().inset(10)
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
        
        // 監聽字形範圍的佈局計算
        func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
            noteCellDelegate?.layoutDidChanged()
            
        }
    }
    
    class CommentCell: UITableViewCell, UITextViewDelegate, NSLayoutManagerDelegate {
        
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
        weak var noteCellDelegate: NoteCellDelegate?
        
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
            noteTextView.layoutManager.delegate = self
            noteTextView.backgroundColor =  SystemDefine.Message.userMgsBackgroundColor
            contentView.addSubview(noteTextView)
            noteTextView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.leading.trailing.equalToSuperview().inset(10)
                make.centerX.equalToSuperview()
            }
        }
        
        func bindComment(comment: MyComment) {
            noteTextView.attributedText = comment.attributedString()
        }
        
        // 監聽字形範圍的佈局計算
        func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
            noteCellDelegate?.layoutDidChanged()
            
        }
        
        //MARK: - UITextViewDelegate
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false // 返回 false，表示讓系統處理超連結的點擊事件
        }
    }
    
}
