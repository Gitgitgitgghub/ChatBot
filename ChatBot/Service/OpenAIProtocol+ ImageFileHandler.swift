//
//  File.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/20.
//

import Foundation
import UIKit

protocol ImageFileHandler {
    
    func getImageFromInfo(info: [UIImagePickerController.InfoKey : Any]) throws -> UIImage
    
}

extension ImageFileHandler {
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
}


extension OpenAIProtocol {
    
    func getImageFromInfo(info: [UIImagePickerController.InfoKey : Any]) throws -> UIImage {
        if let selectedImage = info[.originalImage] as? UIImage {
            if info[.imageURL] is URL {
                print("圖片來自相簿")
                return selectedImage
            } else {
                print("圖片來自相機")
                return selectedImage
            }
        } else {
            throw NSError()
        }
    }
    
}
