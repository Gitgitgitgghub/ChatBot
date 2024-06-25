//
//  ChatViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/11.
//

import UIKit
import SnapKit
import Combine

class ChatViewController: BaseUIViewController {
    
    
    private let viewModel = ChatViewModel(openai: OpenAIService())
    private lazy var views = ChatViews(view: self.view)
    private let loadingView = LoadingView()
    /// tableVIew是否正在滾動
    private var isScrolling = false
    /// 是否該更新tableView
    private var shouldUpdateTable = false
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
        observeKeyboard()
    }
    
    private func initUI() {
        views.messageTableView.delegate = self
        views.messageTableView.dataSource = self
        views.messageTableView.estimatedRowHeight = 50
        views.messageTableView.rowHeight = UITableView.automaticDimension
        views.messageTableView.register(cellType: ChatViews.UserMessageCell.self)
        views.messageTableView.register(cellType: ChatViews.SystemMessageCell.self)
        views.chatInputView.messageInputTextField.delegate = self
        views.messageTableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            .apply { obj in
                obj.cancelsTouchesInView = false
            })
        views.chatInputView.functionButton.addTarget(self, action: #selector(openUploadImageSelectorVc), for: .touchUpInside)
        views.chatInputView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
    }
    
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func bind() {
        _ = viewModel.bindInput()
        viewModel.$messages
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.views.messageTableView.reloadData()
            }
            .store(in: &subscriptions)
        viewModel.$inputMessage
            .eraseToAnyPublisher()
            .assign(to: \.text, on: views.chatInputView.messageInputTextField)
            .store(in: &subscriptions)
        viewModel.mock()
    }
    
    //MARK: - objc
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardShow(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        views.textFieldDidBeginEditing(keyboardHeight: keyboardHeight)
    }
    
    @objc private func keyboardHide(_ notification: Notification) {
        views.textFieldDidEndEditing()
    }
    
    @objc private func openUploadImageSelectorVc() {
        present(UploadImageSelectorViewController(title: "請選擇一種圖片上傳方式", message: "我們絕對會用來做違法使用", preferredStyle: .actionSheet)
            .apply({ vc in
                vc.delegate = self
            }), animated: true)
    }
    
    @objc private func sendMessage() {
        //viewModel.transform(inputEvent: .createImage)
        dismissKeyboard()
        //viewModel.transform(inputEvent: .editImage)
        viewModel.transform(inputEvent: .sendMessage)
    }
    
}

//MARK: - 用戶選擇照片上傳方式處理相關
extension ChatViewController: UploadImageSelectorViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func userSeletedCamara() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            present(imagePickerController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Camera Not Available", message: "Sorry, your device doesn't support camera", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func userSeletedPhotoLibrary() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        viewModel.pickedImageInfo = info
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
}

//MARK: - UITableViewDelegate, UITableViewDataSource, MessageCellProtocol
extension ChatViewController:  UITableViewDelegate, UITableViewDataSource, MessageCellProtocol {
    
    func cellHeighChange() {
        if isScrolling {
            shouldUpdateTable = true
        } else {
            views.messageTableView.performBatchUpdates(nil)
        }
    }
    
    // UIScrollViewDelegate methods
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
        shouldUpdateTable = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
            if shouldUpdateTable {
                views.messageTableView.performBatchUpdates(nil)
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = viewModel.messages[indexPath.row]
        print("tableView cellForRowAt \(indexPath)")
        switch result {
        case .userChatQuery(message: _):
            let cell = tableView.dequeueReusableCell(with: ChatViews.UserMessageCell.self, for: indexPath)
            cell.bindResult(result: result)
            cell.messageCellProtocol = self
            return cell
        case .chatResult(data: _):
            let cell = tableView.dequeueReusableCell(with: ChatViews.SystemMessageCell.self, for: indexPath)
            cell.bindResult(result: result)
            cell.messageCellProtocol = self
            return cell
        case .imageResult(prompt: _, data: _):
            let cell = tableView.dequeueReusableCell(with: ChatViews.SystemMessageCell.self, for: indexPath)
            cell.bindResult(result: result)
            return cell
        case .imageEditResult(prompt: _, data: _):
            let cell = tableView.dequeueReusableCell(with: ChatViews.SystemMessageCell.self, for: indexPath)
            cell.bindResult(result: result)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

//MARK: - UITextViewDelegate
extension ChatViewController: UITextViewDelegate {
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if textView.text?.isEmpty ?? true {
            view.endEditing(true)
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        viewModel.inputMessage = textView.text
    }
    
}

