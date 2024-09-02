//
//  LoadingView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/20.
//

import UIKit
import NVActivityIndicatorView

class LoadingView: UIView {

    let nvActivityIndicatorView = NVActivityIndicatorView(frame: .zero).apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    let messageLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
    }
    
    init(frame: CGRect, type: NVActivityIndicatorType = .ballClipRotate, color: UIColor = .white, padding: CGFloat = .zero) {
        super.init(frame: frame)
        nvActivityIndicatorView.frame = frame
        nvActivityIndicatorView.type = type
        nvActivityIndicatorView.color = color
        nvActivityIndicatorView.padding = padding
        initUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }

    private func initUI() {
        backgroundColor = .black.withAlphaComponent(0.8)
        cornerRadius = 10
        isVisible = false
        addSubview(nvActivityIndicatorView)
        addSubview(messageLabel)
        nvActivityIndicatorView.snp.makeConstraints { make in
            make.size.equalTo(nvActivityIndicatorView.frame.size)
            make.center.equalToSuperview()
        }
        messageLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(15)
            make.leading.trailing.equalToSuperview().inset(5)
        }
    }

    func show(withMessage: String = "載入中") {
        isVisible = true
        nvActivityIndicatorView.startAnimating()
        messageLabel.text = withMessage
    }

    func hide() {
        isVisible = false
        nvActivityIndicatorView.stopAnimating()
    }
}



