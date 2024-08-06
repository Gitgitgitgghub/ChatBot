//
//  RemoteImageAttachment.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/9.
//

import Foundation
import UIKit
import SDWebImage

public class RemoteImageTextAttachment: NSTextAttachment {
    
    // The size to display the image. If nil, the image's size will be used
    public var displaySize: CGSize?
    public var downloadQueue: DispatchQueue?
    public var imageUrl: URL
    private weak var textContainer: NSTextContainer?
    private var isDownloading = false
    public override class var supportsSecureCoding: Bool {
        return true
    }
    
    public init(imageURL: URL, displaySize: CGSize? = nil) {
        self.imageUrl = imageURL
        self.displaySize = displaySize
        super.init(data: nil, ofType: nil)
    }
    
    required init?(coder: NSCoder) {
        guard let imageUrl = coder.decodeObject(forKey: "imageUrl") as? URL else {
            return nil
        }
        self.imageUrl = imageUrl
        //self.displaySize = coder.decodeObject(forKey: "displaySize") as? CGSize
        if let sizeString = coder.decodeObject(forKey: "displaySize") as? String {
            self.displaySize = NSCoder.cgSize(for: sizeString)
        } else {
            self.displaySize = .zero
        }
        super.init(data: nil, ofType: nil)
    }
    
    public override func encode(with coder: NSCoder) {
        coder.encode(imageUrl, forKey: "imageUrl")
        //coder.encode(displaySize, forKey: "displaySize")
        coder.encode(NSCoder.string(for: displaySize ?? .zero), forKey: "displaySize")
    }
    
    override public func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if let displaySize = displaySize {
            return CGRect(origin: .zero, size: displaySize)
        }
        if let originalImageSize = image?.size {
            return CGRect(origin: .zero, size: originalImageSize)
        }
        // If we return .zero, the image(forBounds:textContainer:characterIndex:) function won't be called
        return CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
    }
    
    override public func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        if let image = image {
            return image
        }
        self.textContainer = textContainer
        guard !isDownloading else { return nil }
        isDownloading = true
        // 這邊主要是把檔案相對路徑指向沙盒最新路徑
        if imageUrl.absoluteString.hasPrefix("file:/") {
            let fileName = imageUrl.lastPathComponent
            imageUrl = FileManager.documentsDirectory.appending(path: fileName)
        }
        SDWebImageManager.shared.loadImage(
            with: imageUrl,
            options: [.highPriority],
            progress: nil) { [weak self] image, data, error, cacheType, finished, imageUrl in
                guard let self = self else { return }
                if let image = image, error == nil {
                    let resizeImage = image.resizeToFitWidth(maxWidth: imageBounds.width)
                    DispatchQueue.main.async {
                        self.bounds = .init(origin: .zero, size: resizeImage.size)
                        self.image = resizeImage
                        self.displaySize = resizeImage.size
                        self.isDownloading = false
                        if let layoutManager = self.textContainer?.layoutManager,
                           let ranges = layoutManager.rangesForAttachment(self) {
                            ranges.forEach { range in
                                layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
                            }
                        }
                    }
                } else {
                    print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        return nil
    }
}

public extension NSLayoutManager {
    
    func rangesForAttachment(_ attachment: NSTextAttachment) -> [NSRange]? {
        guard let textStorage = textStorage else {
            return nil
        }
        var ranges: [NSRange] = []
        textStorage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textStorage.length), options: [], using: { (attribute, range, _) in
            
            if let foundAttribute = attribute as? NSTextAttachment, foundAttribute === attachment {
                ranges.append(range)
            }
        })
        return ranges
    }
}
