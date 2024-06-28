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
    private var updatePublisher: PassthroughSubject<Void, Never> = PassthroughSubject()
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
        observeKeyboard()
        setupMessageTableViewUpdatePublisher()
    }
    
    private func initUI() {
        views.messageTableView.delegate = self
        views.messageTableView.dataSource = self
        views.messageTableView.register(cellType: ChatViews.UserMessageCell.self)
        views.messageTableView.register(cellType: ChatViews.AIMessageCell.self)
        views.chatInputView.messageInputTextField.delegate = self
        views.messageTableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            .apply { obj in
                obj.cancelsTouchesInView = false
            })
        views.chatInputView.functionButton.addTarget(self, action: #selector(openUploadImageSelectorVc), for: .touchUpInside)
        views.chatInputView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
    }
    
    private func setupMessageTableViewUpdatePublisher() {
        updatePublisher
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let `self` = self else { return }
                if let indexs = self.views.messageTableView.indexPathsForVisibleRows {
                    //self.views.messageTableView.reloadRows(at: indexs, with: .none)
                }
            }
            .store(in: &subscriptions)
    }
    
    /// 觀察鍵盤顯示與否
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /// 執行一些綁定動作
    private func bind() {
        _ = viewModel.bindInput()
        viewModel.$displayMessages
            .receive(on: RunLoop.main)
            .sink { [weak self] messages in
                guard let `self` = self, !messages.isEmpty else { return }
                self.views.messageTableView.reloadData()
                //滾動到最下方
                guard let lastIndex = self.views.messageTableView.indexPathsForVisibleRows?.last else { return }
                self.views.messageTableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
            }
            .store(in: &subscriptions)
        viewModel.$inputMessage
            .eraseToAnyPublisher()
            .assign(to: \.text, on: views.chatInputView.messageInputTextField)
            .store(in: &subscriptions)
        viewModel.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .imageDownloadComplete:
                    self.imageDownloadComplete()
                }
            }
            .store(in: &subscriptions)
        //viewModel.mock()
    }
    
    /// 處理圖片下載完成事件
    private func imageDownloadComplete() {
        updatePublisher.send(())
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
extension ChatViewController:  UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = viewModel.displayMessages.getOrNil(index: indexPath.row)?.estimatedHeightForAttributedString ?? 0
        if height == 0 {
            return UITableView.automaticDimension
        }
        //+20是因為textView在cell有padding上下１０
        height += 20
        //print("使用緩存高度 row:\(indexPath.row)  height: \(height)")
        return height
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.originalMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("tableView cellForRowAt \(indexPath)  已加載數量：\(viewModel.displayMessages.count)")
        //執行預加載動作
        viewModel.transform(inputEvent: .preloadAttributedString(currentIndex: indexPath.row))
        let message = viewModel.displayMessages.getOrNil(index: indexPath.row)
        switch message?.messageType {
        case .message, .mock:
            let message = message!
            switch message.sender {
            case .user:
                let cell = tableView.dequeueReusableCell(with: ChatViews.UserMessageCell.self, for: indexPath)
                cell.bindMessage(messageModel: message, indexPath: indexPath)
                return cell
            case .ai, .system:
                let cell = tableView.dequeueReusableCell(with: ChatViews.AIMessageCell.self, for: indexPath)
                cell.bindMessage(messageModel: message, indexPath: indexPath)
                return cell
            }
        case .none:
            let cell = tableView.dequeueReusableCell(with: ChatViews.AIMessageCell.self, for: indexPath)
            cell.setLoading(indexPath: indexPath)
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

