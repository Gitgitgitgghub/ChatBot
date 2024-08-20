//
//  HistoryViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/3.
//

import Foundation
import UIKit

class HistoryViewController: BaseUIViewController {
    
    lazy var views = HistoryViews(view: self.view)
    let viewModel = HistoryViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        viewModel.bind()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.transform(inputEvent: .fetchChatRooms)
    }
    
    private func initUI() {
        views.tableView.delegate = self
        views.tableView.dataSource = self
        views.tableView.register(cellType: HistoryViews.ChatRoomCell.self)
        views.editButton.addTarget(self, action: #selector(editButtonClicked), for: .touchUpInside)
    }
    
    /// 綁定各種事件
    private func bind() {
        viewModel.$chatRooms
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { [weak self] chatRooms in
                guard let `self` = self else { return }
                self.views.tableView.reloadData()
            }
            .store(in: &subscriptions)
        viewModel.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .toast(let message, _):
                    self.showToast(message: message, autoDismiss: 1.5)
                }
            }
            .store(in: &subscriptions)
    }
    
    @objc private func editButtonClicked() {
        let vc = UIAlertController(title: "你想要？", message: nil, preferredStyle: .actionSheet)
        vc.addAction(.init(title: "刪除所有聊天記錄", style: .default, handler: { action in
            self.viewModel.transform(inputEvent: .deleteAllChatRoom)
        }))
        vc.addAction(.init(title: "取消", style: .cancel))
        present(vc, animated: true)
    }
    
    
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: HistoryViews.ChatRoomCell.self, for: indexPath)
        guard let chatRoom = viewModel.chatRooms.getOrNil(index: indexPath.row) else { return cell }
        cell.bindChatRoom(chatRoom: chatRoom)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let chatRoom = viewModel.chatRooms.getOrNil(index: indexPath.row) else { return }
        let vc = ScreenLoader.loadScreen(screen: .chat(lauchModel: .chatRoom(chatRoom: chatRoom)))
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, view, completionHandler) in
            self.viewModel.transform(inputEvent: .deleteChatRoom(indexPath: indexPath))
            completionHandler(true)
        }
        return .init(actions: [deleteAction])
    }
}
