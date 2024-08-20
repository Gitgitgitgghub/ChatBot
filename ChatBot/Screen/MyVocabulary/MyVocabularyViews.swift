//
//  MyVocabularyViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation
import UIKit


class MyVocabularyViews: ControllerView {
    
    var tableView = UITableView(frame: .zero, style: .plain).apply { tableView in
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 50
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
    }
    var addNoteButton = UIButton(type: .custom).apply {
        $0.cornerRadius = 25
        $0.setImage(.init(systemName: "plus"), for: .normal)
        $0.backgroundColor = .white
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

//MARK: - VocabularyCellDelegate
protocol VocabularyCellDelegate: AnyObject {
    
    /// 當播放按鈕點選
    func onSpeakButtonClicked(indexPath: IndexPath)
    /// 當收藏按鈕被點選
    func onStarButtonClicked(indexPath: IndexPath)
    
}

//MARK: - 自定義的view
extension MyVocabularyViews {
    
    class HeaderView: UIView {
        
        private var titleLabel = PaddingLabel(withInsets: .init(top: 0, left: 10, bottom: 0, right: 10)).apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.numberOfLines = 1
            $0.backgroundColor = .lightGray
        }
        private var arrowImageView = UIImageView(image: nil).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(titleLabel)
            addSubview(arrowImageView)
            titleLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            arrowImageView.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 25, height: 25))
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(10)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setSectionData(sectionModel: MyVocabularyViewModel.SectionData) {
            titleLabel.text = sectionModel.title.uppercased() + " 共有\(sectionModel.vocabularies.count)個單字"
            let imageName = sectionModel.isExpanding ? "arrow.up" : "arrow.down"
            arrowImageView.image = .init(systemName: imageName)?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        }
        
    }
    
    class VocabularyCell: UITableViewCell {
        
        var wordLabel = PaddingLabel(withInsets: .init(top: 5, left: 10, bottom: 5, right: 10)).apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.numberOfLines = 1
            $0.font = .boldSystemFont(ofSize: 18)
        }
        var definitionLabel = PaddingLabel(withInsets: .init(top: 0, left: 10, bottom: 5, right: 10)).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.numberOfLines = 0
            $0.textColor = .lightGray
            $0.font = .systemFont(ofSize: 14)
        }
        var speakButton = UIButton(type: .custom).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setImage(.init(systemName: "speaker.wave.2.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .normal)
        }
        var starButton = UIButton(type: .custom).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setImage(.init(systemName: "star")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .normal)
            $0.setImage(.init(systemName: "star.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .selected)
        }
        private(set) var vocabulary: VocabularyModel?
        private(set) var indexPath: IndexPath = .init(row: 0, section: 0)
        weak var delegate: VocabularyCellDelegate?
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            contentView.addSubview(wordLabel)
            contentView.addSubview(definitionLabel)
            contentView.addSubview(speakButton)
            contentView.addSubview(starButton)
            wordLabel.snp.makeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
            }
            definitionLabel.snp.makeConstraints { make in
                make.top.equalTo(wordLabel.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            speakButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 25, height: 25))
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(10)
            }
            starButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 25, height: 25))
                make.centerY.equalToSuperview()
                make.trailing.equalTo(speakButton.snp.leading).offset(-5)
            }
            speakButton.addTarget(self, action: #selector(speakButtonClicked), for: .touchUpInside)
            starButton.addTarget(self, action: #selector(starButtonClicked), for: .touchUpInside)
        }
        
        @objc private func speakButtonClicked() {
            delegate?.onSpeakButtonClicked(indexPath: indexPath)
        }
        
        @objc private func starButtonClicked() {
            delegate?.onStarButtonClicked(indexPath: indexPath)
        }
        
        func bindVocabulary(indexPath: IndexPath, vocabulary: VocabularyModel) {
            self.indexPath = indexPath
            self.vocabulary = vocabulary
            wordLabel.text = vocabulary.wordEntry.word
            setDefinitions()
            setStar()
        }
        
        private func setDefinitions() {
            guard let wordEntry = self.vocabulary?.wordEntry else { 
                definitionLabel.text = nil
                return
            }
            definitionLabel.text = wordEntry.displayDefinitionString
        }
        
        private func setStar() {
            guard let vocabulary = self.vocabulary else { return }
            starButton.isSelected = vocabulary.isStar
        }
        
    }
}
