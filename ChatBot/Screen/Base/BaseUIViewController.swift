//
//  BaseUIViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import Foundation
import UIKit
import Combine
import AVFoundation
import Photos

protocol ViewControllerProtocol: AnyObject where Self: UIViewController {
    
    associatedtype ViewModel: ViewModelProtocol
    var viewModel: ViewModel { get }
    var enableSwipeToGoBack: Bool { get }
    func sendInputEvent(_ inputEvent: ViewModel.Input)
    
}

extension ViewControllerProtocol {
    
    func sendInputEvent(_ inputEvent: ViewModel.Input) {
        viewModel.transform(inputEvent: inputEvent)
    }
    
}


class BaseUIViewController<VM: ViewModelProtocol>: UIViewController, ViewControllerProtocol {
    
    var viewModel: VM
    var subscriptions = Set<AnyCancellable>()
    var enableSwipeToGoBack = true
    
    init() {
        viewModel = VM()
        super.init(nibName: nil, bundle: nil)
    }
    
    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        subscriptions.removeAll()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        print("ViewController: \(className) had been deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwipeBack()  // 設置是否允許右滑返回
        setupBindings()
        setupButton()
        observeKeyboard()
    }
    
    // Swipe 返回邏輯
    private func setupSwipeBack() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = enableSwipeToGoBack
    }
    
    /// 設置綁定 ViewModel 的輸出事件和其他通用行為
    private func setupBindings() {
        viewModel.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] outputEvent in
                self?.handleOutputEvent(outputEvent)
            }
            .store(in: &subscriptions)
        viewModel.loadingStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                self?.onLoadingStatusChanged(status: status)
            }
            .store(in: &subscriptions)
    }
    
    /// 觀察鍵盤顯示與否
    func observeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    private func setupButton() {
        let backButton = UIBarButtonItem(title: "返回", image: .init(systemName: "chevron.left"), target: self, action: #selector(customBackAction))
        self.navigationItem.leftBarButtonItem = backButton
    }
    
    /// 處理 ViewModel 的輸出事件
    func handleOutputEvent(_ outputEvent: VM.Output) {
        fatalError("Subclasses must override `handleOutputEvent`")
    }
    
    /// 提供給子類重寫的 hook
    func onLoadingStatusChanged(status: LoadingStatus) {
        // 可以在這裡顯示 loading UI
    }
    
    @objc func customBackAction() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func keyboardShow(_ notification: Notification) { }
    
    @objc func keyboardHide(_ notification: Notification) { }
    
    func showToast(title: String = "", message: String, autoDismiss after: Double = 1.5, completion: (() -> ())? = nil) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(vc, animated: true)
        delay(delay: after) {
            vc.dismiss(animated: true)
            completion?()
        }
    }
    
    
    
}


//MARK: - permission
extension BaseUIViewController {
    
    func requestCameraPermission(completion: @escaping () -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { result in
                print(result)
                if result {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        case .denied:
            self.showAccessDeniedAlert(message: "請前往設置已允許訪問相機。")
        case .restricted:
            self.showRestrictedAccessAlert(message: "您的設備設置不允許訪問相機。")
        case .authorized:
            completion()
        @unknown default:
            break
        }
    }
    
    func requestPhotoLibraryAccess(completion: @escaping () -> ()) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .restricted:
            self.showRestrictedAccessAlert(message: "您的設備設置不允許訪問相册。")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    self?.requestPhotoLibraryAccess(completion: completion)
                }
            }
        case .limited:
            // iOS 14 及以上版本用户可以选择限制访问。
            completion()
        case .authorized:
            completion()
        case .denied:
            self.showAccessDeniedAlert(message: "請前往設置以允許訪問相冊。")
        @unknown default:
            break
        }
    }
    
    func requestMicrophoneAccess() {
        AVAudioApplication.requestRecordPermission { [unowned self] allowed in
            if allowed {
                print("麥克風使用允許")
            } else {
                self.showAccessDeniedAlert(message: "請前往設置以允許使用麥克風", cancelHandler: { [unowned self] _ in
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                })
            }
        }
    }
    
    func showAccessDeniedAlert(message: String, cancelHandler: ((UIAlertAction) -> (Void))? = nil) {
        let alert = UIAlertController(title: "訪問被拒絕", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: cancelHandler))
        alert.addAction(UIAlertAction(title: "設置", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func showRestrictedAccessAlert(message: String) {
        let alert = UIAlertController(title: "訪問受限", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    
}
