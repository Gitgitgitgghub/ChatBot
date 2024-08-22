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

protocol FlipCardViewsDelegate: AnyObject {
    
    func onClickStar(index: Int)
    
}

//MARK: - FlipCardViews
extension FlipCardViews {
    
    //MARK: - 卡片ＵＩ
    class CardView: UIView, SpeechTextDelegate {
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
        private let kkLabel = PaddingLabel(withInsets: .init(top: 5, left: 15, bottom: 5, right: 10)).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.font = SystemDefine.Message.defaultTextFont.withSize(18).bold()
            $0.numberOfLines = 1
        }
        let speakButton = UIButton(type: .custom).apply{
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setImage(UIImage(systemName: "speaker.wave.2.fill")?.withTintColor(.systemBrown, renderingMode: .alwaysOriginal), for: .normal)
        }
        let starButton = StarButton()
        let functionsStackView = UIStackView().apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.alignment = .center
            $0.axis = .horizontal
            $0.distribution = .equalSpacing 
            $0.spacing = 20
        }
        private(set) var isFlipped: Bool = false
        private(set) var vocabulary: VocabularyModel?
        
        init(isFlipped: Bool) {
            self.isFlipped = isFlipped
            super.init(frame: .zero)
            initUI()
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
            addSubview(kkLabel)
            addSubview(definitionsLabel)
            addSubview(functionsStackView)
            indexLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(15)
                make.leading.trailing.equalToSuperview()
            }
            wordLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            kkLabel.snp.makeConstraints { make in
                make.top.equalTo(wordLabel.bottom).priority(.medium)
                make.centerX.equalToSuperview()
            }
            definitionsLabel.snp.makeConstraints { make in
                make.top.equalTo(kkLabel.bottom).offset(15).priority(.medium)
                make.centerX.equalToSuperview()
            }
            functionsStackView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(20)
            }
            starButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 45, height: 45))
            }
            speakButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 45, height: 45))
            }
            functionsStackView.addArrangedSubview(starButton)
            functionsStackView.addArrangedSubview(speakButton)
            if !isFlipped {
                functionsStackView.isVisible = false
                kkLabel.isVisible = false
                definitionsLabel.isVisible = false
            }
            backgroundColor = isFlipped ? .lightGray : .systemBrown
            speakButton.addTarget(self, action: #selector(speakVocabulary), for: .touchUpInside)
        }
        
        @objc private func speakVocabulary() {
            guard let vocabulary = self.vocabulary else { return }
            speak(text: vocabulary.wordEntry.word)
        }
        
        func bindVocabulary(vocabulary: VocabularyModel, index: Int, total: Int) {
            self.vocabulary = vocabulary
            indexLabel.text = "\(index + 1)/\(total)"
            wordLabel.text = vocabulary.wordEntry.word
            definitionsLabel.text = vocabulary.wordEntry.displayDefinitionString
            if vocabulary.kkPronunciation.isEmpty {
                kkLabel.isVisible = false
            }else {
                kkLabel.text = "KK [\(vocabulary.kkPronunciation)]"
            }
        }
    }
    
    //MARK: - 卡片cell
    class CardContentCell: FSPagerViewCell {
        
        private(set) var isFlipped = false
        private(set) var index = 0
        private(set) var total = 0
        private(set) var vocabulary: VocabularyModel?
        private let originalView = CardView(isFlipped: false).apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        private let flippedView = CardView(isFlipped: true).apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        private var cardView: CardView {
            return isFlipped ? flippedView: originalView
        }
        weak var delegate: FlipCardViewsDelegate?
        
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
            flippedView.starButton.addTarget(self, action: #selector(starButtonClicked), for: .touchUpInside)
        }
        
        @objc private func starButtonClicked() {
            delegate?.onClickStar(index: index)
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
            originalView.starButton.isSelected = vocabulary.isStar
            flippedView.starButton.isSelected = vocabulary.isStar
        }
        
        func flipCardView(isFlipped: Bool) {
            self.isFlipped = isFlipped
            let fromView = isFlipped ? originalView : flippedView
            let toView = isFlipped ? flippedView : originalView
            let filpAnimation: UIView.AnimationOptions = isFlipped ? .transitionFlipFromRight : .transitionFlipFromLeft
            UIView.transition(with: contentView, duration: 0.5, options: [filpAnimation, .showHideTransitionViews], animations: {
                fromView.isHidden = true
                toView.isHidden = false
            }, completion: nil)
        }


        
    }
    
}
