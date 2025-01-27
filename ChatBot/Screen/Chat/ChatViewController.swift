//
//  ChatViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/11.
//

import UIKit
import SnapKit
import Combine
import AVFAudio
import NVActivityIndicatorView

class ChatViewController: BaseUIViewController<ChatViewModel> {
    
    
    private lazy var views = ChatViews(view: self.view)
    private var updatePublisher: PassthroughSubject<Void, Never> = PassthroughSubject()
    private let synthesizer = AVSpeechSynthesizer()
    
    init(chatLaunchMode: ChatLaunchMode) {
        super.init(viewModel: ChatViewModel(service: AIServiceManager.shared.service, chatLaunchMode: chatLaunchMode))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// 啟動模式
    enum ChatLaunchMode {
        /// 普通
        case normal
        /// 聊天室
        case chatRoom(chatRoom: ChatRoom)
        /// 附帶prompt
        case prompt(title: String, prompt: String)
        
        var title: String {
            switch self {
            case .normal:
                return "聊天"
            case .chatRoom(_):
                return "聊天室"
            case .prompt(let title, _):
                return title
            }
        }
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
        views.messageTableView.register(cellType: ChatViews.SystemMessageCell.self)
        views.chatInputView.messageInputTextField.delegate = self
        views.messageTableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            .apply { obj in
                obj.cancelsTouchesInView = false
            })
        views.chatInputView.functionButton.addTarget(self, action: #selector(openUploadImageSelectorVc), for: .touchUpInside)
        views.chatInputView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        let dotItem = UIBarButtonItem(image: .init(systemName: "ellipsis"), style: .plain, target: self, action: #selector(rightItemButtonClick))
        navigationItem.rightBarButtonItem = dotItem
    }
    
    /// 目前沒用到
    private func setupMessageTableViewUpdatePublisher() {
//        updatePublisher
//            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
//            .sink { [weak self] in
//                guard let `self` = self else { return }
//                if let indexs = self.views.messageTableView.indexPathsForVisibleRows {
//                    //self.views.messageTableView.reloadRows(at: indexs, with: .none)
//                }
//            }
//            .store(in: &subscriptions)
    }
    
    /// 執行一些綁定動作
    private func bind() {
        // 綁定要顯示的訊息
        viewModel.$displayMessages
            .receive(on: RunLoop.main)
            .sink { [weak self] messages in
                guard let `self` = self, !messages.isEmpty else { return }
                self.views.messageTableView.reloadData()
                //滾動到最下方
                delay(delay: 0.5) {
                    self.views.messageTableView.scrollToRow(at: .init(row: self.viewModel.displayMessages.count - 1, section: 0), at: .bottom, animated: false)
                }
            }
            .store(in: &subscriptions)
        // TextField 綁定
        viewModel.$inputMessage
            .eraseToAnyPublisher()
            .assign(to: \.text, on: views.chatInputView.messageInputTextField)
            .store(in: &subscriptions)
        /// 綁定launchMode變化
        viewModel.$chatLaunchMode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                self?.title = mode.title
            }
            .store(in: &subscriptions)
    }
    
    override func handleOutputEvent(_ outputEvent: ChatViewModel.OutPutEvent) {
        switch outputEvent {
        case .parseComplete(indexs: let indexs):
            self.parseCompletiom(indexs: indexs)
        case .saveChatMessageSuccess:
            self.saveChatMessageComplettion()
        case .saveChatMessageError(error: let error):
            self.saveChatMessageComplettion(error: error)
        }
    }
    
    override func onLoadingStatusChanged(status: LoadingStatus) {
        views.showLoadingView(status: status)
        switch status {
        case .error(error: let error):
            handleError(error: error)
        default:break
        }
    }
    
    private func handleError(error: Error) {
        let vc = UIAlertController(title: "發生錯誤", message: error.localizedDescription, preferredStyle: .alert)
        vc.addAction(.init(title: "重新發送", style: .default, handler: { action in
            self.sendInputEvent(.retrySendMessage)
        }))
        vc.addAction(.init(title: "取消", style: .cancel))
        present(vc, animated: true)
    }
    
    /// 處理保存訊息後的顯示事件
    private func saveChatMessageComplettion(error: Error? = nil) {
        let message: String = error == nil ? "保存成功" : "保存失敗\n\(error!.localizedDescription)"
        showToast(message: message, autoDismiss: 1.5, completion: nil)
    }
    
    /// 處理預載完成事件
    private func parseCompletiom(indexs: [IndexPath]) {
        let visibleRows = views.messageTableView.indexPathsForVisibleRows
        guard !(visibleRows?.isEmpty ?? true) && !indexs.isEmpty else { return }
        //let needUpdateIndex = visibleRows!.commonElements(with: indexs)
        UIView.performWithoutAnimation {
            /// 先用全部刷新 用visibleRow時好像容易漏更新
            views.messageTableView.reloadData()
            //views.messageTableView.reloadRows(at: needUpdateIndex, with: .none)
        }
    }
    
    /// 請求背景預加載
    private func requestPreload() {
        guard let visibleRows = views.messageTableView.indexPathsForVisibleRows, !visibleRows.isEmpty else { return }
        sendInputEvent(.preloadAttributedString(currentIndex: visibleRows.first!.row))
    }
    
    /// 顯示儲存筆記輸入title的alertVC
    private func showNoteTitleInputView(completion: @escaping (_ noteTitle: String?) -> ()) {
        let vc = UIAlertController(title: "儲存筆記", message: "請輸入標題", preferredStyle: .alert)
        vc.addTextField { textField in
            textField.text = "我的筆記"
        }
        vc.addAction(.init(title: "保存", style: .default, handler: { action in
            completion(vc.textFields?.first?.text)
        }))
        vc.addAction(.init(title: "取消", style: .cancel))
        present(vc, animated: true)
    }
    
    //MARK: - objc
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc override func keyboardShow(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        views.textFieldDidBeginEditing(keyboardHeight: keyboardHeight)
    }
    
    @objc override func keyboardHide(_ notification: Notification) {
        views.textFieldDidEndEditing()
    }
    
    @objc private func openUploadImageSelectorVc() {
        present(UploadImageSelectorViewController(title: "請選擇一種圖片上傳方式", message: "我們絕對會用來做違法使用", preferredStyle: .actionSheet)
            .apply({ vc in
                vc.delegate = self
            }), animated: true)
    }
    
    @objc private func sendMessage() {
        //sendInputEvent(.createImage)
        dismissKeyboard()
        //sendInputEvent(.editImage)
        sendInputEvent(.sendMessage)
    }
    
    /// 點navigationBar右上方的點點
    @objc private func rightItemButtonClick() {
        let vc = UIAlertController(title: "你想要？", message: nil, preferredStyle: .actionSheet)
        vc.addAction(.init(title: "保存聊天記錄", style: .default, handler: { action in
            self.sendInputEvent(.saveMessages)
        }))
        vc.addAction(.init(title: "語音設定", style: .default, handler: { action in
            let vc = VoicePickerViewController()
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }))
        vc.addAction(.init(title: "取消", style: .cancel))
        present(vc, animated: true)
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
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        requestPreload()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            requestPreload()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = viewModel.getEstimatedHeight(index: indexPath.row) ?? 0
        if height == 0 {
            return UITableView.automaticDimension
        }
        //+20是因為textView在cell有padding上下１０
        height += 20
        //print("使用緩存高度 row:\(indexPath.row)  height: \(height)")
        return height
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.displayMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = viewModel.displayMessages.getOrNil(index: indexPath.row)
        switch message?.type {
        case .message, .mock:
            let message = message!
            switch message.role {
            case .user:
                let cell = tableView.dequeueReusableCell(with: ChatViews.UserMessageCell.self, for: indexPath)
                cell.bindChatMessage(chatMessage: message, attr: viewModel.getAttributeString(index: indexPath.row), indexPath: indexPath)
                return cell
            case .ai:
                let cell = tableView.dequeueReusableCell(with: ChatViews.AIMessageCell.self, for: indexPath)
                cell.bindChatMessage(chatMessage: message, attr: viewModel.getAttributeString(index: indexPath.row), indexPath: indexPath)
                return cell
            case .unknown:
                let cell = tableView.dequeueReusableCell(with: ChatViews.SystemMessageCell.self, for: indexPath)
                cell.bindChatMessage(chatMessage: message, attr: viewModel.getAttributeString(index: indexPath.row), indexPath: indexPath)
                return cell
            }
        case .none:
            let cell = tableView.dequeueReusableCell(with: ChatViews.AIMessageCell.self, for: indexPath)
            cell.setLoading(indexPath: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let message = viewModel.displayMessages[indexPath.row]
        print("contextMenuConfigurationForRowAt \(message.role)")
        switch message.role {
        case .ai:
            return .init(actionProvider:  { menuElements in
                let action1 = UIAction(title: "朗讀", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { (action) in
                    self.speakMessage(message: message.message)
                }
                let action2 = UIAction(title: "儲存到筆記", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { (action) in
                    self.showNoteTitleInputView { noteTitle in
                        self.sendInputEvent(.saveMessageToMyNote(noteTitle: noteTitle, indexPath: indexPath))
                    }
                }
                return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [action1, action2])
            })
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

//MARK: - 長按menu的選項
extension ChatViewController {
    
    func speakMessage(message: String?) {
        guard let message = message, message.isNotEmpty else { return }
        SpeechVoiceManager.shared.speak(text: message)
    }
    
    func saveToMyNote() {
        
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

