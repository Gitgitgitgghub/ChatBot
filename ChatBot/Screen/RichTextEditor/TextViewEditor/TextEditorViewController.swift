//
//  TextEditorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/31.
//

import Foundation
import UIKit


class TextEditorViewController: BaseUIViewController, TextEditorViewsProtocol {
    
    enum Action: Int, CaseIterable {
        case bold,
             italic,
             underline,
             strikethrough,
             textAlignLeft,
             textAlignCenter,
             textAlignRight,
             insertImage,
             link,
             fontColor,
             highlightColor,
             fontSize,
             font
        
        func enableSelected() -> Bool {
            switch self {
            case .insertImage, .link, .fontColor, .fontSize, .highlightColor, .font: return false
            default: return true
            }
        }
        
        var image: UIImage? {
            switch self {
            case .bold: return.init(systemName: "bold")
            case .italic: return.init(systemName: "italic")
            case .underline: return.init(systemName: "underline")
            case .strikethrough: return.init(systemName: "strikethrough")
            case .textAlignLeft: return.init(systemName: "text.alignleft")
            case .textAlignCenter: return.init(systemName: "text.aligncenter")
            case .textAlignRight: return.init(systemName: "text.alignright")
            case .insertImage: return.init(systemName: "photo")
            case .link: return.init(systemName: "link")
            case .fontColor:
                return .init(systemName: "textformat.size.larger")
            case .highlightColor:
                return .init(systemName: "highlighter")
            default: return .init(systemName: "textformat.size.larger")
            }
        }
    }
    let content: Data?
    let inputBackgroundColor: UIColor
    var attr: NSMutableAttributedString?
    lazy var views = TextEditorViews(view: self.view)
    var typingAttributes: [NSAttributedString.Key : Any] = [.font : SystemDefine.Message.defaultTextFont,
                                                            .foregroundColor : SystemDefine.Message.textColor]
    var textView: UITextView {
        return views.textView
    }
    var font: UIFont {
        if let font = self.typingAttributes[.font] as? UIFont {
            return font
        }
        return .systemFont(ofSize: 16)
    }
    /// 觸發顏色選擇器的Action目前只有:fontColor,highlightColor
    var colorPickerAction: Action = .fontColor
    
    init(content: Data?, inputBackgroundColor: UIColor) {
        self.content = content
        self.inputBackgroundColor = inputBackgroundColor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    private func initUI() {
        views.delegate = self
        setupTextView()
    }
    
    private func setupTextView() {
        if let content = self.content {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.rtfd,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            attr = try? .init(data: content, options: options, documentAttributes: nil)
        }
        if attr == nil {
            attr = .init(string: "", attributes: nil)
        }
        textView.backgroundColor = inputBackgroundColor
        textView.attributedText = attr
        textView.typingAttributes = typingAttributes
        textView.linkTextAttributes = [.font: UIFont(name: "Arial", size: 16) ?? UIFont.systemFont(ofSize: 16),
                                       .foregroundColor: UIColor.systemRed,
                                       .underlineColor: UIColor.systemRed,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
    }
    
    func onActionButtonClick(action: Action) {
        switch action {
        case .bold:
            makeBold()
        case .italic:
            makeItalic()
        case .underline:
            makeUnderline()
        case .strikethrough:
            makeStrikethrough()
        case .textAlignLeft:
            alignLeft()
        case .textAlignCenter:
            alignCenter()
        case .textAlignRight:
            alignRight()
        case .insertImage:
            insertImage()
        case .link:
            insertLink()
        case .fontColor:
            changeFontColor()
        case .highlightColor:
            changeHighlightColor()
        case .fontSize:
            changeFontSize()
        case .font:
            changeFont()
        }
    }
    
    /// 顯示插入連結ＵＩ
    func showLinkInputController(completion: @escaping (_ title: String?, _ urlString: String?) -> ()) {
        let alert = UIAlertController(title: "插入連結", message: "請輸入連結", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "標題(可不輸入)"
        }
        alert.addTextField { textField in
            textField.placeholder = "網址"
            textField.text = "https://google.com"
        }
        let insertAction = UIAlertAction(title: "插入", style: .default) { _ in
            let title = alert.textFields?.getOrNil(index: 0)?.text
            let url = alert.textFields?.getOrNil(index: 1)?.text
            completion(title, url)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(insertAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    /// 顯示插入圖片來源ＵＩ
    private func showImageSelectionAlert(completion: @escaping (_ urlString: String?) -> ()) {
        let alert = UIAlertController(title: "選擇圖片", message: "請選擇一種方式添加圖片", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "輸入網址", style: .default, handler: { _ in
            self.promptForImageURL(completion: completion)
        }))
        alert.addAction(UIAlertAction(title: "從相簿選擇", style: .default, handler: { _ in
            self.requestPhotoLibraryAccess { [weak self] in
                self?.selectImageFromGallery()
                completion(nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// 顯示顏色選擇ＵＩ
    func showColorPickerVC() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = textView.textColor ?? .label
        present(colorPicker, animated: true, completion: nil)
    }
    
    /// 跳出字型選擇ＶＣ
    func showFontSelectorVc(completion: @escaping (_ fontName: String) -> ()) {
        let alertController = UIAlertController(title: "選擇你要的字型", message: nil, preferredStyle: .actionSheet)
        let fontList = SystemDefine.Message.fontList
        for fontName in fontList {
            let action = UIAlertAction(title: fontName, style: .default) { _ in
                completion(fontName)
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "關閉", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    /// 跳出文字大小輸入匡ＶＣ
    func showFontSizeInputVc(completion: @escaping (_ size: CGFloat) -> ()) {
        let alertController = UIAlertController(title: "修改文字大小", message: "修改文字大小", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "允許大小12~48"
            textField.keyboardType = .numberPad
        }
        let confirmAction = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            if let textField = alertController.textFields?.first, let text = textField.text, let fontSize = Int(text) {
                if fontSize >= 12 && fontSize <= 48 {
                    completion(CGFloat(fontSize))
                } else {
                    textField.text = ""
                    textField.placeholder = "輸入錯誤! 允許大小12~48"
                    self?.present(alertController, animated: true, completion: nil)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "關閉", style: .cancel, handler: nil)
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    /// 從相簿選擇
    private func selectImageFromGallery() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    /// 顯示輸入圖片網址ＵＩ
    private func promptForImageURL(completion: @escaping (_ urlString: String?) -> ()) {
        let alert = UIAlertController(title: "輸入圖片網址", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "圖片網址"
        }
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { [weak alert] _ in
            completion(alert?.textFields?.first?.text)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// 取得該顯示的字型
    func selecteFont() -> UIFont {
        let actions: [Action] = [.bold, .italic]
        var isBold = false
        var isItalic = false
        actions.forEach { action in
            if let button = views.getCellButton(action: action) {
                switch action {
                case .bold: isBold = button.isSelected
                case .italic: isItalic = button.isSelected
                default: return
                }
            }
        }
        if isBold && isItalic {
            return font.boldItalic()
        }else if isBold {
            return font.bold()
        }else if isItalic {
            return font.italic()
        }else {
            return font
        }
    }
    
}

extension TextEditorViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}

//MARK: Actions
extension TextEditorViewController {
    
    func makeBold() {
        applyAttribute(.font, value: selecteFont())
    }
    
    func makeItalic() {
        applyAttribute(.font, value: selecteFont())
    }
    
    func makeUnderline() {
        applyAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue)
    }
    
    func makeStrikethrough() {
        applyAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue)
    }

    func alignLeft() {
        applyParagraphStyle { style in
            style.alignment = .left
        }
    }

    func alignCenter() {
        applyParagraphStyle { style in
            style.alignment = .center
        }
    }

    func alignRight() {
        applyParagraphStyle { style in
            style.alignment = .right
        }
    }
    
    func insertLink() {
        showLinkInputController { [weak self] title, urlString in
            guard let self = self,
                  let urlString = urlString,
                  let url = URL(string: urlString) else { return }
            let selectedRange = self.textView.selectedRange
            guard selectedRange.location != NSNotFound else { return }
            let linkText = title?.isEmpty == false ? title! : urlString
            let attributedString = NSMutableAttributedString(string: linkText, attributes: [.link : url])
            self.textView.textStorage.replaceCharacters(in: selectedRange, with: attributedString)
            /// 這邊要重新設定不然後續輸入的文字也會成為超連結的一部分
            self.textView.selectedRange = NSRange(location: selectedRange.location + linkText.count, length: 0)
            self.reapplyTypingAttributes()
        }
    }
    
    func insertImage() {
        showImageSelectionAlert { urlString in
            guard let urlString = urlString, urlString.isNotEmpty else { return }
            guard let url = URL(string: urlString) else { return }
        }
    }
    
    func changeFontColor() {
        colorPickerAction = .fontColor
        showColorPickerVC()
    }
    
    func changeHighlightColor() {
        colorPickerAction = .highlightColor
        showColorPickerVC()
    }
    
    func changeFont() {
        showFontSelectorVc { [weak self] fontName in
            guard let `self` = self else { return }
            let currentFont = self.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
            guard let newFont = UIFont(name: fontName, size: currentFont.pointSize) else { return }
            self.applyAttribute(.font, value: newFont)
        }
    }
    
    func changeFontSize() {
        showFontSizeInputVc { [weak self] size in
            guard let `self` = self else { return }
            let currentFont = self.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
            guard let newFont = UIFont(name: currentFont.fontName, size: size) else { return }
            self.applyAttribute(.font, value: newFont)
        }
    }

    func applyParagraphStyle(modifier: (NSMutableParagraphStyle) -> Void) {
        guard let range = textView.selectedTextRange else { return }
        let nsRange = textView.textRangeToNSRange(range)
        textView.textStorage.beginEditing()
        textView.textStorage.enumerateAttribute(.paragraphStyle, in: nsRange, options: []) { value, range, _ in
            let style = (value as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            modifier(style)
            textView.textStorage.addAttribute(.paragraphStyle, value: style, range: range)
            updateTypingAttributes(attribute: .paragraphStyle, value: style)
        }
        textView.textStorage.endEditing()
    }
    
    func applyAttribute(_ attribute: NSAttributedString.Key, value: Any) {
        guard let range = textView.selectedTextRange else { return }
        let nsRange = textView.textRangeToNSRange(range)
        if nsRange.length > 0 {
            let existValue = textView.textStorage.attribute(attribute, at: nsRange.location, longestEffectiveRange: nil, in: nsRange) as AnyObject
            if existValue.isEqual(value) {
                print("equal")
                textView.textStorage.removeAttribute(attribute, range: nsRange)
                textView.textStorage.addAttribute(attribute, value: value, range: nsRange)
            }else {
                print("not equal")
                textView.textStorage.addAttribute(attribute, value: value, range: nsRange)
            }
        }
        updateTypingAttributes(attribute: attribute, value: value)
    }
    
    func reapplyTypingAttributes() {
        updateTypingAttributes(attribute: nil, value: nil)
    }

    func updateTypingAttributes(attribute: NSAttributedString.Key?, value: Any?) {
        if let attribute = attribute {
            typingAttributes[attribute] = value
        }
        textView.typingAttributes = typingAttributes
    }
}

//MARK: - UIColorPickerViewControllerDelegate 處理文字顏色選擇後的動作
extension TextEditorViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor
        guard let range = textView.selectedTextRange else { return }
        let attribute:  NSAttributedString.Key = (colorPickerAction == .fontColor) ? .foregroundColor : .backgroundColor
        let nsRange = textView.textRangeToNSRange(range)
        textView.textStorage.addAttribute(attribute, value: selectedColor, range: nsRange)
        updateTypingAttributes(attribute: attribute, value: selectedColor)
    }
}

//MARK: - UIColorPickerViewControllerDelegate 處理本地圖片選中後的動作
extension TextEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            let attachment = NSTextAttachment()
            let resizeImage = image.resizeToFitWidth(maxWidth: UIScreen.main.bounds.width - 36)
            attachment.image = resizeImage
            attachment.bounds = .init(origin: .zero, size: resizeImage.size)
            let attributedString = NSAttributedString(attachment: attachment)
            let selectedRange = textView.selectedRange
            textView.textStorage.insert(attributedString, at: selectedRange.location)
            // 更新选择范围以防止光标位置错误
            textView.selectedRange = NSRange(location: selectedRange.location + 1, length: 0)
            reapplyTypingAttributes()
        }
        picker.dismiss(animated: true, completion: nil)
    }
}


