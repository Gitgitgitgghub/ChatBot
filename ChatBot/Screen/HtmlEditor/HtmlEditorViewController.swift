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
    
    let webView = WKWebView()
        .apply { webView in
            webView.translatesAutoresizingMaskIntoConstraints = false
        }
    let saveButton = UIButton(type: .custom).apply { button in
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("保存", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
    }
    let discardButton = UIButton(type: .custom).apply { button in
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("放棄", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
    }
    var attr: NSAttributedString
    weak var delegate: HtmlEditorViewControllerDelegate?
    
    init(attr: NSAttributedString, delegate: HtmlEditorViewControllerDelegate) {
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
        if let htmlContent = attr.toHTML() {
            print("[DEBUG]: \(#function) \(htmlContent)")
            if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
                do {
                    var html = try String(contentsOfFile: htmlPath, encoding: .utf8)
                    html = html.replacingOccurrences(of: "<div id=\"content\"></div>", with: "<div id=\"content\">\(htmlContent)</div>")
                    webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
                } catch {
                    print("Error loading HTML file: \(error)")
                }
            }
        }
//        let htmlContent = NSAttributedString(string: godzilla)
//        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
//            do {
//                var html = try String(contentsOfFile: htmlPath, encoding: .utf8)
//                html = html.replacingOccurrences(of: "<div id=\"content\"></div>", with: "<div id=\"content\">\(htmlContent)</div>")
//                webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
//            } catch {
//                print("Error loading HTML file: \(error)")
//            }
//        }
    }
    
    private func initUI() {
        view.addSubview(saveButton)
        view.addSubview(discardButton)
        view.addSubview(webView)
        saveButton.snp.makeConstraints { make in
            make.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.size.equalTo(CGSize(width: 100, height: 50))
        }
        discardButton.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.size.equalTo(CGSize(width: 100, height: 50))
        }
        webView.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        discardButton.addTarget(self, action: #selector(discard), for: .touchUpInside)
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
