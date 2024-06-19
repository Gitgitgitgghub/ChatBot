//
//  ChatViewController+CamraPermissionRequest.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/18.
//

import Foundation
import AVFoundation
import UIKit


extension ChatViewController {
    
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] result in
                print(result)
                if result {
                    DispatchQueue.main.async {
                        self.userSeletedCamara()
                    }
                }
            }
        case .restricted, .denied:
            break
        
        case .authorized:
            self.userSeletedCamara()
        @unknown default:
            break
        }
    }
    
}
