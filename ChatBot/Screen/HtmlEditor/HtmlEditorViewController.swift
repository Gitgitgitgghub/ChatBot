//
//  HtmlEditorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/19.
//

import Foundation
import WebKit

protocol HtmlEditorViewControllerDelegate: AnyObject {
    
    func didSaveAttributedString(attributedString: NSAttributedString)
    
}

class HtmlEditorViewController: BaseUIViewController {
    
    lazy var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        .apply { webView in
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.configuration.userContentController = .init()
            webView.configuration.userContentController.add(self, name: "task")
        }
    var attr: NSAttributedString?
    weak var delegate: HtmlEditorViewControllerDelegate?
    
    /// webview call
    enum Task: String, CaseIterable {
        /// 保存
        case save
        /// 放棄
        case discard
    }
    
    init(attr: NSAttributedString?, delegate: HtmlEditorViewControllerDelegate) {
        self.attr = attr
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        loadWebView()
    }
    
    private func loadWebView() {
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") else { return }
        do {
            var html = try String(contentsOfFile: htmlPath, encoding: .utf8)
            if let htmlContent = attr?.toHTML() {
                print("load: \(htmlContent)")
                html = html.replacingOccurrences(of: "<div id=\"content\"></div>", with: "<div id=\"content\">\(htmlContent)</div>")
            }
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
    
    private func convertHTMLToAttributedString(html: String) {
        guard let data = html.data(using: .utf8) else { return }
        if let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
            delegate?.didSaveAttributedString(attributedString: attr)
        }else {
            print("[DEBUG]: \(#function) error")
        }
    }
    
    @objc private func save() {
        webView.evaluateJavaScript("document.getElementById('text-input').innerHTML") { [weak self] result, error in
            if let htmlContent = result as? String {
                print("save: \(htmlContent)")
                self?.convertHTMLToAttributedString(html: htmlContent)
            } else if let error = error {
                print("[DEBUG]: \(#function) \(error.localizedDescription)")
            }
        }
        discard()
    }
    
    @objc private func discard() {
        dismiss(animated: true)
    }
}

//MARK: - WKScriptMessageHandler實作webview與vc溝通
extension HtmlEditorViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String, let task = Task(rawValue: body) else { return }
        switch task {
        case .save:
            save()
        case .discard:
            discard()
        }
    }
    
}
