//
//  VocabularyViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/13.
//

import Foundation
import UIKit

class VocabularyViewController: BaseUIViewController {

    private let viewModel: VocabularyViewModel
    private lazy var views = VocabularyViews(view: self.view)
    private var pagerView: FSPagerView {
        return views.pagerView
    }
    
    init(vocabularies: [VocabularyModel], startIndex: Int) {
        self.viewModel = .init(vocabularies: vocabularies, startIndex: startIndex, openAI: VocabularyService())
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
        viewModel.transform(inputEvent: .initialVocabularies)
    }
    
    private func initUI() {
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.collectionView.prefetchDataSource = self
        pagerView.collectionView.isPrefetchingEnabled = true
        pagerView.register(VocabularyViews.VocabularyPagerViewCell.self, forCellWithReuseIdentifier: VocabularyViews.VocabularyPagerViewCell.className)
        views.starButton.addTarget(self, action: #selector(starButtonClicked), for: .touchUpInside)
        views.moreButton.addTarget(self, action: #selector(moreButtonClicked), for: .touchUpInside)
    }
    
    @objc private func starButtonClicked() {
        viewModel.transform(inputEvent: .toggleStar(index: pagerView.currentIndex))
    }
    
    @objc private func moreButtonClicked() {
        viewModel.transform(inputEvent: .fetchMoreSentence(index: pagerView.currentIndex))
    }
    
    private func bind() {
        viewModel.bindInput()
        viewModel.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .toast(message: let message):
                    self.showToast(message: message)
                case .changeTitle(title: let title):
                    self.title = title
                case .updateStar(isStar: let isStar):
                    self.updateStar(isStar: isStar)
                case .reloadUI(scrollTo: let scrollTo, isStar: let isStar):
                    self.updateUI(scrollTo: scrollTo, isStar: isStar)
                }
            }
            .store(in: &subscriptions)
        viewModel.loadingStatus
            .sink { [weak self] status in
                self?.views.showLoadingView(status: status, with: "讀取中...")
            }
            .store(in: &subscriptions)
    }
    
    private func updateStar(isStar: Bool) {
        self.views.starButton.isSelected = isStar
    }
    
    private func updateUI(scrollTo: Int? = nil, isStar: Bool) {
        self.pagerView.reloadData()
        updateStar(isStar: isStar)
        if let scrollTo = scrollTo {
            self.pagerView.scrollToItem(at: scrollTo, animated: false)
        }
    }
    
}

//MARK: FSPagerViewDelegate, FSPagerViewDataSource
extension VocabularyViewController: FSPagerViewDelegate, FSPagerViewDataSource, UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let index = indexPaths.last?.item else { return }
        viewModel.transform(inputEvent: .fetchVocabularies(index: index))
    }
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return viewModel.displayEnable ? viewModel.vocabularies.count : 0
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: VocabularyViews.VocabularyPagerViewCell.className, at: index) as! VocabularyViews.VocabularyPagerViewCell
        cell.bindVocabulary(vocabulary: viewModel.vocabularies[index])
        return cell
    }
    
    func pagerViewDidEndDecelerating(_ pagerView: FSPagerView) {
        viewModel.transform(inputEvent: .currentIndexChange(index: pagerView.currentIndex))
    }
}
