import UIKit
import SDWebImage
import Kingfisher
import Combine


/// 字串轉AttributedString協定
protocol AttributedStringParsable {
    /// string轉AttributedString
    func convertStringToAttributedString(string: String) -> AnyPublisher<NSAttributedString, Error>
    /// string array轉AttributedString array
    func convertStringsToAttributedStrings(strings: [String]) -> AnyPublisher<NSAttributedString, Error>
}

class AttributedStringParser: AttributedStringParsable {
    
    func convertStringsToAttributedStrings(strings: [String]) -> AnyPublisher<NSAttributedString, Error> {
        let publishers = strings.map { convertStringToAttributedString(string: $0) }
        return Publishers.MergeMany(publishers).eraseToAnyPublisher()
    }

    func convertStringToAttributedString(string: String) -> AnyPublisher<NSAttributedString, Error> {
        return Future { promise in
            DispatchQueue.global(qos: .background).async {
                do {
                    let result: NSAttributedString = try self.createAttributedString(string: string)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    
    func createAttributedString(string: String) throws -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttributes([.font : UIFont.systemFont(ofSize: 16),
                                        .foregroundColor : UIColor.white], range: NSRange(location: 0, length: string.count))
        do {
            try self.matchTitleTexts(string: string, attributedString: attributedString)
            try self.matchUrlTexts(string: string, attributedString: attributedString)
            try self.matchImageUrlTexts(string: string, attributedString: attributedString)
            return attributedString
        } catch {
            throw error
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
                let url = URL(string: String(string[urlRange]))
                let attachment = WebImageAttachment()
                attachment.bounds = CGRect(x: 0, y: 0, width: 300, height: 210)
                attachment.imageUrl = url
                let imageAttributedString = NSAttributedString(attachment: attachment)
                attributedString.insert(imageAttributedString, at: match.range.location + i)
                attributedString.insert(NSAttributedString(string: "\n"), at: match.range.location + 1 + i)
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
}
