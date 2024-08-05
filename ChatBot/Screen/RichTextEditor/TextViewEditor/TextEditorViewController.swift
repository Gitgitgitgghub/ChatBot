//
//  TextEditorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/31.
//

import Foundation
import UIKit

protocol TextEditorViewControllerDelegate: AnyObject {
    
    func onSave(attributedString: NSAttributedString?)
    
}


class TextEditorViewController: BaseUIViewController, TextEditorViewsProtocol {
    
    
    enum Action: Equatable {
        
        case bold(isSeleted: Bool)
        case italic(isSeleted: Bool)
        case underline(isSeleted: Bool)
        case strikethrough(isSeleted: Bool)
        case textAlignLeft(isSeleted: Bool)
        case textAlignCenter(isSeleted: Bool)
        case textAlignRight(isSeleted: Bool)
        case insertImage
        case link
        case fontColor(color: UIColor)
        case highlightColor(color: UIColor)
        case fontSize(size: CGFloat)
        case fontName(foneName: String)
        
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
            default: return nil
            }
        }
        
        var actionName: String {
            switch self {
            case .bold(_): return "粗體"
            case .italic(_): return "斜體"
            case .underline(_): return "底線"
            case .strikethrough(_): return "刪除線"
            case .textAlignLeft(_): return "靠左對齊"
            case .textAlignCenter(_): return "靠中對齊"
            case .textAlignRight(_): return "靠右對齊"
            case .insertImage: return "插入圖片"
            case .link: return "插入連結"
            case .fontColor(_): return "字體顏色"
            case .highlightColor(_): return "背景顏色"
            case .fontSize(_): return "字體大小"
            case .fontName(_): return "字型"
            }
        }
        
        func enableToggle() -> Bool {
            switch self {
            case .insertImage, .link, .fontColor, .fontSize, .highlightColor, .fontName: return false
            default: return true
            }
        }
        
        func setSelected(_ isSelected: Bool) -> Action {
            switch self {
            case .bold:
                return .bold(isSeleted: isSelected)
            case .italic:
                return .italic(isSeleted: isSelected)
            case .underline:
                return .underline(isSeleted: isSelected)
            case .strikethrough:
                return .strikethrough(isSeleted: isSelected)
            case .textAlignLeft:
                return .textAlignLeft(isSeleted: isSelected)
            case .textAlignCenter:
                return .textAlignCenter(isSeleted: isSelected)
            case .textAlignRight:
                return .textAlignRight(isSeleted: isSelected)
            default:
                return self
            }
        }
        
        // 新增方法來處理文字對齊的互斥性
        static func updateTextAlignment(_ currentAlignment: Action) -> [Action] {
            let alignments: [Action] = [
                .textAlignLeft(isSeleted: false),
                .textAlignCenter(isSeleted: false),
                .textAlignRight(isSeleted: false)
            ]
            
            return alignments.map { alignment in
                switch (alignment, currentAlignment) {
                case (.textAlignLeft, .textAlignLeft),
                    (.textAlignCenter, .textAlignCenter),
                    (.textAlignRight, .textAlignRight):
                    return currentAlignment
                default:
                    return alignment
                }
            }
        }
    }
    
    let content: Data?
    let inputBackgroundColor: UIColor
    weak var delegate: TextEditorViewControllerDelegate?
    let viewModel = TextEditorViewModel()
    var attr: NSMutableAttributedString?
    lazy var views = TextEditorViews(view: self.view)
    
    var textView: UITextView {
        return views.textView
    }
    
    /// 觸發顏色選擇器的Action目前只有:fontColor,highlightColor
    var colorPickerAction: Action = .fontColor(color: .clear)
    
    init(content: Data?, inputBackgroundColor: UIColor, delegate: TextEditorViewControllerDelegate) {
        self.content = content
        self.inputBackgroundColor = inputBackgroundColor
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
    }
    
    private func initUI() {
        views.delegate = self
        setupTextView()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(save))
    }
    
    private func bind() {
        viewModel.bindInputEvent()
        viewModel.outputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .typingAttributesChange(let typingAttributes):
                    self.textView.typingAttributes = typingAttributes
                case .actionUIChange:
                    self.views.actionCollectionView.reloadData()
                }
            }
            .store(in: &subscriptions)
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
        textView.linkTextAttributes = [.font: SystemDefine.Message.defaultTextFont,
                                       .foregroundColor: UIColor.systemRed,
                                       .underlineColor: UIColor.systemRed,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.typingAttributes = viewModel.typingAttributes
    }
    
    @objc private func save() {
        delegate?.onSave(attributedString: textView.attributedText)
        navigationController?.popViewController(animated: true)
    }
    
    func getActionDataSource() -> [Action] {
        return viewModel.actions
    }
    
    func onActionButtonClick(action: Action, indexPath: IndexPath) {
        viewModel.transform(inputEvent: .toggleActionButton(indexPath: indexPath))
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
        case .fontName:
            changeFontName()
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
    
    
}

extension TextEditorViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}

//MARK: Actions
extension TextEditorViewController {
    
    func makeBold() {
        applyAttribute(.font, value: viewModel.getFont())
    }
    
    func makeItalic() {
        applyAttribute(.font, value: viewModel.getFont())
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
            self.viewModel.transform(inputEvent: .reapplyTypingAttributes)
        }
    }
    
    func insertImage() {
        showImageSelectionAlert { urlString in
            guard let urlString = urlString, urlString.isNotEmpty else { return }
            guard let url = URL(string: urlString) else { return }
        }
    }
    
    func changeFontColor() {
        colorPickerAction = .fontColor(color: .clear)
        showColorPickerVC()
    }
    
    func changeHighlightColor() {
        colorPickerAction = .highlightColor(color: .clear)
        showColorPickerVC()
    }
    
    func changeFontName() {
        showFontSelectorVc { [weak self] fontName in
            guard let `self` = self else { return }
            let currentFont = viewModel.font
            guard let newFont = UIFont(name: fontName, size: currentFont.pointSize) else { return }
            self.applyAttribute(.font, value: newFont)
        }
    }
    
    func changeFontSize() {
        showFontSizeInputVc { [weak self] size in
            guard let `self` = self else { return }
            let currentFont = viewModel.font
            guard let newFont = UIFont(name: currentFont.fontName, size: size) else { return }
            self.applyAttribute(.font, value: newFont)
        }
    }

    func applyParagraphStyle(modifier: (NSMutableParagraphStyle) -> Void) {
        guard let range = textView.selectedTextRange else { return }
        let nsRange = textView.textRangeToNSRange(range)
        textView.textStorage.beginEditing()
        // 创建一个新的 NSMutableParagraphStyle 对象并应用修改器
        let newParagraphStyle = NSMutableParagraphStyle()
        modifier(newParagraphStyle)
        // 在选中范围内应用新的段落样式
        textView.textStorage.addAttribute(.paragraphStyle, value: newParagraphStyle, range: nsRange)
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
        viewModel.transform(inputEvent: .addAttribute(key: attribute, value: value))
    }
}

//MARK: - UIColorPickerViewControllerDelegate 處理文字顏色選擇後的動作
extension TextEditorViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor
        let attribute:  NSAttributedString.Key
        switch colorPickerAction {
        case .fontColor:
            attribute = .foregroundColor
        case .highlightColor:
            attribute = .backgroundColor
        default: return
        }
        applyAttribute(attribute, value: selectedColor)
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
            viewModel.transform(inputEvent: .reapplyTypingAttributes)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}


