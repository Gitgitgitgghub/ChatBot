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
        tableView.sectionHeaderTopPadding = 0
    }
    var addNoteButton = UIButton(type: .custom).apply {
        $0.cornerRadius = 25
        $0.setImage(.init(systemName: "plus"), for: .normal)
        $0.backgroundColor = .white
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.layer.borderWidth = 1
    }
    let bottomToolBar = BottomToolBar().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    let searchBar = UISearchBar().apply {
        $0.placeholder = "搜尋單字"
        $0.keyboardType = .asciiCapable
    }
    let emptyLabel = UILabel().apply {
        let attr = NSMutableAttributedString(string: "沒有該單字\n請AI幫你查查", attributes: [.foregroundColor : UIColor.systemBrown])
        attr.addAttribute(.foregroundColor, value: UIColor.systemGray, range: .init(location: 0, length: 5))
        $0.numberOfLines = 2
        $0.attributedText = attr
        $0.isVisible = false
        $0.isUserInteractionEnabled = true
        $0.textAlignment = .center
    }
    let loadingView = LoadingView(frame: .init(origin: .zero, size: .init(width: 80, height: 80)), type: .ballScaleMultiple, color: .white, padding: 0)
    
    override func initUI() {
        view.addSubview(tableView)
        view.addSubview(addNoteButton)
        view.addSubview(bottomToolBar)
        view.addSubview(searchBar)
        view.addSubview(emptyLabel)
        view.addSubview(loadingView)
        searchBar.sizeToFit()
        searchBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            //make.height.equalTo(44)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomToolBar.top)
        }
        addNoteButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 50, height: 50))
            make.trailing.bottom.equalToSuperview().inset(15)
        }
        bottomToolBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(80)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
        loadingView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 150, height: 150))
            make.center.equalToSuperview()
        }
    }
    
    func showLoading(status: LoadingStatus) {
        switch status {
        case .loading(message: _):
            loadingView.show(withMessage: "正在搜索中...")
            view.bringSubviewToFront(loadingView)
        default:
            loadingView.hide()
        }
    }
    
}

//MARK: - VocabularyCellDelegate
protocol MyVocabularyViewDelegate: AnyObject {
    
    /// 當收藏按鈕被點選
    func onStarButtonClicked(indexPath: IndexPath)
    /// 當翻卡測驗按鈕被點選
    func onFlipCardButtonClicked()
    /// 當單字測驗按鈕被點選
    func onExamButtonClicked()
}

//MARK: - 自定義的view
extension MyVocabularyViews {
    
    //MARK: - 單字分類的header
    class HeaderView: UIView {
        
        private let titleLabel = PaddingLabel(withInsets: .init(top: 0, left: 10, bottom: 0, right: 10)).apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.numberOfLines = 1
            $0.backgroundColor = .hex("#f0f0f0")
        }
        private let arrowImageView = UIImageView(image: nil).apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        private let bottomLineView = UIView().apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = .hex("#e0e0e0")
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(titleLabel)
            addSubview(arrowImageView)
            addSubview(bottomLineView)
            titleLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            arrowImageView.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 25, height: 25))
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(10)
            }
            bottomLineView.snp.makeConstraints { make in
                make.bottom.leading.trailing.equalToSuperview()
                make.height.equalTo(1)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setSectionData(sectionModel: MyVocabularyViewModel.SectionData) {
            titleLabel.text = sectionModel.letter.uppercased() + " 共有\(sectionModel.count)個單字"
            let imageName = sectionModel.isExpanding ? "arrow.up" : "arrow.down"
            arrowImageView.image = .init(systemName: imageName)?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        }
        
    }
    
    //MARK: - 單字Cell
    class VocabularyCell: UITableViewCell, SpeechTextDelegate {
        
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
        var starButton = StarButton().apply {
            $0.cornerRadius = 5
        }
        private(set) var vocabulary: VocabularyModel?
        private(set) var indexPath: IndexPath = .init(row: 0, section: 0)
        weak var delegate: MyVocabularyViewDelegate?
        
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
            guard let text = self.vocabulary?.wordEntry.word else { return }
            speak(text: text)
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
    
    //MARK: - BottomToolBar
    class BottomToolBar: UIView {
        
        let flipCardButton = UIButton(type: .custom).apply {
            $0.setTitle("翻卡練習", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.backgroundColor = .systemBrown
            $0.cornerRadius = 25
        }
        let examButton = UIButton(type: .custom).apply {
            $0.setTitle("單字測驗", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.backgroundColor = .systemBrown
            $0.cornerRadius = 25
        }
        weak var delegate: MyVocabularyViewDelegate?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            backgroundColor = .white
            addSubview(flipCardButton)
            addSubview(examButton)
            flipCardButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 130, height: 50))
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().inset(50)
            }
            examButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 130, height: 50))
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(50)
            }
            flipCardButton.addTarget(self, action: #selector(flipCard), for: .touchUpInside)
            examButton.addTarget(self, action: #selector(exam), for: .touchUpInside)
        }
        
        @objc private func flipCard() {
            delegate?.onFlipCardButtonClicked()
        }
        
        @objc private func exam() {
            delegate?.onExamButtonClicked()
        }
        
    }
}
