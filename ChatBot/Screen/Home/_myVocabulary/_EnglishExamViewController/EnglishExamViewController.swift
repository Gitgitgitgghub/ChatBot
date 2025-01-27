//
//  EnglishExamViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/23.
//

import Foundation
import UIKit


class EnglishExamViewController: BaseUIViewController<EnglishExamViewModel> {
    
    private lazy var views = EnglishExamViews(view: self.view, questionType: self.viewModel.questionType)
    private var pagerView: FSPagerView {
        return views.pagerView
    }
    
    init(questionType: SystemDefine.EnglishExam.QuestionType, vocabularies: [VocabularyModel]) {
        super.init(viewModel: .init(questionType: questionType, vocabularies: vocabularies))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
        sendInputEvent(.fetchQuestion)
    }
    
    private func initUI() {
        title = viewModel.questionType.title
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.register(EnglishExamViews.VocabularyExamQuestionCell.self, forCellWithReuseIdentifier: EnglishExamViews.VocabularyExamQuestionCell.className)
        views.pauseButton.addTarget(self, action: #selector(paustExam), for: .touchUpInside)
        views.addNoteButton.addTarget(self, action: #selector(addNote), for: .touchUpInside)
    }
    
    @objc private func paustExam() {
        sendInputEvent(.pauseExam)
    }
    
    @objc private func addNote() {
        sendInputEvent(.addToNote)
    }
    
    override func handleOutputEvent(_ outputEvent: EnglishExamViewModel.OutputEvent) {
        switch outputEvent {
        case .indexChange(let newIndex):
            self.indexChange(newIndex: newIndex)
        case .scrollToNextQuestion(let index):
            self.pagerView.scrollToItem(at: index, animated: true)
        case .updateTimer(string: let string):
            self.views.timerLabel.attributedText = string
        case .toast(message: let message):
            self.showToast(message: message) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func onLoadingStatusChanged(status: LoadingStatus) {
        views.showLoadingView(status: status, with: "AI正在產生題目中")
    }
    
    private func bind() {
        viewModel.$examState
            .sink { [weak self] state in
                self?.examState(state: state)
                self?.setAddNoteButtonVisible(state: state)
                self?.updatePauseButtonUI(state: state)
            }
            .store(in: &subscriptions)
    }
    
    private func examState(state: EnglishExamViewModel.ExamState) {
        switch state {
        case .preparing: 
            views.pauseButton.isEnabled = false
            views.addNoteButton.isEnabled = false
        case .ready:
            setupReadyUI()
        case .started: break
        case .paused:
            let vc = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            vc.message = "點擊恢復考試"
            vc.addAction(.init(title: "恢復考試", style: .default, handler: { _ in
                self.sendInputEvent(.startExam)
            }))
            vc.addAction(.init(title: "放棄離開", style: .destructive, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(vc, animated: true)
        case .ended(correctCount: let correctCount, wrongCount: let wrongCount):
            self.showExamResult(correctCount: correctCount, wrongCount: wrongCount)
        case .answerMode:
            pagerView.reloadData()
            pagerView.scrollToItem(at: 0, animated: false)
        }
    }
    
    /// 設定 examState ＝ ready ui
    private func setupReadyUI() {
        let vc = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        vc.message = "點擊開始考試"
        vc.addAction(.init(title: "開始考試", style: .default, handler: { _ in
            self.sendInputEvent(.startExam)
        }))
        present(vc, animated: true)
        views.pauseButton.isEnabled = true
        views.addNoteButton.isEnabled = true
        pagerView.reloadData()
        views.questionIndicatorView.setQuestionNumbers(questionNumbers: viewModel.questions.questionNumbers())
    }
    
    private func setAddNoteButtonVisible(state: EnglishExamViewModel.ExamState) {
        views.addNoteButton.isVisible = state == .answerMode
    }
    
    private func updatePauseButtonUI(state: EnglishExamViewModel.ExamState) {
        print(state)
        if state == .answerMode {
            views.pauseButton.isVisible = viewModel.wrongAnswerQuestions.isNotEmpty
            views.pauseButton.setTitle("錯題重做", for: .normal)
        }else {
            views.pauseButton.isVisible = true
            views.pauseButton.setTitle("暫停考試", for: .normal)
        }
    }
    
    private func indexChange(newIndex: Int) {
        views.questionIndicatorView.setCurrentPage(pageIndex: newIndex)
    }
    
    private func showExamResult(correctCount: Int, wrongCount: Int) {
        let message = "答對了\(correctCount)題\n答錯了\(wrongCount)題"
        let vc = UIAlertController(title: "答題結果", message: message, preferredStyle: .alert)
        if wrongCount > 0 {
            vc.addAction(.init(title: "重做錯題", style: .default, handler: { _ in
                self.sendInputEvent(.retakeExam)
                self.pagerView.scrollToItem(at: 0, animated: false)
            }))
        }
        vc.addAction(.init(title: "查看解答", style: .default, handler: { _ in
            self.sendInputEvent(.switchAnswerMode)
        }))
        vc.addAction(.init(title: "離開", style: .destructive, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(vc, animated: true)
    }
    
}

//MARK: - QuestionCardDelegate
extension EnglishExamViewController: QuestionCardDelegate {
    
    func onOptionSelected(question: EnglishExamQuestion, selectedOption: String?) {
        sendInputEvent(.onOptionSelected(question: question, selectedOption: selectedOption))
    }
    
}

//MARK: - FSPagerViewDelegate, FSPagerViewDataSource
extension EnglishExamViewController: FSPagerViewDelegate, FSPagerViewDataSource {
    
    func pagerViewDidEndDecelerating(_ pagerView: FSPagerView) {
        sendInputEvent(.currentIndexChange(currentIndex: pagerView.currentIndex))
    }
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return viewModel.questions.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        guard let cell = pagerView.dequeueReusableCell(withReuseIdentifier: EnglishExamViews.VocabularyExamQuestionCell.self.className, at: index) as? EnglishExamViews.VocabularyExamQuestionCell else {
            return FSPagerViewCell()
        }
        sendInputEvent(.currentIndexChange(currentIndex: index))
        cell.bindEnglishQuestion(question: viewModel.questions[index], isAnswerMode: viewModel.examState == .answerMode)
        cell.delegate = self
        return cell
    }
    
    
}
