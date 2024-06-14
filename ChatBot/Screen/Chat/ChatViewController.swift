//
//  ChatViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/11.
//

import UIKit
import SnapKit
import Combine

class ChatViewController: UIViewController {
    
    
    
    private let viewModel = ChatViewModel(openai: OpenAIService())
    private lazy var views = ChatViews(view: self.view)
    private var cancellables = Set<AnyCancellable>()
    private var requestCountSubscriber: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
    }
    
    private func initUI() {
        views.messageTableView.delegate = self
        views.messageTableView.dataSource = self
        views.messageTableView.register(cellType: ChatViews.MessageCell.self)
        views.messageInputTextField.delegate = self
    }
    
    private func bind() {
        viewModel.bindInput()
        viewModel.messages
            .sink { [weak self] messages in
                self?.views.messageTableView.reloadData()
            }
            .store(in: &cancellables)
        requestCountSubscriber = viewModel.requestCount
            .map{ "request count: \($0)" }
            .assign(to: \.text, on: views.requestCountLabel)
    }

    deinit {
        requestCountSubscriber?.cancel()
    }
}

extension ChatViewController:  UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messagesSubject.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: ChatViews.MessageCell.self, for: indexPath)
        cell.bindMessage(message: viewModel.messagesSubject.value[indexPath.row])
        return cell
    }
}

extension ChatViewController: UITextFieldDelegate {
    

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        if let message = textField.text {
            viewModel.transform(inputEvent: .sendMessage(message: message))
        }
        return true
    }
    
}

