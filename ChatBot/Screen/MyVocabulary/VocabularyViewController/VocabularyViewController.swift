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
    }
    
    private func bind() {
        viewModel.bindInput()
        viewModel.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .scrollTo(index: let index):
                    self.pagerView.reloadData()
                    self.pagerView.scrollToItem(at: index, animated: false)
                case .toast(message: let message):
                    self.showToast(message: message)
                case .reloadCurrentIndex:
                    self.pagerView.reloadData()
                }
            }
            .store(in: &subscriptions)
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
        print("cellForItemAt: \(index)")
        viewModel.transform(inputEvent: .currentIndexPathChange(index: index))
        return cell
    }
    
    func pagerView(_ pagerView: FSPagerView, willDisplay cell: FSPagerViewCell, forItemAt index: Int) {
        print("willDisplay: \(index)")
    }
}
