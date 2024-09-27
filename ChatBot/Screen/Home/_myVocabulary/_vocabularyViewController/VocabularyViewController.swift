//
//  VocabularyViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/13.
//

import Foundation
import UIKit

class VocabularyViewController: BaseUIViewController<VocabularyViewModel> {

   
    private lazy var views = VocabularyViews(view: self.view)
    private var pagerView: FSPagerView {
        return views.pagerView
    }
    
    init(vocabularies: [VocabularyModel], startIndex: Int) {
        super.init(viewModel: .init(vocabularies: vocabularies, startIndex: startIndex))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        sendInputEvent(.initialVocabularies)
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
        sendInputEvent(.toggleStar(index: pagerView.currentIndex))
    }
    
    @objc private func moreButtonClicked() {
        sendInputEvent(.fetchMoreSentence(index: pagerView.currentIndex))
    }
    
    override func handleOutputEvent(_ outputEvent: VocabularyViewModel.OutputEvent) {
        switch outputEvent {
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
    
    override func onLoadingStatusChanged(status: LoadingStatus) {
        views.showLoadingView(status: status, with: "讀取中...")
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
        sendInputEvent(.fetchVocabularies(index: index))
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
        sendInputEvent(.currentIndexChange(index: pagerView.currentIndex))
    }
}
