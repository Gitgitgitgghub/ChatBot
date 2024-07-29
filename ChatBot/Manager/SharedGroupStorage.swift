//
//  SharedGroupStorage.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/29.
//

import Foundation
import UIKit


class SharedGroupStorage {
    static let shared = SharedGroupStorage()
    private let suiteName = "group.com.yourcompany.yourapp"
    
    private init() {}
    
    func saveImage(_ image: UIImage, withName name: String) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8),
              let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName) else {
            return nil
        }
        
        let fileURL = containerURL.appendingPathComponent(name)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("保存圖片失敗: \(error)")
            return nil
        }
    }
    
    func getImageURL(withName name: String) -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName) else {
            return nil
        }
        
        let fileURL = containerURL.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}
