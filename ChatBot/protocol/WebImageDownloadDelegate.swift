//
//  WebImageDownloadDelegate.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/28.
//

import Foundation
import UIKit


protocol WebImageDownloadDelegate: AnyObject {
    
    func asyncDownloadImage(attributedString: NSAttributedString, completion: (() -> Void)?)
}

extension WebImageDownloadDelegate {
    
    func asyncDownloadImage(attributedString: NSAttributedString, completion: (() -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            attributedString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedString.length), options: []) { (value, range, _) in
                if let attachment = value as? WebImageAttachment {
                    attachment.setImage(placeholder: UIImage(systemName: "arrowshape.down.circle.fill"), completion: completion)
                }
            }
        }
    }
}
