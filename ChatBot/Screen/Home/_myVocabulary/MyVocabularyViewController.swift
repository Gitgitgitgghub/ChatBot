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
            return sectionData.vocabularies.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: MyVocabularyViews.VocabularyCell.self, for: indexPath)
        cell.bindVocabulary(indexPath: indexPath, vocabulary: viewModel.sectionDatas[indexPath.section].vocabularies[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let vocabularies = viewModel.sectionDatas[indexPath.section].vocabularies
        let index = indexPath.row
        let vc = ScreenLoader.loadScreen(screen: .vocabulary(vocabularies: vocabularies, startIndex: index))
        navigationController?.pushViewController(vc, animated: true)
    }
    
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
