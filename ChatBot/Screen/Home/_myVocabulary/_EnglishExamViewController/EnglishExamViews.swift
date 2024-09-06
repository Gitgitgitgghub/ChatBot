//
//  EnglishExamViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/23.
//

import Foundation
import UIKit
import NVActivityIndicatorView


class EnglishExamViews: ControllerView {
    
    
    let timerLabel = UILabel().apply {
        $0.numberOfLines = 1
        $0.textColor = .darkGray
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textAlignment = .center
    }
    let pauseButton = UIButton(type: .custom).apply {
        $0.setTitle("暫停考試", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .systemBrown
        $0.cornerRadius = 7
    }
    let pagerView = FSPagerView().apply {
        $0.transformer = .init(type: .depth)
        $0.interitemSpacing = 20
        $0.isScrollEnabled = false
    }
    let addNoteButton = UIButton(type: .custom).apply {
        $0.setTitle("加入筆記", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .systemBrown
        $0.cornerRadius = 7
    }
    
    override func initUI() {
        view.addSubview(pagerView)
        view.addSubview(timerLabel)
        view.addSubview(pauseButton)
        view.addSubview(addNoteButton)
        timerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.leading.equalToSuperview().inset(10)
        }
        pauseButton.snp.makeConstraints { make in
            make.centerY.equalTo(timerLabel)
            make.trailing.equalToSuperview().inset(10)
            make.size.equalTo(CGSize(width: 90, height: 30))
        }
        addNoteButton.snp.makeConstraints { make in
            make.centerY.equalTo(timerLabel)
            make.trailing.equalTo(pauseButton.snp.leading).offset(-5)
            make.size.equalTo(CGSize(width: 90, height: 30))
        }
        pagerView.snp.makeConstraints { make in
            make.top.equalTo(pauseButton.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
        }
    }
    
}

//MARK: Cell的delegate
protocol QuestionCardDelegate: AnyObject {
    func onOptionSelected(question: EnglishExamQuestion, selectedOption: String?)
}

extension EnglishExamViews {
    
    //MARK: - 問題卡片
    class QuestionCard: UIView {
        
        let questionLabel = UILabel().apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.font = SystemDefine.Message.defaultTextFont.withSize(22).bold()
            $0.numberOfLines = 0
            $0.textAlignment = .center
        }
        let questionAnswerLabel = UILabel().apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .darkGray
            $0.font = SystemDefine.Message.defaultTextFont.withSize(22).bold()
            $0.numberOfLines = 0
            $0.textAlignment = .left
        }
        let optionsStackView = UIStackView().apply {
            $0.axis = .vertical
            $0.spacing = 10
            $0.alignment = .center
            $0.distribution = .equalCentering
        }
        private(set) var question: EnglishExamQuestion?
        weak var delegate: QuestionCardDelegate?
        private(set) var optionButtons: [UIButton] = []
        private(set) var isAnswerMode: Bool = false
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            let spacerView = UIView()
            addSubview(questionLabel)
            addSubview(questionAnswerLabel)
            addSubview(optionsStackView)
            addSubview(spacerView)
            questionLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(20)
                make.top.equalToSuperview().inset(30)
            }
            questionAnswerLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(20)
                make.top.equalTo(questionLabel.snp.bottom).offset(5)
            }
            spacerView.snp.makeConstraints { make in
                make.top.equalTo(questionAnswerLabel.snp.bottom).offset(5)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(optionsStackView.snp.top)
                make.height.greaterThanOrEqualTo(0)
            }
            optionsStackView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(20)
                make.bottom.equalToSuperview().inset(30)
            }
        }
        
        @objc private func optionsSelected(sender: UIButton) {
            guard let question = self.question else { return }
            let selectedOption = question.options[sender.tag]
            delegate?.onOptionSelected(question: question, selectedOption: selectedOption)
        }
        
        func setQuestion(question: EnglishExamQuestion, isAnswerMode: Bool) {
            self.question = question
            self.isAnswerMode = isAnswerMode
            setOptions()
            setQuestionLabel()
            if isAnswerMode {
                setAndwerModeUI()
            }else {
                setQuestionModeUI()
            }
        }
        
        private func setQuestionLabel() {
            guard let question = self.question else { return }
            questionLabel.text = question.questionText
            switch question {
            case .vocabulayExamQuestion(_):
                questionLabel.font = .systemFont(ofSize: 22, weight: .bold)
                questionLabel.textAlignment = .center
            case .grammarExamQuestion(_):
                questionLabel.textAlignment = .left
                questionLabel.font = .systemFont(ofSize: 18, weight: .bold)
            }
        }
        
        private func setOptions() {
            guard let question = self.question else { return }
            optionsStackView.removeAllArrangedSubView()
            for (i, option) in question.options.enumerated() {
                let button = dequeueReusableOptionsButton(index: i)
                button.tag = i
                button.setTitle(option, for: .normal)
                button.isUserInteractionEnabled = !isAnswerMode
                optionsStackView.addArrangedSubview(button)
                if isAnswerMode {
                    //按钮颜色 正確答案綠色 用戶選擇的但答錯紅色 其他為咖啡色
                    if option == question.correctAnswer {
                        button.backgroundColor = .systemGreen
                    } else if option == question.userSelecedAnswer ?? "" {
                        if option != question.correctAnswer {
                            button.backgroundColor = .systemRed
                        }
                    } else {
                        button.backgroundColor = .systemBrown
                    }
                }else {
                    button.backgroundColor = .systemBrown
                }
            }
        }
        
        /// 復用舊按鈕
        private func dequeueReusableOptionsButton(index: Int) -> UIButton {
            if let button = optionButtons.getOrNil(index: index) {
                return button
            }else {
                let button = generateOptionButton()
                optionButtons.append(button)
                return button
            }
        }
        
        /// 產生全新的按鈕
        private func generateOptionButton() -> UIButton {
            let button = UIButton(type: .custom).apply {
                $0.setTitleColor(.white, for: .normal)
                $0.backgroundColor = .systemBrown
                $0.cornerRadius = 10
                $0.isUserInteractionEnabled = true
                $0.addTarget(self, action: #selector(optionsSelected), for: .touchUpInside)
                $0.titleLabel?.numberOfLines = 0
                $0.snp.makeConstraints { make in
                    make.height.greaterThanOrEqualTo(40)
                    make.width.equalTo(250)
                }
            }
            return button
        }
        
        private func setQuestionModeUI() {
            guard let question = self.question else { return }
            questionLabel.text = question.questionText
            questionAnswerLabel.isVisible = false
        }
        
        private func setAndwerModeUI() {
            setQuestionTranslationLabel()
        }
        
        private func setQuestionTranslationLabel() {
            guard let question = self.question else { return }
            switch question {
            case .vocabulayExamQuestion(_): break
            case .grammarExamQuestion(let data):
                questionAnswerLabel.font = .boldSystemFont(ofSize: 18)
                questionAnswerLabel.isVisible = true
                questionAnswerLabel.text = data.displayReason
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
        
        func bindEnglishQuestion(question: EnglishExamQuestion, isAnswerMode: Bool) {
            questionCard.setQuestion(question: question, isAnswerMode: isAnswerMode)
        }
        
    }
    
}
