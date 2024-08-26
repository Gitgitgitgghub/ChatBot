//
//  VocabularyExamViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/23.
//

import Foundation
import UIKit


class VocabularyExamViewController: BaseUIViewController {
    
    private let viewModel: VocabularyExamViewModel
    private lazy var views = VocabularyExamViews(view: self.view)
    private var pagerView: FSPagerView {
        return views.pagerView
    }
    
    init(questionType: SystemDefine.VocabularyExam.QuestionType, vocabularies: [VocabularyModel]) {
        self.viewModel = .init(questionType: questionType, vocabularies: vocabularies)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
        viewModel.transform(inputEvent: .fetchQuestion)
    }
    
    private func initUI() {
        title = "單字測驗"
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.register(VocabularyExamViews.VocabularyExamQuestionCell.self, forCellWithReuseIdentifier: VocabularyExamViews.VocabularyExamQuestionCell.className)
        views.pauseButton.addTarget(self, action: #selector(paustExam), for: .touchUpInside)
    }
    
    @objc private func paustExam() {
        viewModel.transform(inputEvent: .pauseExam)
    }
    
    private func bind() {
        viewModel.bindInputEvent()
        viewModel.outputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .indexChange(string: let string):
                    self.indexChange(string: string)
                case .error(message: let message):
                    self.showToast(message: "題目數量不足") { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                case .scrollToNextQuestion:
                    self.pagerView.scrollToItem(at: self.pagerView.currentIndex + 1, animated: true)
                case .updateTimer(string: let string):
                    self.views.timerLabel.attributedText = string
                }
            }
            .store(in: &subscriptions)
        viewModel.$examState
            .sink { [weak self] state in
                self?.examState(state: state)
            }
            .store(in: &subscriptions)
    }
    
    private func examState(state: VocabularyExamViewModel.ExamState) {
        switch state {
        case .preparing: 
            break
        case .ready:
            let vc = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            vc.message = "點擊開始考試"
            vc.addAction(.init(title: "開始考試", style: .default, handler: { _ in
                self.viewModel.transform(inputEvent: .startExam)
            }))
            present(vc, animated: true)
            pagerView.reloadData()
        case .started: break
        case .paused:
            let vc = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            vc.message = "點擊恢復考試"
            vc.addAction(.init(title: "恢復考試", style: .default, handler: { _ in
                self.viewModel.transform(inputEvent: .startExam)
            }))
            vc.addAction(.init(title: "放棄離開", style: .destructive, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(vc, animated: true)
        case .ended(correctCount: let correctCount, wrongCount: let wrongCount):
            self.showExamResult(correctCount: correctCount, wrongCount: wrongCount)
        }
    }
    
    private func indexChange(string: String) {
        views.indexLabel.text = string
    }
    
    private func showExamResult(correctCount: Int, wrongCount: Int) {
        let message = "答對了\(correctCount)題\n答錯了\(wrongCount)題"
        let vc = UIAlertController(title: "答題結果", message: message, preferredStyle: .alert)
        if wrongCount > 0 {
            vc.addAction(.init(title: "重做錯誤題", style: .default, handler: { _ in
                self.viewModel.transform(inputEvent: .retakeExam)
                self.pagerView.scrollToItem(at: 0, animated: false)
            }))
        }
        vc.addAction(.init(title: "離開", style: .destructive, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(vc, animated: true)
    }
    
}

//MARK: - QuestionCardDelegate
extension VocabularyExamViewController: QuestionCardDelegate {
    
    func onOptionSelected(question: VocabulayExamQuestion, selectedOption: String?) {
        viewModel.transform(inputEvent: .onOptionSelected(question: question, selectedOption: selectedOption))
    }
    
}

//MARK: - FSPagerViewDelegate, FSPagerViewDataSource
extension VocabularyExamViewController: FSPagerViewDelegate, FSPagerViewDataSource {
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return viewModel.questions.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        guard let cell = pagerView.dequeueReusableCell(withReuseIdentifier: VocabularyExamViews.VocabularyExamQuestionCell.self.className, at: index) as? VocabularyExamViews.VocabularyExamQuestionCell else {
            return FSPagerViewCell()
        }
        viewModel.transform(inputEvent: .currentIndexChange(currentIndex: index))
        cell.bindVocabulayExamQuestion(question: viewModel.questions[index])
        cell.delegate = self
        return cell
    }
    
    
}
