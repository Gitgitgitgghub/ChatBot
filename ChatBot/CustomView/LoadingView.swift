//
//  LoadingView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/20.
//

import UIKit

class LoadingView: UIView {

    private let spinnerLayer = CAShapeLayer()
    private let messageLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }

    private func initUI() {
        backgroundColor = UIColor(white: 0, alpha: 0.7)
        cornerRadius = 10
        setupSpinnerLayer()
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(15)
            make.leading.trailing.equalToSuperview().inset(5)
        }
    }

    private func setupSpinnerLayer() {
        let radius: CGFloat = 20
        let circularPath = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        spinnerLayer.path = circularPath.cgPath
        spinnerLayer.strokeColor = UIColor.white.cgColor
        spinnerLayer.lineWidth = 5
        spinnerLayer.fillColor = UIColor.clear.cgColor
        spinnerLayer.lineCap = .round
        spinnerLayer.strokeStart = 0
        spinnerLayer.strokeEnd = 0.75
        spinnerLayer.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        layer.addSublayer(spinnerLayer)
        startSpinning()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        spinnerLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }

    private func startSpinning() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = 2 * CGFloat.pi
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        spinnerLayer.add(rotation, forKey: "rotationAnimation")
    }

    func show(in view: UIView, withMessage: String = "載入中") {
        frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        center = view.center
        view.addSubview(self)
        messageLabel.text = withMessage
    }

    func hide() {
        removeFromSuperview()
    }
}



