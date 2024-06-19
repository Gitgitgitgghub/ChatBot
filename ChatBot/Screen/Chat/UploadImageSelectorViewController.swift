//
//  UploadImageSelectorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/18.
//

import UIKit
import AVFoundation

class UploadImageSelectorViewController: UIAlertController {
    
    weak var delegate: UploadImageSelectorViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        addAction()
    }
    
    private func addAction() {
        addAction(UIAlertAction(title: "相機", style: .default, handler: { [unowned self] action in
            self.delegate?.userSeletedCamara()
        }))
        addAction(UIAlertAction(title: "相簿", style: .default, handler: { [unowned self] action in
            self.delegate?.userSeletedPhotoLibrary()
        }))
        addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
    
    deinit {
        print("\(className) deinit")
    }

}

protocol UploadImageSelectorViewControllerDelegate: AnyObject {
    
    func userSeletedCamara()
    
    func userSeletedPhotoLibrary()
    
}
