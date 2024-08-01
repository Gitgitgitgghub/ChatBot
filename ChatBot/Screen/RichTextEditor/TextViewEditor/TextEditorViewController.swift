//
//  TextEditorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/31.
//

import Foundation
import UIKit


class TextEditorViewController: BaseUIViewController {
    
    let content: Data?
    let inputBackgroundColor: UIColor
    var attr: NSMutableAttributedString?
    
    enum Action: Int, CaseIterable {
        case bold,
             italic,
             underline,
             strikethrough,
             textAlignLeft,
             textAlignCenter,
             textAlignRight,
             insertImage,
             link
        
        func enableSelected() -> Bool {
            switch self {
            case .insertImage, .link: return false
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
            }
        }
    }
    lazy var actionsStackView = UIStackView().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .horizontal
        $0.alignment = .leading
        $0.distribution = .equalSpacing
        $0.spacing = 10
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        $0.backgroundColor = .white
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.layer.borderWidth = 1
    }
    lazy var textView = NoActionTextView().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.cornerRadius = 10
        $0.backgroundColor = inputBackgroundColor
        $0.delegate = self
        $0.textColor = .white
    }
    var font: UIFont {
        if let font = self.typingAttributes[.font] as? UIFont {
            return font
        }
        return .systemFont(ofSize: 16)
    }
    var typingAttributes: [NSAttributedString.Key : Any] = [.font : SystemDefine.Message.defaultTextFont,
                                                            .foregroundColor : SystemDefine.Message.textColor]
    
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
        view.addSubview(textView)
        view.addSubview(actionsStackView)
        textView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.height.equalTo(300)
            make.centerY.equalToSuperview()
        }
        actionsStackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.bottom.equalTo(textView.snp.top).offset(-40)
        }
        setupToolbar()
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
        textView.attributedText = attr
        textView.typingAttributes = typingAttributes
        textView.linkTextAttributes = [.font: UIFont(name: "Arial", size: 16) ?? UIFont.systemFont(ofSize: 16),
                                       .foregroundColor: UIColor.systemRed,
                                       .underlineColor: UIColor.systemRed,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
    }
    
    private func setupToolbar() {
        for action in Action.allCases {
            let button = UIButton(type: .custom)
            button.tag = action.rawValue
            button.addTarget(self, action: #selector(onActionButtonClick(sender:)), for: .touchUpInside)
            button.setImage(action.image, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tintColor = .systemGray
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 30),
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: 30)
            ])
            actionsStackView.addArrangedSubview(button)
        }
    }
    
    @objc private func onActionButtonClick(sender: UIButton) {
        guard let action = Action(rawValue: sender.tag) else { return }
        toggleActionButton(action: action)
        switch action {
        case .bold:
            makeBold(isSelected: sender.isSelected)
        case .italic:
            makeItalic(isSelected: sender.isSelected)
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
        }
    }
    
    func toggleActionButton(action: Action) {
        guard let button = actionsStackView.arrangedSubviews.getOrNil(index: action.rawValue) as? UIButton else { return }
        guard action.enableSelected() else { return }
        switch action {
            // 這三顆按鈕互斥
        case .textAlignLeft, .textAlignCenter, .textAlignRight:
            let alignActions: [Action] = [.textAlignLeft, .textAlignCenter, .textAlignRight]
            alignActions.forEach { alignAction in
                if alignAction != action {
                    guard let otherButton = actionsStackView.arrangedSubviews.getOrNil(index: alignAction.rawValue) as? UIButton else { return }
                    otherButton.isSelected = false
                    otherButton.tintColor = .systemGray
                    otherButton.backgroundColor = .white
                }
            }
            button.isSelected = true
            button.tintColor = .white
            button.backgroundColor = .systemGray
        default:
            button.isSelected.toggle()
            button.tintColor = button.isSelected ? .white : .systemGray
            button.backgroundColor = button.isSelected ? .systemGray : .white
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
            if let button = actionsStackView.arrangedSubviews.getOrNil(index: action.rawValue) as? UIButton {
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
    
    func makeBold(isSelected: Bool) {
        applyAttribute(.font, value: selecteFont())
    }
    
    func makeItalic(isSelected: Bool) {
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
            self.updateTypingAttributes(attribute: nil, value: nil)
        }
    }
    
    func insertImage() {
        showImageSelectionAlert { urlString in
            guard let urlString = urlString, urlString.isNotEmpty else { return }
            guard let url = URL(string: urlString) else { return }
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

    func updateTypingAttributes(attribute: NSAttributedString.Key?, value: Any?) {
        if let attribute = attribute {
            typingAttributes[attribute] = value
        }
        textView.typingAttributes = typingAttributes
    }
}

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
            updateTypingAttributes(attribute: nil, value: nil)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}


