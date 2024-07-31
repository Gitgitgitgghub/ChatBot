//
//  TextEditorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/31.
//

import Foundation
import UIKit


class TextEditorViewController: UIViewController {
    
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
    }
    lazy var toolBar = UIToolbar().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    lazy var textView = NoActionTextView().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.cornerRadius = 10
        $0.backgroundColor = inputBackgroundColor
        $0.delegate = self
    }
    var effectiveAction = Set<Action>()
    
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
        view.addSubview(toolBar)
        textView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.height.equalTo(300)
            make.centerY.equalToSuperview()
        }
        toolBar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.bottom.equalTo(textView.snp.top).offset(-40)
            make.height.greaterThanOrEqualTo(50)
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
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font : SystemDefine.Message.defaultTextFont,
                                .foregroundColor : SystemDefine.Message.textColor]
        if attr == nil {
            attr = .init(string: "", attributes: defaultAttributes)
        }
        textView.attributedText = attr
        textView.typingAttributes = defaultAttributes
    }
    
    private func setupToolbar() {
        let bold = UIBarButtonItem(image: .init(systemName: "bold"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        let italic = UIBarButtonItem(image: .init(systemName: "italic"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        let underline = UIBarButtonItem(image: .init(systemName: "underline"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        let strikethrough = UIBarButtonItem(image: .init(systemName: "strikethrough"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        let textAlignleft = UIBarButtonItem(image: .init(systemName: "text.alignleft"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        let textAligncenter = UIBarButtonItem(image: .init(systemName: "text.aligncenter"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        let textAlignright = UIBarButtonItem(image: .init(systemName: "text.alignright"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        let insertImage = UIBarButtonItem(image: .init(systemName: "photo"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        let link = UIBarButtonItem(image: .init(systemName: "link"), style: .plain, target: self, action: #selector(onActionButtonClick(sender:)))
        toolBar.items = [bold,
                         italic,
                         underline,
                         strikethrough,
                         textAlignleft,
                         textAligncenter,
                         textAlignright,
                         insertImage,
                         link]
        for (i, item) in toolBar.items!.enumerated() {
            item.tag = Action.allCases[i].rawValue
        }
    }
    
    @objc private func onActionButtonClick(sender: UIBarButtonItem) {
        guard let action = Action(rawValue: sender.tag) else { return }
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
        }
        selectAction(action: action)
    }
    
    func selectAction(action: Action) {
        guard action.enableSelected() else { return }
        if effectiveAction.contains(where: { $0 == action }) {
            effectiveAction.remove(action)
        }else {
            effectiveAction.insert(action)
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
        applyAttribute(.font, value: UIFont.boldSystemFont(ofSize: textView.font?.pointSize ?? 16))
    }
    
    func makeItalic() {
        applyAttribute(.font, value: UIFont.italicSystemFont(ofSize: textView.font?.pointSize ?? 16))
    }
    
    func makeUnderline() {
        applyAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue)
    }
    
    func makeStrikethrough() {
        applyAttribute(.strikethroughStyle, value: UIColor.black)
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
        let alert = UIAlertController(title: "Insert Link", message: "Enter URL", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "URL"
        }
        let insertAction = UIAlertAction(title: "Insert", style: .default) { _ in
            if let url = alert.textFields?.first?.text {
                self.applyAttribute(.link, value: url)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(insertAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func insertImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }

    func applyParagraphStyle(modifier: (NSMutableParagraphStyle) -> Void) {
        if let range = textView.selectedTextRange {
            let nsRange = textView.textRangeToNSRange(range)
            let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            
            attributedText.enumerateAttribute(.paragraphStyle, in: nsRange, options: []) { value, range, _ in
                let style = (value as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
                modifier(style)
                attributedText.addAttribute(.paragraphStyle, value: style, range: range)
            }
            
            textView.attributedText = attributedText
        }
    }
    
    func applyAttribute(_ attribute: NSAttributedString.Key, value: Any) {
        if let range = textView.selectedTextRange {
            let nsRange = textView.textRangeToNSRange(range)
            let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            attributedText.addAttribute(attribute, value: value, range: nsRange)
            textView.attributedText = attributedText
            // 更新 typingAttributes
            var currentAttributes = textView.typingAttributes
            currentAttributes[attribute] = value
            textView.typingAttributes = currentAttributes
        }
    }
    
}

extension TextEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            let attachment = NSTextAttachment()
            attachment.image = image
            let attributedString = NSAttributedString(attachment: attachment)
            textView.textStorage.insert(attributedString, at: textView.selectedRange.location)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}


