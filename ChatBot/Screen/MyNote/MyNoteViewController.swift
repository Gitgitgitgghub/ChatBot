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
        if let attr = viewModel.myNotes[indexPath.row].attributedString() {
            let vc = ScreenLoader.loadScreen(screen: .HTMLEditor(attr: attr, delegate: self))
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
}

//TODO: - 事實上這邊不會打開編輯頁面，只是測試用
extension MyNoteViewController: HtmlEditorViewControllerDelegate {
    
    func didSaveAttributedString(attributedString: NSAttributedString) {
        let indexPath = IndexPath(row: 0, section: 0)
        if let new = try? MyNote(title: "更改過的", attributedString: attributedString) {
            viewModel.myNotes[indexPath.row] = new
            views.tableView.reloadData()
        }
    }
}
