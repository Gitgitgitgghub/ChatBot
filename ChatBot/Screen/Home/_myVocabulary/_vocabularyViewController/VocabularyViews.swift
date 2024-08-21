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
    let starButton = UIButton(type: .custom).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.cornerRadius = 10
        $0.backgroundColor = .systemBrown
        $0.setImage(UIImage(systemName: "star")?.withTintColor(.hex("#f5deb3"), renderingMode: .alwaysOriginal), for: .normal)
        $0.setImage(UIImage(systemName: "star.fill")?.withTintColor(.hex("#f5deb3"), renderingMode: .alwaysOriginal), for: .selected)
    }
    let moreButton = UIButton(type: .custom).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setTitle("更多句子", for: .normal)
        $0.titleLabel?.font = .boldSystemFont(ofSize: 12)
        $0.cornerRadius = 10
        $0.backgroundColor = .systemBrown
        $0.setTitleColor(.white, for: .normal)
    }
    lazy var functionsStackView = UIStackView().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alignment = .center
        $0.axis = .horizontal
        $0.distribution = .equalSpacing
        $0.spacing = 40
    }
    
    override func initUI() {
        view.addSubview(pagerView)
        view.addSubview(functionsStackView)
        pagerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(functionsStackView.top)
        }
        functionsStackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }
        starButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        moreButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 80, height: 40))
        }
        functionsStackView.addArrangedSubview(starButton)
        functionsStackView.addArrangedSubview(moreButton)
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
            tableView.register(cellType: WordSentenceCell.self)
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
                let cell = tableView.dequeueReusableCell(with: WordSentenceCell.self, for: indexPath)
                if let sentence = vocabulary?.wordSentences.getOrNil(index: indexPath.row) {
                    cell.bindWordSentence(wordSentence: sentence, indexPath: indexPath)
                }
                return cell
            }
        }
        
    }
    
}

//MARK: - 最上方單字資訊的cell
fileprivate class WordCell: UITableViewCell, SpeechTextDelegate {
    
    private let wordLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = SystemDefine.Message.defaultTextFont.withSize(22).bold()
        $0.numberOfLines = 1
    }
    private let kkLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = SystemDefine.Message.defaultTextFont.withSize(18).bold()
        $0.numberOfLines = 1
    }
    private let definitionsLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = SystemDefine.Message.defaultTextFont.withSize(18).bold()
        $0.numberOfLines = 0
    }
    private let lineView = UIView().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .systemGray
    }
    var speakButton = UIButton(type: .custom).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(.init(systemName: "speaker.wave.2.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .normal)
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
        contentView.addSubview(speakButton)
        wordLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.trailing.equalTo(speakButton.snp.leading)
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
        speakButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 30, height: 30))
            make.centerY.equalTo(wordLabel)
            make.trailing.equalToSuperview().inset(20)
        }
        speakButton.addTarget(self, action: #selector(sepak), for: .touchUpInside)
    }
    
    func bindWord(vocabulary: VocabularyModel?) {
        self.vocabulary = vocabulary
        wordLabel.text = vocabulary?.wordEntry.word
        kkLabel.text = "KK [\(vocabulary?.kkPronunciation ?? "")]"
        definitionsLabel.text = vocabulary?.wordEntry.displayDefinitionString
    }
    
    @objc private func sepak() {
        guard let word = self.vocabulary?.wordEntry.word else { return }
        speak(text: word)
    }
    
}

//MARK: - 句子的cell
fileprivate class WordSentenceCell: UITableViewCell, SpeechTextDelegate {
    
    private let sentenceTitleLabel = PaddingLabel(withInsets: .init(top: 25, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = SystemDefine.Message.defaultTextFont.withSize(18).bold()
        $0.numberOfLines = 0
        $0.text = "例句:"
        $0.isVisible = false
        $0.textColor = .systemBrown
    }
    private let sentenceLabel = PaddingLabel(withInsets: .init(top: 10, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = SystemDefine.Message.defaultTextFont.withSize(18).bold()
        $0.numberOfLines = 0
    }
    private let translationLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .darkGray
        $0.font = SystemDefine.Message.defaultTextFont.withSize(18).bold()
        $0.numberOfLines = 0
    }
    var speakButton = UIButton(type: .custom).apply{
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(.init(systemName: "speaker.wave.2.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .normal)
    }
    private(set) var indexPath: IndexPath?
    private(set) var wordSentence: WordSentence?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        contentView.addSubview(sentenceTitleLabel)
        contentView.addSubview(sentenceLabel)
        contentView.addSubview(translationLabel)
        contentView.addSubview(speakButton)
        sentenceTitleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        sentenceLabel.snp.makeConstraints { make in
            make.top.equalTo(sentenceTitleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview()
            make.trailing.equalTo(speakButton.snp.leading)
        }
        translationLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(sentenceLabel.snp.bottom).priority(.medium)
            make.bottom.equalToSuperview()
        }
        speakButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 30, height: 30))
            make.centerY.equalTo(sentenceLabel)
            make.trailing.equalToSuperview().inset(20)
        }
        speakButton.addTarget(self, action: #selector(sepak), for: .touchUpInside)
    }
    
    func bindWordSentence(wordSentence: WordSentence, indexPath: IndexPath) {
        self.wordSentence = wordSentence
        self.indexPath = indexPath
        sentenceLabel.text = wordSentence.sentence
        translationLabel.text = wordSentence.translation
        sentenceTitleLabel.isVisible = indexPath.row == 0
    }
    
    @objc private func sepak() {
        guard let sentence = wordSentence?.sentence else { return }
        speak(text: sentence)
    }
}
