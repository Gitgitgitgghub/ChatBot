//
//  NoteViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/22.
//

import Foundation
import UIKit
import GRDB
  

class NoteViewController: BaseUIViewController {
    
    private(set) var myNote: MyNote
    private lazy var viewModel = NoteViewModel(myNote: self.myNote)
    private lazy var views = NoteViews(view: self.view)
    
    init(myNote: MyNote) {
        self.myNote = myNote
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
    }
    
    private func initUI() {
        views.tableView.delegate = self
        views.tableView.dataSource = self
        views.tableView.register(cellType: NoteViews.NoteCell.self)
        views.addCommentButton.addTarget(self, action: #selector(addComment), for: .touchUpInside)
    }
    
    @objc private func addComment() {
        viewModel.transform(inputEvent: .addComment)
        let vc = ScreenLoader.loadScreen(screen: .HTMLEditor(attr: nil, delegate: self))
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    private func bind() {
        viewModel.bind()
        viewModel.$myNote
            .receive(on: RunLoop.main)
            .sink { [weak self] myNote in
                guard let `self` = self else { return }
                self.title = myNote.title
                self.views.tableView.reloadData()
            }
            .store(in: &subscriptions)
        viewModel.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .toast(message: let message, reload: let reload):
                    self.showToast(message: message)
                    if reload {
                        self.views.tableView.reloadData()
                    }
                }
            }
            .store(in: &subscriptions)
    }
}

extension NoteViewController: HtmlEditorViewControllerDelegate {
    
    func didSaveAttributedString(attributedString: NSAttributedString) {
        viewModel.transform(inputEvent: .modifyNote(content: attributedString))
    }
    
}

//MARK: - UITableViewDataSource, UITabBarDelegate
extension NoteViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.sections[section] {
        case .note:
            return 1
        case .comment:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: NoteViews.NoteCell.self, for: indexPath)
        cell.bindNote(note: viewModel.myNote)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch viewModel.sections[indexPath.section] {
        case .note:
            guard let attr = viewModel.myNote.attributedString() else { return }
            viewModel.transform(inputEvent: .editNote)
            let vc = ScreenLoader.loadScreen(screen: .HTMLEditor(attr: attr, delegate: self))
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        case .comment:
            break
        }
    }
    
    
}
