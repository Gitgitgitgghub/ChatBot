//
//  RecordingView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/18.
//

import Foundation
import UIKit
import AVFoundation


protocol RecordingViewDelegate: AnyObject {
    
    func startRecording()
    
    func stopRecording()
    
}

class RecordingView: UIView, AVAudioRecorderDelegate {
    
    let startRecordingButton = UIButton(type: .custom).apply {
        $0.backgroundColor = .fromAppColors(\.lightCoffeeButton)
        $0.cornerRadius = 25
        $0.setTitleColor(.fromAppColors(\.darkCoffeeText), for: .normal)
    }
    let volumeProgressView = UIProgressView(progressViewStyle: .default).apply {
        $0.trackTintColor = .fromAppColors(\.secondaryButtonBackground)
        $0.progressTintColor = .fromAppColors(\.darkCoffeeText)
    }
    let contentView = UIView().apply {
        $0.backgroundColor = .systemBackground
        $0.cornerRadius = 15
    }
    var isRecording = false
    weak var delegate:RecordingViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(contentView)
        contentView.addSubview(startRecordingButton)
        contentView.addSubview(volumeProgressView)
        contentView.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(150)
            make.center.equalToSuperview()
        }
        startRecordingButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.75)
            make.size.equalTo(CGSize(width: 100, height: 50))
        }
        volumeProgressView.snp.makeConstraints { make in
            make.top.equalTo(startRecordingButton.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        // 設置基底
        isUserInteractionEnabled = true
        backgroundColor = .black.withAlphaComponent(0.4)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundClicked)))
        // 設置錄音按鈕
        startRecordingButton.setTitle("開始錄音", for: .normal)
        startRecordingButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        // 設置音量進度條
        volumeProgressView.progress = 0.0
    }
    
    @objc private func backgroundClicked() {
        isVisible = false
    }
    
    @objc private func recordButtonTapped() {
        if isRecording {
            startRecordingButton.setTitle("開始錄音", for: .normal)
            delegate?.startRecording()
        } else {
            startRecordingButton.setTitle("停止錄音", for: .normal)
            delegate?.stopRecording()
        }
        isRecording.toggle()
    }
    
    
}
