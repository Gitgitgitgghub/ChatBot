import UIKit
import Foundation
import Photos
import Combine

class ImageManager {
    
    static let shared = ImageManager()
    /// 應用的 Documents 目錄
    let documentsDirectory: URL = FileManager.documentsDirectory
    
    private init() {
    }
    
    /// 根據圖片和 localIdentifier 保存圖片到 Documents 目錄
    /// - Parameters:
    ///   - image: 要保存的圖片
    ///   - localIdentifier: 用於文件名的 localIdentifier
    /// - Returns: 保存圖片的文件 URL，如果保存失敗則返回 nil
    func saveImageToDocumentsDirectory(image: UIImage, localIdentifier: String) -> AnyPublisher<URL?, Never> {
        let fileManager = FileManager.default
        // 清理 localIdentifier，將無效字符替換為有效字符
        let cleanedIdentifier = cleanIdentifier(localIdentifier: localIdentifier)
        let fileURL = documentsDirectory.appendingPathComponent(cleanedIdentifier).appendingPathExtension("jpg")
        // 如果文件已經存在，直接返回 URL
        if fileManager.fileExists(atPath: fileURL.path) {
            print("[DEBUG]: \(#function) 文件已經存在，直接返回 URL: \(fileURL)")
            return Just(fileURL).eraseToAnyPublisher()
        }
        // 如果文件不存在，將圖片數據寫入文件
        return Future { promise in
            DispatchQueue.global(qos: .background).async {
                if let imageData = image.jpegData(compressionQuality: 1.0) {
                    do {
                        print("[DEBUG]: \(#function) 文件不存在，將圖片數據寫入文件")
                        try imageData.write(to: fileURL)
                        promise(.success(fileURL))
                    } catch {
                        print("寫入文件錯誤: \(error)")
                        promise(.success(nil))
                    }
                } else {
                    promise(.success(nil))
                }
            }
        }.eraseToAnyPublisher()
    }

    
    // MARK: - 獲取 PHAsset
    /// 根據 localIdentifier 獲取 PHAsset
    /// - Parameters:
    ///   - identifier: localIdentifier
    /// - Returns: 獲取到的 PHAsset
    func fetchAsset(from identifier: String) -> AnyPublisher<PHAsset?, Never> {
        return Future { promise in
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            let asset = assets.firstObject
            promise(.success(asset))
        }.eraseToAnyPublisher()
    }
    
    // MARK: - 請求圖片數據
    /// 根據 PHAsset 請求圖片數據並保存
    /// - Parameters:
    ///   - asset: PHAsset 對象
    /// - Returns: 圖片的文件 URL，如果請求圖片失敗則返回 nil
    func requestImage(for asset: PHAsset) -> AnyPublisher<URL?, Never> {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        return Future { promise in
            DispatchQueue.global().async {
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) {(image, info) in
                    promise(.success(image))
                }
            }
        }
        .flatMap { [weak self] image in
            guard let `self` = self,
                  let image = image else {
                return Just<URL?>(nil)
                    .eraseToAnyPublisher()
            }
            // 使用 localIdentifier 作為文件名保存圖片
            return self.saveImageToDocumentsDirectory(image: image, localIdentifier: asset.localIdentifier)
        }
        .eraseToAnyPublisher()
    }
    
    /// 根據 localIdentifier 查找圖片的文件 URL
    /// - Parameter localIdentifier: 用於文件名的 localIdentifier
    /// - Returns: 圖片的文件 URL，如果文件不存在則返回 nil
    func urlForImage(with localIdentifier: String) -> URL? {
        let fileManager = FileManager.default
        // 清理 localIdentifier，將無效字符替換為有效字符
        let cleanedIdentifier = cleanIdentifier(localIdentifier: localIdentifier)
        let fileURL = documentsDirectory.appendingPathComponent(cleanedIdentifier).appendingPathExtension("jpg")
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func cleanIdentifier(localIdentifier: String) -> String {
        return localIdentifier
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "*", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "<", with: "_")
            .replacingOccurrences(of: ">", with: "_")
            .replacingOccurrences(of: "|", with: "_")
    }
    
    /// 將本地文件路徑轉換為 file:// 協議的 URL
    /// - Parameter localPath: 原始的本地文件路徑
    /// - Returns: 轉換後的 file:// URL，如果轉換失敗則返回 nil
    func convertToFileURL(localPath: String) -> URL? {
        // 確保路徑不為空
        guard !localPath.isEmpty else {
            print("路徑不能為空")
            return nil
        }
        if localPath.starts(with: "http") {
            return URL(string: localPath)
        }
        // 將路徑轉換為 URL
        let fileURL = URL(fileURLWithPath: localPath)
        return fileURL
    }
    
    /// 用新的目錄路徑替換 URL 中的目錄部分，保留文件名
    /// - Parameters:
    ///   - originalURL: 原始的 file:// URL
    ///   - newDirectoryURL: 新的目錄 URL
    /// - Returns: 生成的新 URL，如果替換失敗則返回 nil
    func replaceDirectoryInURL(originalURL: URL) -> URL? {
        // 確保原始 URL 的文件名部分存在
        let fileName = originalURL.lastPathComponent
        guard !fileName.isEmpty else {
            print("原始 URL 的文件名部分不存在")
            return nil
        }
        // 創建新的 URL，使用新的目錄路徑和原始 URL 的文件名
        let newURL = documentsDirectory.appendingPathComponent(fileName)
        return newURL
    }
    
    // 获取新的图片 URL 字符串
    func getNewImageURLString(from originalURL: URL) -> String? {
        return replaceDirectoryInURL(originalURL: originalURL)?.absoluteString
    }
}
