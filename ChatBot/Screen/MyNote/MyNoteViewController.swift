//
//  MyNoteViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/9.
//

import UIKit

class MyNoteViewController: BaseUIViewController {
    
    private lazy var views = MyNoteViews(view: self.view)
    private let viewModel = MyNoteViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        viewModel.bind()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.transform(inputEvent: .fetchAllNote)
    }
    
    private func initUI() {
        views.tableView.delegate = self
        views.tableView.dataSource = self
        views.tableView.register(cellType: MyNoteViews.NoteCell.self)
    }
    
    private func bind() {
        viewModel.$myNotes
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let `self` = self else { return }
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
                }
            }
            .store(in: &subscriptions)
    }

}

//MARK: - UITableViewDataSource, UITabBarDelegate
extension MyNoteViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.myNotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: MyNoteViews.NoteCell.self, for: indexPath)
        cell.bindNote(note: viewModel.myNotes[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let myNote = viewModel.myNotes[indexPath.row]
        let vc = ScreenLoader.loadScreen(screen: .note(myNote: myNote))
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, view, completionHandler) in
            self.viewModel.transform(inputEvent: .deleteNote(indexPath: indexPath))
            completionHandler(true)
        }
        return .init(actions: [deleteAction])
    }
}

