//
//  MyNoteViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/18.
//

import Foundation
import UIKit


class MyNoteViews: ControllerView {
    
    
    var tableView = UITableView(frame: .zero, style: .plain).apply { tableView in
        tableView.estimatedRowHeight = 50
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
    }
    var addNoteButton = UIButton(type: .custom).apply {
        $0.cornerRadius = 25
        $0.setImage(.init(systemName: "plus"), for: .normal)
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.layer.borderWidth = 1
    }
    
    override func initUI() {
        view.addSubview(tableView)
        view.addSubview(addNoteButton)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addNoteButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 50, height: 50))
            make.trailing.bottom.equalToSuperview().inset(15)
        }
    }
    
}

//MARK: - 筆記cell
extension MyNoteViews {
    
    class NoteCell: UITableViewCell {
        
        private var titleLabel = UILabel().apply { label in
            label.numberOfLines = 1
            label.textColor = .darkGray
        }
        private var messageLabel = PaddingLabel(withInsets: .init(top: 10, left: 8, bottom: 10, right: 8)).apply { label in
            label.numberOfLines = 3
            label.textColor = .darkGray.withAlphaComponent(0.8)
            label.cornerRadius = 10
            label.backgroundColor = .systemBlue
        }
        private var lastUpdateLabel = UILabel().apply { label in
            label.numberOfLines = 1
            label.textColor = .red.withAlphaComponent(0.8)
        }
        lazy var commentImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = .init(systemName: "rectangle.and.pencil.and.ellipsis")
            return imageView
        }()
        lazy var commentCountLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = ": 0"
            label.textColor = .systemGray
            label.numberOfLines = 1
            return label
        }()
        private(set) var myNote: MyNote?
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
            contentView.addSubview(titleLabel)
            contentView.addSubview(messageLabel)
            contentView.addSubview(lastUpdateLabel)
            contentView.addSubview(commentCountLabel)
            contentView.addSubview(commentImageView)
            titleLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(10)
                make.height.equalTo(20)
            }
            messageLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(10)
                make.top.equalTo(titleLabel.snp.bottom).offset(3)
                make.height.greaterThanOrEqualTo(20)
                make.height.lessThanOrEqualTo(100)
            }
            lastUpdateLabel.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.snp.bottom).offset(5)
                make.bottom.trailing.equalToSuperview().inset(10)
                make.height.equalTo(20)
            }
            commentCountLabel.snp.makeConstraints { make in
                make.trailing.equalTo(lastUpdateLabel.snp.leading).offset(-5)
                make.height.equalTo(20)
                make.bottom.equalTo(lastUpdateLabel)
            }
            commentImageView.snp.makeConstraints { make in
                make.trailing.equalTo(commentCountLabel.snp.leading).offset(-2)
                make.size.equalTo(CGSize(width: 20, height: 20))
                make.bottom.equalTo(commentCountLabel)
            }
        }
        
        func bindNote(note: MyNote) {
            self.myNote = note
            setupUI()
        }
        
        private func setupUI() {
            guard let myNote = self.myNote else { return }
            titleLabel.text = myNote.title
            lastUpdateLabel.text = dateFormatter.string(from: myNote.lastUpdate)
            messageLabel.attributedText = myNote.attributedString()
            commentCountLabel.text = ": \(myNote.comments.count)"
        }
    }
}
