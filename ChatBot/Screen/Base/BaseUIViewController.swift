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

class BaseUIViewController: UIViewController {
    
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /// 觀察鍵盤顯示與否
    func observeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardShow(_ notification: Notification) { }
    
    @objc func keyboardHide(_ notification: Notification) { }
    
    deinit {
        subscriptions.removeAll()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        print("ViewController: \(className) had been deinited")
    }
    
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
            self.showAccessDeniedAlert(message: "請前往設置已允許訪問相冊。")
        @unknown default:
            break
        }
    }
    
    func showAccessDeniedAlert(message: String) {
        let alert = UIAlertController(title: "訪問被拒絕", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
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
