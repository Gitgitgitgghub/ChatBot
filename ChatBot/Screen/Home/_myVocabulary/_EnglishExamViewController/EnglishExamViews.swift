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
    }
    let addNoteButton = UIButton(type: .custom).apply {
        $0.setTitle("加入筆記", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .systemBrown
        $0.cornerRadius = 7
    }
    let questionIndicatorView = QuestionPageIndicatorView()
    private(set) var questionType: SystemDefine.EnglishExam.QuestionType
    
    
    init(view: UIView, questionType: SystemDefine.EnglishExam.QuestionType) {
        self.questionType = questionType
        super.init(view: view)
        initUI()
    }
    
    required init(view: UIView) {
        fatalError("init(view:) has not been implemented")
    }
    
    override func initUI() {
        view.addSubview(pagerView)
        view.addSubview(timerLabel)
        view.addSubview(pauseButton)
        view.addSubview(addNoteButton)
        view.addSubview(questionIndicatorView)
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
        questionIndicatorView.snp.makeConstraints { make in
            let height = 30
            make.height.equalTo(height)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(pauseButton.bottom).offset(10)
        }
        pagerView.snp.makeConstraints { make in
            make.top.equalTo(questionIndicatorView.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
        }
        questionIndicatorView.pageChangeListener = { [weak self] pageIndex in
            self?.pagerView.scrollToItem(at: pageIndex, animated: true)
        }
    }
    
}

//MARK: Cell的delegate
protocol QuestionCardDelegate: AnyObject {
    func onOptionSelected(question: EnglishExamQuestion, selectedOption: String?)
}

extension EnglishExamViews {
    
    //MARK: 問題指示器 QuestionIndicatorView
    class QuestionPageIndicatorView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
        
        let previousButton = UIButton(type: .custom).apply {
            $0.setImage(.init(systemName: "arrow.backward")?.withTintColor(.fromAppColors(\.darkCoffeeText), renderingMode: .alwaysOriginal), for: .normal)
            $0.cornerRadius = 15
            $0.backgroundColor = .fromAppColors(\.lightCoffeeButton)
            $0.isVisible = false
        }
        let nextButton = UIButton(type: .custom).apply {
            $0.setImage(.init(systemName: "arrow.forward")?.withTintColor(.fromAppColors(\.darkCoffeeText), renderingMode: .alwaysOriginal), for: .normal)
            $0.cornerRadius = 15
            $0.backgroundColor = .fromAppColors(\.lightCoffeeButton)
            $0.isVisible = false
        }
        lazy var collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = .init(width: 30, height: 30)
            layout.minimumLineSpacing = 5
            layout.scrollDirection = .horizontal
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.collectionViewLayout = layout
            return collectionView
        }()
        private(set) var questionNumbers: [String] = []
        private(set) var currentPage = 0
        
        var pageChangeListener: ((_ page: Int) -> ())?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func initUI() {
            addSubview(previousButton)
            addSubview(nextButton)
            addSubview(collectionView)
            previousButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 30, height: 30))
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().inset(30)
            }
            nextButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 30, height: 30))
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(30)
            }
            collectionView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.equalTo(previousButton.trailing).offset(5)
                make.trailing.equalTo(nextButton.leading).offset(-5)
            }
            collectionView.register(cellType: Cell.self)
            collectionView.delegate = self
            collectionView.dataSource = self
            previousButton.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
            nextButton.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        }
        
        func setQuestionNumbers(questionNumbers: [String]) {
            self.questionNumbers = questionNumbers
            self.currentPage = 0
            collectionView.reloadData()
            if questionNumbers.isNotEmpty {
                previousButton.isVisible = true
                nextButton.isVisible = true
                collectionView.selectItem(at: .init(item: currentPage, section: 0), animated: false, scrollPosition: .left)
            }
        }
        
        func setCurrentPage(pageIndex: Int) {
            guard pageIndex != currentPage && pageIndex < questionNumbers.count else { return }
            currentPage = pageIndex
            collectionView.selectItem(at: .init(item: currentPage, section: 0), animated: false, scrollPosition: .left)
        }
        
        @objc private func buttonClicked(sender: UIButton) {
            if sender == previousButton && currentPage > 0 {
                currentPage -= 1
            }else if sender == nextButton && currentPage < questionNumbers.count - 1 {
                currentPage += 1
            }else {
                return
            }
            pageSelected()
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return questionNumbers.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(with: Cell.self, for: indexPath)
            let questionNumber = questionNumbers[indexPath.item]
            cell.label.text = questionNumber
            cell.cornerRadius = 15
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let questionNumber = questionNumbers[indexPath.item]
            if let pageIndex = questionNumbers.firstIndex(of: questionNumber), pageIndex != currentPage {
                currentPage = pageIndex
                pageSelected()
            }
        }
        
        private func pageSelected() {
            collectionView.selectItem(at: .init(item: currentPage, section: 0), animated: false, scrollPosition: .left)
            pageChangeListener?(currentPage)
        }
        
        fileprivate class Cell: UICollectionViewCell {
            
            let label = UILabel().apply {
                $0.translatesAutoresizingMaskIntoConstraints = true
                $0.font = .boldSystemFont(ofSize: 14)
                $0.textAlignment = .center
                $0.textColor = .fromAppColors(\.darkCoffeeText)
            }
            override var isSelected: Bool {
                didSet {
                    if isSelected {
                        self.backgroundColor = .fromAppColors(\.creamBackground)
                    } else {
                        self.backgroundColor = .fromAppColors(\.lightCoffeeButton)
                    }
                }
            }
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                backgroundColor = .fromAppColors(\.lightCoffeeButton)
                addSubview(label)
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            override func layoutSubviews() {
                super.layoutSubviews()
                label.frame = self.bounds
            }
            
        }
        
    }
    
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
            case .readingExamQuestion(let data):
                if data.isArticle() {
                    questionLabel.textAlignment = .left
                    questionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
                }else {
                    questionLabel.textAlignment = .left
                    questionLabel.font = .systemFont(ofSize: 18, weight: .bold)
                }
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
                button.setTitleColor(.white, for: .normal)
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
                    if option == question.userSelecedAnswer {
                        button.backgroundColor = .fromAppColors(\.lightCoffeeButton)
                        button.backgroundColor = .fromAppColors(\.darkCoffeeText)
                    }else {
                        button.backgroundColor = .systemBrown
                    }
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
                    make.width.equalTo(UIScreen.main.bounds.width - 100)
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
            case .readingExamQuestion(data: let data):
                questionAnswerLabel.font = .boldSystemFont(ofSize: 18)
                questionAnswerLabel.isVisible = true
                questionAnswerLabel.text = data.reason
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
