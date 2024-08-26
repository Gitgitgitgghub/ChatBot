//
//  VocabularyExamViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/23.
//

import Foundation
import UIKit


class VocabularyExamViews: ControllerView {
    
    
    let indexLabel = UILabel().apply {
        $0.numberOfLines = 1
        $0.textColor = .darkGray
        $0.font = .systemFont(ofSize: 22, weight: .bold)
        $0.textAlignment = .center
    }
    let timerLabel = UILabel().apply {
        $0.numberOfLines = 1
        $0.textColor = .darkGray
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textAlignment = .center
    }
    let pauseButton = UIButton(type: .custom).apply {
        $0.setTitle("暫停", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .systemBrown
        $0.cornerRadius = 7
    }
    let pagerView = FSPagerView().apply {
        $0.transformer = .init(type: .depth)
        $0.interitemSpacing = 20
        $0.isScrollEnabled = false
    }
    
    override func initUI() {
        view.addSubview(indexLabel)
        view.addSubview(pagerView)
        view.addSubview(timerLabel)
        view.addSubview(pauseButton)
        indexLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.leading.trailing.equalToSuperview()
        }
        timerLabel.snp.makeConstraints { make in
            make.centerY.equalTo(indexLabel)
            make.leading.equalToSuperview().inset(10)
        }
        pauseButton.snp.makeConstraints { make in
            make.centerY.equalTo(indexLabel)
            make.trailing.equalToSuperview().inset(10)
            make.size.equalTo(CGSize(width: 50, height: 30))
        }
        pagerView.snp.makeConstraints { make in
            make.top.equalTo(indexLabel.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
        }
    }
    
}

protocol QuestionCardDelegate: AnyObject {
    
    func onOptionSelected(question: VocabulayExamQuestion, selectedOption: String?)
    
}

extension VocabularyExamViews {
    
    //MARK: - 問題卡片
    class QuestionCard: UIView {
        
        let questionLabel = UILabel().apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.font = SystemDefine.Message.defaultTextFont.withSize(22).bold()
            $0.numberOfLines = 1
            $0.textAlignment = .center
        }
        let answerStackView = UIStackView().apply {
            $0.axis = .vertical
            $0.spacing = 10
            $0.alignment = .center
            $0.distribution = .equalCentering
        }
        var question: VocabulayExamQuestion?
        weak var delegate: QuestionCardDelegate?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            addSubview(questionLabel)
            addSubview(answerStackView)
            questionLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().inset(30)
            }
            answerStackView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(30)
                make.centerX.equalToSuperview()
            }
            for i in 0..<3 {
                let button = UIButton(type: .custom).apply {
                    $0.setTitleColor(.white, for: .normal)
                    $0.backgroundColor = .systemBrown
                    $0.cornerRadius = 10
                    $0.tag = i
                    $0.addTarget(self, action: #selector(optionsSelected), for: .touchUpInside)
                }
                answerStackView.addArrangedSubview(button)
                button.snp.makeConstraints { make in
                    make.size.equalTo(CGSize(width: 250, height: 40))
                }
            }
        }
        
        @objc private func optionsSelected(sender: UIButton) {
            guard let question = self.question else { return }
            let selectedOption = question.options[sender.tag]
            delegate?.onOptionSelected(question: question, selectedOption: selectedOption)
        }
        
        func setQuestion(question: VocabulayExamQuestion) {
            self.question = question
            questionLabel.text = question.questionText
            for (i, option) in question.options.enumerated() {
                guard let button = answerStackView.arrangedSubviews[i] as? UIButton else { continue }
                button.setTitle(option, for: .normal)
            }
        }
        
    }
    
    //MARK: 問題Cell
    class VocabularyExamQuestionCell: FSPagerViewCell {
        
        private let questionCard = QuestionCard().apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = .hex("#f5deb3")
            $0.cornerRadius = 30
        }
        weak var delegate: QuestionCardDelegate? {
            didSet {
                questionCard.delegate = delegate
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
        
        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            contentView.layer.shadowColor = UIColor.clear.cgColor
            contentView.addSubview(questionCard)
            questionCard.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        func bindVocabulayExamQuestion(question: VocabulayExamQuestion) {
            questionCard.setQuestion(question: question)
        }
        
    }
    
}
