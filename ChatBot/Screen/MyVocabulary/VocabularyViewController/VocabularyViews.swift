//
//  VocabularyViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/13.
//

import Foundation
import UIKit


class VocabularyViews: ControllerView {

    let pagerView = FSPagerView()
    
    override func initUI() {
        view.addSubview(pagerView)
        pagerView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
}

extension VocabularyViews {
    
    //MARK: 字卡的cell
    class VocabularyPagerViewCell: FSPagerViewCell, UITableViewDataSource, UITableViewDelegate {
        
        private(set) var vocabulary: VocabularyModel?
        private let tableView = UITableView(frame: .zero, style: .plain).apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.estimatedRowHeight = UITableView.automaticDimension
            $0.separatorStyle = .none
        }
//        private enum Section {
//            case word
//            case example
//        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            contentView.addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(cellType: WordCell.self)
            tableView.register(cellType: WordExampleCell.self)
        }
        
        func bindVocabulary(vocabulary: VocabularyModel) {
            self.vocabulary = vocabulary
            tableView.reloadData()
        }
        
        //MARK: UITableViewDataSource, UITableViewDelegate
        func numberOfSections(in tableView: UITableView) -> Int {
            return 2
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            switch section {
            case 0:
                return 1
            default:
                return vocabulary?.wordSentences.count ?? 0
            }
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCell(with: WordCell.self, for: indexPath)
                cell.bindWord(vocabulary: vocabulary)
                return cell
            default:
                let cell = tableView.dequeueReusableCell(with: WordExampleCell.self, for: indexPath)
                if let sentence = vocabulary?.wordSentences.getOrNil(index: indexPath.row) {
                    cell.bindWordSentence(wordSentence: sentence)
                }
                return cell
            }
        }
        
    }
    
}

fileprivate class WordCell: UITableViewCell {
    
    private let wordLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = .boldSystemFont(ofSize: 22)
        $0.numberOfLines = 1
    }
    private let kkLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = .systemFont(ofSize: 18)
        $0.numberOfLines = 1
    }
    private let definitionsLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = .systemFont(ofSize: 18)
    }
    private let lineView = UIView().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .systemGray
    }
    private(set) var vocabulary: VocabularyModel?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        contentView.addSubview(wordLabel)
        contentView.addSubview(kkLabel)
        contentView.addSubview(definitionsLabel)
        contentView.addSubview(lineView)
        wordLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        definitionsLabel.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
        }
        kkLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(wordLabel.snp.bottom).priority(.medium)
            make.bottom.equalTo(definitionsLabel.snp.top).priority(.medium)
        }
        lineView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(definitionsLabel.snp.bottom).offset(10)
        }
    }
    
    func bindWord(vocabulary: VocabularyModel?) {
        self.vocabulary = vocabulary
        wordLabel.text = vocabulary?.wordEntry.word
        kkLabel.text = "[\(vocabulary?.kkPronunciation ?? "")]"
        definitionsLabel.text = vocabulary?.wordEntry.displayDefinitionString
    }
    
}

fileprivate class WordExampleCell: UITableViewCell {
    
    private let sentenceLabel = PaddingLabel(withInsets: .init(top: 25, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = .boldSystemFont(ofSize: 18)
        $0.numberOfLines = 0
    }
    private let translationLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = .boldSystemFont(ofSize: 18)
        $0.numberOfLines = 0
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        contentView.addSubview(sentenceLabel)
        contentView.addSubview(translationLabel)
        sentenceLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        translationLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(sentenceLabel.snp.bottom).priority(.medium)
            make.bottom.equalToSuperview()
        }
    }
    
    func bindWordSentence(wordSentence: WordSentence) {
        sentenceLabel.text = wordSentence.sentence
        translationLabel.text = wordSentence.translation
    }
}
