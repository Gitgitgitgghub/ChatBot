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
        views.tableView.register(cellType: NoteViews.CommentCell.self)
        views.addCommentButton.addTarget(self, action: #selector(addComment), for: .touchUpInside)
        let dotItem = UIBarButtonItem(image: .init(systemName: "ellipsis"), style: .plain, target: self, action: #selector(rightItemButtonClick))
        navigationItem.rightBarButtonItem = dotItem
    }
    
    /// 點navigationBar右上方的點點
    @objc private func rightItemButtonClick() {
        let vc = UIAlertController(title: "你想要？", message: nil, preferredStyle: .actionSheet)
        vc.addAction(.init(title: "刪除筆記", style: .default, handler: { action in
            self.viewModel.transform(inputEvent: .deleteNote)
        }))
        vc.addAction(.init(title: "取消", style: .cancel))
        present(vc, animated: true)
    }
    
    @objc private func addComment() {
        viewModel.transform(inputEvent: .addComment)
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
                case .openEditor(editData: let editData, isNote: let isEditNote, useHtmlEdotir: let useHtmlEdotir):
                    self.openEditorVc(isHtml: useHtmlEdotir, editData: editData, isEditNote: isEditNote)
                case .deleteNoteSuccess:
                    self.showToast(message: "刪除成功，１秒後反回上一頁", autoDismiss: 1) { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                case .deleteCommentSuccess:
                    self.showToast(message: "刪除筆記成功", autoDismiss: 1)
                    self.views.tableView.reloadSections(.init(integer: 1), with: .automatic)
                }
            }
            .store(in: &subscriptions)
    }
    
    /// 開啟編輯畫面
    private func openEditorVc(isHtml: Bool, editData: Data?, isEditNote: Bool) {
        if isHtml {
            let vc = ScreenLoader.loadScreen(screen: .HTMLEditor(content: editData, inputBackgroundColor:  SystemDefine.Message.aiMgsBackgroundColor, completion: { [weak self] result in
                self?.viewModel.transform(inputEvent: .modifyNote(attr: result))
            }))
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }else {
            let vc = ScreenLoader.loadScreen(screen: .textEditor(content: editData, inputBackgroundColor:  SystemDefine.Message.userMgsBackgroundColor, delegate: self))
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

//MARK: - 處理編輯器點選儲存
extension NoteViewController: TextEditorViewControllerDelegate {
    
    func onSave(title: String?, attributedString: NSAttributedString?) {
        viewModel.transform(inputEvent: .modifyNote(attr: attributedString))
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
            return viewModel.myNote.comments.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.sections[indexPath.section] {
        case .note:
            let cell = tableView.dequeueReusableCell(with: NoteViews.NoteCell.self, for: indexPath)
            cell.bindNote(note: viewModel.myNote)
            cell.noteCellDelegate = self
            return cell
        case .comment:
            let cell = tableView.dequeueReusableCell(with: NoteViews.CommentCell.self, for: indexPath)
            cell.bindComment(comment: viewModel.myNote.comments[indexPath.row])
            cell.noteCellDelegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch viewModel.sections[indexPath.section] {
        case .note:
            viewModel.transform(inputEvent: .editNote)
        case .comment:
            viewModel.transform(inputEvent: .editComment(indexPath: indexPath))
        }
    }
    
    /// 側滑動作，目前只開放comment刪除
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch viewModel.sections[indexPath.section] {
        case .note:
            return nil
        case .comment:
            let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, view, completionHandler) in
                self.viewModel.transform(inputEvent: .deleteComment(indexPath: indexPath))
                completionHandler(true)
            }
            return .init(actions: [deleteAction])
        }
    }
    
}

extension NoteViewController: NoteCellDelegate {
    
    func layoutDidChanged() {
        
    }
    
    
}
