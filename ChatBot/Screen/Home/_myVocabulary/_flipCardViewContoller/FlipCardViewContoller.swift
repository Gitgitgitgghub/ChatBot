//
//  FlipCardViewContoller.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/20.
//

import Foundation


class FlipCardViewContoller: BaseUIViewController<FlipCardViewModel> {
    
    private lazy var views = FlipCardViews(view: self.view)
    private var pagerView: FSPagerView {
        return views.pagerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
        sendInputEvent(.fetchVocabularies)
    }
    
    private func initUI() {
        title = "翻卡練習"
        views.pagerView.delegate = self
        views.pagerView.dataSource = self
        views.pagerView.register(FlipCardViews.CardContentCell.self, forCellWithReuseIdentifier: FlipCardViews.CardContentCell.className)
        views.flipCardButton.addTarget(self, action: #selector(flipCardButtonClicked), for: .touchUpInside)
        views.examButton.addTarget(self, action: #selector(examButtonClicked), for: .touchUpInside)
    }
    
    private func bind() {
        viewModel.$vocabularies
            .sink { [weak self] _ in
                self?.pagerView.reloadData()
            }
            .store(in: &subscriptions)
    }
    
    override func handleOutputEvent(_ outputEvent: FlipCardViewModel.OutputEvent) {
        switch outputEvent {
        case .flipCard(index: let index):
            self.flipCard(index: index)
        case .toast(message: let message):
            self.showToast(message: message)
        case .reloadCurrent:
            self.pagerView.reloadData()
        }
    }
    
    @objc private func examButtonClicked() {
        ExamQuestionSelectorViewController(selectorComponent: [.questionTypeSelector]).show(in: self) { QuestionType in
            guard let QuestionType = QuestionType else { return }
            ScreenLoader.toScreen(screen: .englishExam(questionType: QuestionType, vocabularies: self.viewModel.vocabularies), viewController: self)
        }
    }
    
    @objc private func flipCardButtonClicked() {
        sendInputEvent(.flipCard(index: pagerView.currentIndex))
    }
    
    private func flipCard(index: Int) {
        guard let cell = pagerView.cellForItem(at: index) as? FlipCardViews.CardContentCell else { return }
        cell.flipCardView(isFlipped: viewModel.flippedStates[index] ?? false)
    }
    
}

//MARK: - FSPagerViewDelegate, FSPagerViewDataSource
extension FlipCardViewContoller: FSPagerViewDelegate, FSPagerViewDataSource {

    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return viewModel.vocabularies.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        guard let cell = pagerView.dequeueReusableCell(withReuseIdentifier: FlipCardViews.CardContentCell.className, at: index) as? FlipCardViews.CardContentCell else { return FSPagerViewCell() }
        cell.bindVocabulary(vocabulary: viewModel.vocabularies[index], index: index, total: viewModel.vocabularies.count, isFlipped: viewModel.flippedStates[index] ?? false)
        cell.delegate = self
        sendInputEvent(.currentPageChange(index: index))
        return cell
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        sendInputEvent(.flipCard(index: index))
    }
    
}

extension FlipCardViewContoller: FlipCardViewsDelegate {
    
    func onClickStar(index: Int) {
        sendInputEvent(.toggleStar(index: index))
    }
    
    
}
