//
//  FlipCardViewContoller.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/20.
//

import Foundation


class FlipCardViewContoller: BaseUIViewController {
    
    private let viewModel = FlipCardViewModel()
    private lazy var views = FlipCardViews(view: self.view)
    private var pagerView: FSPagerView {
        return views.pagerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
        viewModel.transform(inputEvent: .fetchVocabularies)
    }
    
    private func initUI() {
        views.pagerView.delegate = self
        views.pagerView.dataSource = self
        views.pagerView.register(FlipCardViews.CardContentCell.self, forCellWithReuseIdentifier: FlipCardViews.CardContentCell.className)
    }
    
    private func bind() {
        viewModel.bindInputEvent()
        viewModel.$vocabularies
            .sink { [weak self] _ in
                self?.pagerView.reloadData()
            }
            .store(in: &subscriptions)
        viewModel.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .flipCard(index: let index):
                    self.flipCard(index: index)
                }
            }
            .store(in: &subscriptions)
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
        cell.bindVocabulary(vocabulary: viewModel.vocabularies[index], index: index, total: viewModel.vocabularies.count, isFlipped: false)
        return cell
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        viewModel.transform(inputEvent: .flipCard(index: index))
    }
    
}