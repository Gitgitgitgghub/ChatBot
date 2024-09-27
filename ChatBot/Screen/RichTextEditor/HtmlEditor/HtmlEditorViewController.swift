//
//  HtmlEditorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/19.
//

import Foundation
import WebKit
import Photos
import ZMarkupParser

class HtmlEditorViewController: BaseUIViewController<BaseViewModel<Any, Any>> {
    
    lazy var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        .apply { webView in
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            webView.scrollView.bouncesZoom = false
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.configuration.userContentController = .init()
            webView.configuration.userContentController.add(self, name: "task")
            webView.configuration.userContentController.add(self, name: "consoleLog")
            webView.navigationDelegate = self
        }
    var content: Data?
    var inputBackgroundColor: UIColor
    var completion: ((_ result: NSAttributedString?) -> ())?
    
    /// webview call
    enum Task: String, CaseIterable {
        /// 保存
        case save
        /// 放棄
        case discard
        /// 添加圖片
        case addImage
    }
    
    init(content: Data?, inputBackgroundColor: UIColor, completion: @escaping ((_ result: NSAttributedString?) -> ())) {
        self.content = content
        self.completion = completion
        self.inputBackgroundColor = inputBackgroundColor
        super.init(viewModel: .init())
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
    
    override func keyboardShow(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            webView.scrollView.contentInset.bottom = keyboardHeight
            webView.scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    override func keyboardHide(_ notification: Notification) {
        webView.scrollView.contentInset.bottom = 0
        webView.scrollView.verticalScrollIndicatorInsets.bottom = 0
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
    
    @objc private func save() {
        webView.evaluateJavaScript("document.getElementById('text-input').innerHTML") { [weak self] result, error in
            if let htmlContent = result as? String, let attr = NSMutableAttributedString(htmlString: htmlContent)?.convertPx2Px() {
                print("save: \(htmlContent)")
                self?.completion?(attr)
            } else if let error = error {
                print("[DEBUG]: \(#function) \(error.localizedDescription)")
            }
        }
        discard()
    }
    
    @objc private func discard() {
        dismiss(animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - WKNavigationDelegate
extension HtmlEditorViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadContent()
        updateAllImageSrcs()
        replaceTextInputBackgroundColor()
        replaceFontStyle()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView錯誤: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView加載錯誤: \(error.localizedDescription)")
    }
    
    private func loadContent() {
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
    
    // 获取 HTML 内容中的所有图片 src，并逐一替换
    private func updateAllImageSrcs() {
        let script = """
           var srcs = [];
           var images = document.getElementsByTagName('img');
           for (var i = 0; i < images.length; i++) {
               srcs.push(images[i].src);
           }
           srcs;
           """
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("获取图片 src 失败: \(error)")
                return
            }
            
            guard let srcArray = result as? [String] else {
                print("无法解析图片 src")
                return
            }
            for src in srcArray {
                if let oldURL = URL(string: src), let newSrc = ImageManager.shared.getNewImageURLString(from: oldURL) {
                    self.replaceImageSrc(oldSrc: src, newSrc: newSrc)
                }
            }
        }
    }
    
    /// 替换特定图片的路径
    private func replaceImageSrc(oldSrc: String, newSrc: String) {
        let script = """
        var images = document.getElementsByTagName('img');
        for (var i = 0; i < images.length; i++) {
            if (images[i].src === '\(oldSrc)') {
                images[i].src = '\(newSrc)';
            }
        }
        """
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript 执行失败: \(error)")
            } else {
                print("图片路径替换成功")
            }
        }
    }
    
    /// 更改輸入區域的背景顏色
    func replaceTextInputBackgroundColor() {
        let color = inputBackgroundColor.hexColor
        let cssString = "#text-input { background-color: \(color); }"
        injectCSS(cssString: cssString)
    }
    
    /// 替換有關字型的css
    func replaceFontStyle() {
        var fontSize = "3"
        var fontColor = "#ffffff"
        var face = "Arial"
        if let content = self.content, let htmlString = String(data: content, encoding: .utf8) {
            let selector = ZHTMLParserBuilder.initWithDefault().build().selector(htmlString)
            if let font = selector.first(.font)?.get() as? [String:Any],
               let attributes = font["attributes"] as? [String:Any] {
                fontSize = attributes["size"] as? String ?? "3"
                fontColor = attributes["color"] as? String ?? "#ffffff"
                face = attributes["color"] as? String ?? "Arial"
            }
        }
        replaceFontSize(size: fontSize)
        replaceFontColor(fontColor: fontColor)
        replaceFontName(face: face)
    }
    
    /// 替換預設字體大小
    func replaceFontSize(size: String) {
        let jsString = """
        fontSizeRef.value = \(size);
        """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    /// 替換預設字體顏色
    func replaceFontColor(fontColor: String) {
        let jsString = """
                var colorInput = document.getElementById('foreColor');
                if (colorInput) {
                    colorInput.value = '\(fontColor)';
                    var event = new Event('change');
                    colorInput.dispatchEvent(event);
                }
                """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    /// 替換字型
    func replaceFontName(face: String) {
        let jsString = """
                var options = fontName.getElementsByTagName('option');
                for (var i = 0; i < options.length; i++) {
                    if (options[i].value === '\(face)') {
                        fontName.value = options[i].value;
                        break;
                    }
                }
                """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
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
    
    /// 注入css
    func injectCSS(cssString: String) {
        let jsString = """
        var style = document.createElement('style');
        style.innerHTML = '\(cssString)';
        document.head.appendChild(style);
        """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
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
                //let filePath = fileURL.path.replacingOccurrences(of: "file://", with: "")
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
