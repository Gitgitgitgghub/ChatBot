//
//  FlipCardViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/20.
//

import Foundation
import UIKit


class FlipCardViews: ControllerView {
    
    let titleLabel = UILabel().apply {
        $0.text = "每次測驗隨機抽取３０個單字"
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    let pagerView = FSPagerView().apply {
        $0.transformer = .init(type: .linear)
        $0.interitemSpacing = 20
        $0.itemSize = .init(width: 300, height: 500)
    }
    let flipCardButton = UIButton(type: .custom).apply {
        $0.setTitle("翻卡", for: .normal)
        $0.backgroundColor = .systemBrown
        $0.cornerRadius = 30
    }
    
    override func initUI() {
        view.addSubview(titleLabel)
        view.addSubview(pagerView)
        view.addSubview(flipCardButton)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.trailing.equalToSuperview()
        }
        pagerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.bottom).offset(10)
            make.bottom.equalTo(flipCardButton.top).offset(-10)
            make.leading.trailing.equalToSuperview()
        }
        flipCardButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 100, height: 60))
        }
    }
    
}

//MARK: - FlipCardViews
extension FlipCardViews {
    
    //MARK: - 卡片ＵＩ
    class CardView: UIView {
        let indexLabel = PaddingLabel(withInsets: .zero).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.font = SystemDefine.Message.defaultTextFont.withSize(14).bold()
            $0.numberOfLines = 1
            $0.textAlignment = .center
        }
        let wordLabel = PaddingLabel(withInsets: .init(top: 0, left: 10, bottom: 0, right: 10)).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.font = SystemDefine.Message.defaultTextFont.withSize(22).bold()
            $0.numberOfLines = 1
            $0.textAlignment = .center
        }
        let definitionsLabel = PaddingLabel(withInsets: .init(top: 0, left: 10, bottom: 0, right: 10)).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.font = SystemDefine.Message.defaultTextFont.withSize(18).bold()
            $0.numberOfLines = 0
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            cornerRadius = 10
            addSubview(indexLabel)
            addSubview(wordLabel)
            addSubview(definitionsLabel)
            indexLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(15)
                make.leading.trailing.equalToSuperview()
            }
            wordLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            definitionsLabel.snp.makeConstraints { make in
                make.top.equalTo(wordLabel.bottom).offset(15)
                make.centerX.equalToSuperview()
            }
        }
        
        func bindVocabulary(vocabulary: VocabularyModel, index: Int, total: Int) {
            indexLabel.text = "\(index + 1)/\(total)"
            wordLabel.text = vocabulary.wordEntry.word
            definitionsLabel.text = vocabulary.wordEntry.displayDefinitionString
        }
    }
    
    //MARK: - 卡片cell
    class CardContentCell: FSPagerViewCell {
        
        private(set) var isFlipped = false
        private(set) var index = 0
        private(set) var total = 0
        private(set) var vocabulary: VocabularyModel?
        private let originalView = CardView().apply {
            $0.definitionsLabel.isVisible = false
            $0.backgroundColor = .systemBrown
        }
        private let flippedView = CardView().apply {
            $0.backgroundColor = .systemBrown.withAlphaComponent(0.6)
        }
        private var cardView: CardView {
            return isFlipped ? flippedView: originalView
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            contentView.cornerRadius = 10
            contentView.addSubview(flippedView)
            contentView.addSubview(originalView)
            flippedView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            originalView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        func bindVocabulary(vocabulary: VocabularyModel, index: Int, total: Int, isFlipped: Bool) {
            self.vocabulary = vocabulary
            self.index = index
            self.total = total
            self.isFlipped = isFlipped
            setupUI()
        }
        
        private func setupUI() {
            guard let vocabulary = self.vocabulary else { return }
            flippedView.bindVocabulary(vocabulary: vocabulary, index: index, total: total)
            originalView.bindVocabulary(vocabulary: vocabulary, index: index, total: total)
            flippedView.isVisible = isFlipped
            originalView.isVisible = !isFlipped
            
        }
        
        func flipCardView(isFlipped: Bool) {
            self.isFlipped = isFlipped
            UIView.transition(with: cardView, duration: 0.3, options: isFlipped ? .transitionFlipFromRight : .transitionFlipFromLeft, animations: {
                // 這裡可以執行翻轉前後所需要的UI更新
                self.setupUI()
            }, completion: nil)
        }
        
    }
    
}
