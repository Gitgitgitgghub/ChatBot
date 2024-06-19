//
//  LoadingView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import UIKit

class LoadingView: UIView {

    lazy var indecator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var label: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    init(messgae: String = "讀取中請稍候") {
        super.init(frame: .zero)
        self.label.text = messgae
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        layer.cornerRadius = 10
        layer.masksToBounds = true
        addSubview(indecator)
        addSubview(label)
        indecator.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(30)
        }
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(indecator.snp.bottom)
        }
        indecator.startAnimating()
    }
    
}
