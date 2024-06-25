import UIKit
import SDWebImage
import Kingfisher


protocol AttributedStringParsable {
    func parseToAttributedString(string: String, completion: @escaping (_ attr: NSAttributedString) -> Void)
}


protocol WebImageDownloadDelegate: AnyObject {
    
    func asyncDownloadImage(urlString: String, textAttachment: NSTextAttachment, completion: (() -> Void)?) throws
    
    func imageDownloadComplete()
}

extension WebImageDownloadDelegate {
    
    func asyncDownloadImage(urlString: String, textAttachment: NSTextAttachment, completion: (() -> Void)? = nil) throws {
        guard URL(string: urlString) != nil else { throw NSError(domain: "Invalid URL", code: 0, userInfo: nil) }
        textAttachment.setImage(from: urlString, placeholder: UIImage(systemName: "arrowshape.down.circle.fill"), completion: imageDownloadComplete)
    }
}


enum ParseError: Error {
    case invalidURL
    case unsupportedFormat
    case imageDownloadFailed
}

class AttributedStringParser: AttributedStringParsable {
    
    
    weak var webImageDownloadDelegate: WebImageDownloadDelegate?
    
    
    func parseToAttributedString(string: String, completion: @escaping (_ attr: NSAttributedString) -> Void){
        DispatchQueue.global(qos: .background).async { [self] in
            let attributedString = NSMutableAttributedString(string: string)
            attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: string.utf16.count))
            do {
                try self.matchTitleTexts(string: string, attributedString: attributedString)
                try self.matchUrlTexts(string: string, attributedString: attributedString)
                try self.matchImageUrlTexts(string: string, attributedString: attributedString)
            } catch {
                print("Error creating regex: \(error)")
            }
            completion(attributedString)
        }
    }
    
    func getTitleTextMathces(string: String) throws -> [NSTextCheckingResult] {
        let itemPattern = "\\d+\\. [^\\n]+"
        let itemRegex = try NSRegularExpression(pattern: itemPattern, options: [])
        return itemRegex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
    }
    
    func matchTitleTexts(string: String, attributedString: NSMutableAttributedString) throws {
        let boldFont = UIFont.boldSystemFont(ofSize: 16)
        let matches = try getTitleTextMathces(string: string)
        for match in matches {
            attributedString.addAttribute(.font, value: boldFont, range: match.range)
        }
    }
    
    func getImageUrlMatches(string: String) throws -> [NSTextCheckingResult] {
        let imagePattern = #"(?i)\b(?:https?://|www\.)\S+\.(?:jpe?g|gif|png|bmp|tiff|tif|webp|svg)\b"#
        let regex = try NSRegularExpression(pattern: imagePattern, options: [])
        return regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
    }
    
    func matchImageUrlTexts(string: String, attributedString: NSMutableAttributedString) throws {
        do {
            let matches = try getImageUrlMatches(string: string)
            for (i, match) in matches.enumerated() {
                let urlRange = Range(match.range, in: string)!
                let urlString = String(string[urlRange])
                let attachment = NSTextAttachment()
                attachment.bounds = CGRect(x: 0, y: 0, width: 300, height: 210)
                let imageAttributedString = NSAttributedString(attachment: attachment)
                attributedString.insert(imageAttributedString, at: match.range.location + i)
                attributedString.insert(NSAttributedString(string: "\n"), at: match.range.location + 1 + i)
                try self.webImageDownloadDelegate?.asyncDownloadImage(urlString: urlString, textAttachment: attachment)
            }
        } catch {
            throw error
        }
    }
    
    func getUrlMatches(string: String) throws -> [NSTextCheckingResult] {
        let urlPattern = #"(?i)\bhttps?://(?:www\.)?[a-zA-Z0-9.-]+(?:\.[a-zA-Z]{2,})(?:/[a-zA-Z0-9._%+-]*)*(?:\?[a-zA-Z0-9=&%._+-]*)?\b"#
        let urlRegex = try NSRegularExpression(pattern: urlPattern, options: [])
        return urlRegex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
    }
    
    func matchUrlTexts(string: String, attributedString: NSMutableAttributedString) throws {
        let regularFont = UIFont.systemFont(ofSize: 16)
        do {
            let urlMatches = try getUrlMatches(string: string)
            for match in urlMatches {
                let urlRange = Range(match.range, in: string)!
                if let url = URL(string:String(string[urlRange])) {
                    attributedString.addAttribute(.link, value: url, range: match.range)
                    attributedString.addAttribute(.font, value: regularFont, range: match.range)
                }
            }
        } catch {
            throw error
        }
    }
    
    private func extractYouTubeVideoID(from url: String) throws -> String {
        let pattern = "https?://(?:www\\.)?youtube\\.com/watch\\?v=([\\w-]+)"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsString = url as NSString
        let results = regex.matches(in: url, options: [], range: NSRange(location: 0, length: nsString.length))
        
        guard let result = results.first, result.numberOfRanges == 2 else {
            throw ParseError.invalidURL
        }
        return nsString.substring(with: result.range(at: 1))
    }
}
