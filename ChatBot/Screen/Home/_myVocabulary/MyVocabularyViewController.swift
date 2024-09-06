//
//  MyVocabularyViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation
import UIKit


class MyVocabularyViewController: BaseUIViewController {
    
    private let viewModel = MyVocabularyViewModel()
    private lazy var views = MyVocabularyViews(view: self.view)
    private var tableView: UITableView {
        return views.tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        initUI()
        viewModel.transform(inputEvent: .initialVocabulary)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.transform(inputEvent: .reloadExpandingSection)
    }
    
    private func initUI() {
        views.bottomToolBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: MyVocabularyViews.VocabularyCell.self)
        views.searchBar.delegate = self
        views.emptyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(emptyLabelClicked)))
    }
    
    private func bind() {
        viewModel.bindInputEvent()
        viewModel.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .reloadRows(indexPath: let indexPath):
                    self.tableView.reloadRows(at: indexPath, with: .automatic)
                case .reloadAll:
                    self.tableView.reloadData()
                case .reloadSections(sections: let sections):
                    self.tableView.reloadSections(.init(sections), with: .automatic)
                case .toast(message: let message):
                    self.showToast(message: message)
                case .setEmptyButtonVisible(isVisible: let isVisible):
                    self.views.emptyLabel.isVisible = isVisible
                    self.view.bringSubviewToFront(self.views.emptyLabel)
                case .wordNotFound(sggestion: let sggestion):
                    self.wordNotFound(sggestion: sggestion)
                }
            }
            .store(in: &subscriptions)
        viewModel.loadingStatus
            .sink { [weak self] status in
                self?.views.showLoadingView(status: status, with: "正在搜索中...")
            }
            .store(in: &subscriptions)
    }
    
    private func wordNotFound(sggestion: String?) {
        if let suggestion = sggestion {
            let alert = UIAlertController(title: "找不到該單字", message: "試試\(suggestion)?", preferredStyle: .alert)
            alert.addAction(.init(title: "確認", style: .default, handler: { _ in
                self.viewModel.transform(inputEvent: .fetchVocabularyModel(word: suggestion))
            }))
            alert.addAction(.init(title: "取消", style: .cancel))
            present(alert, animated: true)
        }else {
            showToast(message: "找不到該單字")
        }
    }
    
    @objc private func emptyLabelClicked(_ sender: UIGestureRecognizer) {
        viewModel.transform(inputEvent: .fetchVocabularyModel())
    }
    
    @objc private func toggleExpanding(sender: UITapGestureRecognizer) {
        guard let section = sender.view?.tag else { return }
        viewModel.transform(inputEvent: .toggleExpanding(section: section))
    }
}

//MARK: - UISearchBarDelegate
extension MyVocabularyViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.transform(inputEvent: .searchVocabularyDatabase(text: searchText))
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.transform(inputEvent: .searchVocabularyDatabase(text: ""))
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

//MARK: - UITableViewDataSource, UITableViewDelegate, VocabularyCellDelegate
extension MyVocabularyViewController: UITableViewDataSource, UITableViewDelegate, MyVocabularyViewDelegate {
    
    func onExamButtonClicked() {
        ExamQuestionSelectorViewController().show(in: self) { QuestionType in
            guard let QuestionType = QuestionType else { return }
            ScreenLoader.toScreen(screen: .englishExam(questionType: QuestionType, vocabularies: []), viewController: self)
        }
    }
    
    func onFlipCardButtonClicked() {
        ScreenLoader.toScreen(screen: .flipCard, viewController: self)
    }
    
    func onStarButtonClicked(indexPath: IndexPath) {
        viewModel.transform(inputEvent: .toggleStar(indexPath: indexPath))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch viewModel.displayMode {
        case .normalMode:
            return viewModel.sectionDatas.count
        case .searchMode:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.displayMode {
        case .normalMode:
            if let sectionData = viewModel.sectionDatas.getOrNil(index: section), sectionData.isExpanding {
                return sectionData.vocabularies.count
            }
            return 0
        case .searchMode:
            return viewModel.searchDatas.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: MyVocabularyViews.VocabularyCell.self, for: indexPath)
        cell.delegate = self
        switch viewModel.displayMode {
        case .normalMode:
            cell.bindVocabulary(indexPath: indexPath, vocabulary: viewModel.sectionDatas[indexPath.section].vocabularies[indexPath.row])
        case .searchMode:
            cell.bindVocabulary(indexPath: indexPath, vocabulary: viewModel.searchDatas[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        var vocabularies: [VocabularyModel]
        switch viewModel.displayMode {
        case .normalMode:
            vocabularies = viewModel.sectionDatas[indexPath.section].vocabularies
        case .searchMode:
            vocabularies = viewModel.searchDatas
        }
        let index = indexPath.row
        let vc = ScreenLoader.loadScreen(screen: .vocabulary(vocabularies: vocabularies, startIndex: index))
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionData = viewModel.sectionDatas.getOrNil(index: section), viewModel.displayMode == .normalMode {
            let header = MyVocabularyViews.HeaderView()
            header.tag = section
            header.setSectionData(sectionModel: sectionData)
            header.isUserInteractionEnabled = true
            header.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleExpanding(sender:))))
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.displayMode == .normalMode ? 44 : .zero
    }
    
}
