//
//  ImageFileHandler.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/9.
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
