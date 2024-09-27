//
//  MyNoteViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/9.
//

import UIKit

class MyNoteViewController: BaseUIViewController<MyNoteViewModel> {
    
    private lazy var views = MyNoteViews(view: self.view)

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sendInputEvent(.fetchAllNote)
    }
    
    private func initUI() {
        views.tableView.delegate = self
        views.tableView.dataSource = self
        views.tableView.register(cellType: MyNoteViews.NoteCell.self)
        views.addNoteButton.addTarget(self, action: #selector(addNote), for: .touchUpInside)
    }
    
    override func handleOutputEvent(_ outputEvent: MyNoteViewModel.OutputEvent) {
        switch outputEvent {
        case .toast(message: let message, reload: _):
            self.showToast(message: message)
        }
    }
    
    private func bind() {
        viewModel.$myNotes
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.views.tableView.reloadData()
            }
            .store(in: &subscriptions)
    }
    
    @objc private func addNote() {
        let vc = ScreenLoader.loadScreen(screen: .textEditor(content: nil, inputBackgroundColor: .systemBlue, delegate: self))
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension MyNoteViewController: TextEditorViewControllerDelegate {
    
    func onSave(title: String?, attributedString: NSAttributedString?) {
        sendInputEvent(.addNote(title: title, attributedString: attributedString))
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
            self.sendInputEvent(.deleteNote(indexPath: indexPath))
            completionHandler(true)
        }
        return .init(actions: [deleteAction])
    }
}

