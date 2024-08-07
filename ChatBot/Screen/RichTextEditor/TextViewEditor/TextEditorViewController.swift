//
//  TextEditorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/31.
//

import Foundation
import UIKit
import Photos

protocol TextEditorViewControllerDelegate: AnyObject {
    
    func onSave(title: String?,attributedString: NSAttributedString?)
    
}


class TextEditorViewController: BaseUIViewController, TextEditorViewsProtocol {
    
    typealias Action = ActionUIStatusModel.Action
    
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
    var colorPickerAction: Action = .fontColor
    
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
        observeKeyboard()
    }
    
    override func keyboardHide(_ notification: Notification) {
        views.updateTextViewBottomConstraint(keyboardHeight: 0)
    }
    
    override func keyboardShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        views.updateTextViewBottomConstraint(keyboardHeight: keyboardHeight)
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
        var attr: NSAttributedString?
        if let content = self.content {
            attr = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: content)
        }else {
            attr = .init(string: "", attributes: nil)
        }
        textView.attributedText = attr
        textView.backgroundColor = inputBackgroundColor
        textView.linkTextAttributes = [.font: SystemDefine.Message.defaultTextFont,
                                       .foregroundColor: UIColor.systemRed,
                                       .underlineColor: UIColor.systemRed,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.typingAttributes = viewModel.typingAttributes
        textView.tintColor = .white
    }
    
    @objc private func save() {
        // 如果content是nil代表是新增筆記需要一個title
        if content == nil {
            showNoteTitleInputView { [weak self] noteTitle in
                guard let `self` = self else { return }
                self.delegate?.onSave(title: noteTitle, attributedString: self.textView.attributedText)
                self.navigationController?.popViewController(animated: true)
            }
        }else {
            delegate?.onSave(title: nil, attributedString: self.textView.attributedText)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func getActionUIStatus() -> ActionUIStatusModel {
        return viewModel.actionUIStatusModel
    }
    
    func getActions() -> [Action] {
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
    
    /// 顯示儲存筆記輸入title的alertVC
    private func showNoteTitleInputView(completion: @escaping (_ noteTitle: String?) -> ()) {
        let vc = UIAlertController(title: "儲存筆記", message: "請輸入標題", preferredStyle: .alert)
        vc.addTextField { textField in
            textField.text = "我的筆記"
        }
        vc.addAction(.init(title: "保存", style: .default, handler: { action in
            completion(vc.textFields?.first?.text)
        }))
        vc.addAction(.init(title: "取消", style: .cancel))
        present(vc, animated: true)
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
        applyAttribute(.underlineStyle, value: viewModel.actionUIStatusModel.underlineStyle)
    }
    
    func makeStrikethrough() {
        applyAttribute(.strikethroughStyle, value: viewModel.actionUIStatusModel.strikethroughLineStyle)
    }

    func alignLeft() {
        applyParagraphStyle(alignment: .left)
    }

    func alignCenter() {
        applyParagraphStyle(alignment: .center)
    }

    func alignRight() {
        applyParagraphStyle(alignment: .right)
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
        showImageSelectionAlert { [weak self] urlString in
            guard let urlString = urlString, urlString.isNotEmpty else { return }
            guard let url = URL(string: urlString) else { return }
            self?.addImage(url: url)
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

    func applyParagraphStyle(alignment: NSTextAlignment) {
        let newParagraphStyle = NSMutableParagraphStyle()
        newParagraphStyle.alignment = alignment
        applyAttribute(.paragraphStyle, value: newParagraphStyle)
        //alignCursor(to: alignment)
    }
    
    func alignCursor(to: NSTextAlignment) {
        guard let range = textView.selectedTextRange else { return }
        let nsRange = textView.textRangeToNSRange(range)
        if nsRange.length == 0 {
            let position: UITextPosition?
            switch to {
            case .left:
                position = textView.beginningOfDocument
            case .center:
                position = textView.position(from: textView.beginningOfDocument, offset: textView.text.count / 2)
            case .right:
                position = textView.endOfDocument
            default:
                position = nil
            }
            if let position = position {
                textView.selectedTextRange = textView.textRange(from: position, to: position)
            }
        }
    }
    
    func applyAttribute(_ attribute: NSAttributedString.Key, value: Any) {
        guard let range = textView.selectedTextRange else { return }
        let nsRange = textView.textRangeToNSRange(range)
        textView.textStorage.beginEditing()
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
        textView.textStorage.endEditing()
        viewModel.transform(inputEvent: .addAttribute(key: attribute, value: value))
    }
}

//MARK: - UIColorPickerViewControllerDelegate 處理文字顏色選擇後的動作
extension TextEditorViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        viewController.dismiss(animated: true)
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
        guard let asset = info[.phAsset] as? PHAsset else { return }
        ImageManager.shared.requestImage(for: asset)
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                guard let fileURL = url else { return }
                self?.addImage(url: fileURL)
            }
            .store(in: &subscriptions)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func addImage(url: URL) {
        let attachment = RemoteImageTextAttachment(imageURL: url, displaySize: .init(width: UIScreen.main.bounds.width - 36, height: 210))
        let selectedRange = textView.selectedRange
        let attachmentString = NSAttributedString(attachment: attachment)
        textView.textStorage.beginEditing()
        textView.textStorage.insert(attachmentString, at: selectedRange.location)
        let newRange = NSRange(location: selectedRange.location, length: attachmentString.length)
        textView.textStorage.addAttributes(viewModel.typingAttributes, range: newRange)
        textView.textStorage.endEditing()
        textView.moveCursorToEnd()
    }
}


