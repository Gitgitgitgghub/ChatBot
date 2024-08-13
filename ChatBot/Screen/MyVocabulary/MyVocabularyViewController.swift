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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.transform(inputEvent: .fetchVocabularys)
    }
    
    private func initUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: MyVocabularyViews.VocabularyCell.self)
        //tableView.register(MyVocabularyViews.HeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
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
                case .reloadSection(section: let section):
                    self.tableView.reloadSections(.init(integer: section), with: .automatic)
                case .toast(message: let message):
                    self.showToast(message: message)
                }
            }
            .store(in: &subscriptions)
    }
    
    @objc private func toggleExpanding(sender: UITapGestureRecognizer) {
        guard let section = sender.view?.tag else { return }
        viewModel.transform(inputEvent: .toggleExpanding(section: section))
    }
}

//MARK: - UITableViewDataSource, UITableViewDelegate, VocabularyCellDelegate
extension MyVocabularyViewController: UITableViewDataSource, UITableViewDelegate, VocabularyCellDelegate {
    
    func onSpeakButtonClicked(indexPath: IndexPath) {
        viewModel.transform(inputEvent: .speakWord(indexPath: indexPath))
    }
    
    func onStarButtonClicked(indexPath: IndexPath) {
        viewModel.transform(inputEvent: .toggleStar(indexPath: indexPath))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionDatas.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionData = viewModel.sectionDatas.getOrNil(index: section), sectionData.isExpanding {
            return sectionData.vocabularys.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: MyVocabularyViews.VocabularyCell.self, for: indexPath)
        cell.bindVocabulary(indexPath: indexPath, vocabulary: viewModel.sectionDatas[indexPath.section].vocabularys[indexPath.row])
        cell.delegate = self
        return cell
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if let sectionData = viewModel.sectionDatas.getOrNil(index: section) {
//            let header = MyVocabularyViews.HeaderView()
//            return sectionData.title
//        }
//        return nil
//    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionData = viewModel.sectionDatas.getOrNil(index: section) {
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
        return 44
    }
    
}
