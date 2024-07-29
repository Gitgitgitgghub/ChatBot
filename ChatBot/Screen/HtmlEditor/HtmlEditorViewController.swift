//
//  HtmlEditorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/19.
//

import Foundation
import WebKit
import Photos

protocol HtmlEditorViewControllerDelegate: AnyObject {
    
    func didSaveAttributedString(innerHtml: String)
    
}

class HtmlEditorViewController: BaseUIViewController {
    
    lazy var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        .apply { webView in
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.configuration.userContentController = .init()
            webView.configuration.userContentController.add(self, name: "task")
            webView.configuration.userContentController.add(self, name: "consoleLog")
            webView.navigationDelegate = self
        }
    var content: Data?
    weak var delegate: HtmlEditorViewControllerDelegate?
    
    /// webview call
    enum Task: String, CaseIterable {
        /// 保存
        case save
        /// 放棄
        case discard
        /// 添加圖片
        case addImage
    }
    
    init(content: Data?, delegate: HtmlEditorViewControllerDelegate) {
        self.content = content
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        //observeKeyboard()
        loadWebView()
    }
    
    private func loadWebView() {
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") else { return }
        do {
            let html = try String(contentsOfFile: htmlPath, encoding: .utf8)
            webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        } catch {
            print("Error loading HTML file: \(error)")
        }
    }
    
    private func initUI() {
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func save() {
        webView.evaluateJavaScript("document.getElementById('text-input').innerHTML") { [weak self] result, error in
            if let htmlContent = result as? String {
                print("save: \(htmlContent)")
                self?.delegate?.didSaveAttributedString(innerHtml: htmlContent)
            } else if let error = error {
                print("[DEBUG]: \(#function) \(error.localizedDescription)")
            }
        }
        discard()
    }
    
    @objc private func discard() {
        dismiss(animated: true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            webView.scrollView.contentInset.bottom = keyboardHeight
            webView.scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        webView.scrollView.contentInset.bottom = 0
        webView.scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension HtmlEditorViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let content = self.content else { return }
        // 将 Data 转换为字符串
        if let dynamicData = String(data: content, encoding: .utf8) {
            // 使用 JavaScript 将动态数据插入到指定容器中
            let js = """
                document.getElementById('text-input').innerHTML = `\(dynamicData)`;
                """
            webView.evaluateJavaScript(js) { (result, error) in
                if let error = error {
                    print("JavaScript evaluation error: \(error)")
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView錯誤: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView加載錯誤: \(error.localizedDescription)")
    }
}

//MARK: - WKScriptMessageHandler實作webview與vc溝通
extension HtmlEditorViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "consoleLog" {
            print("Console訊息: \(message.body)")
        }
        guard let body = message.body as? String, let task = Task(rawValue: body) else { return }
        switch task {
        case .save:
            save()
        case .discard:
            discard()
        case .addImage:
            showImageSelectionAlert()
        }
    }
    
}

//MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate 處理從本地選擇圖片
extension HtmlEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let asset = info[.phAsset] as? PHAsset else { return }
        ImageManager.shared.requestImage(for: asset)
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                guard let fileURL = url else { return }
                // 插入圖片到 webView
                let javascript = "insertImage('\(fileURL.absoluteString)')"
                self?.webView.evaluateJavaScript(javascript, completionHandler: nil)
            }
            .store(in: &subscriptions)
    }
    
    /// 顯示插入圖片來源ＵＩ
    private func showImageSelectionAlert() {
        let alert = UIAlertController(title: "選擇圖片", message: "請選擇一種方式添加圖片", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "輸入網址", style: .default, handler: { _ in
            self.promptForImageURL()
        }))
        alert.addAction(UIAlertAction(title: "從相簿選擇", style: .default, handler: { _ in
            self.requestPhotoLibraryAccess { [weak self] in
                self?.selectImageFromGallery()
            }
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// 顯示輸入圖片網址ＵＩ
    private func promptForImageURL() {
        let alert = UIAlertController(title: "輸入圖片網址", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "圖片網址"
        }
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { [weak alert] _ in
            if let url = alert?.textFields?.first?.text {
                self.webView.evaluateJavaScript("insertImage('\(url)')", completionHandler: nil)
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
}
