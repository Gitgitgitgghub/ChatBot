//
//  VoicePickerViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/10.
//

import UIKit
import AVFoundation

class VoicePickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let voiceManager = SpeechVoiceManager.shared
    var pickerView: UIPickerView = UIPickerView().apply { pickerView in
        pickerView.translatesAutoresizingMaskIntoConstraints = false
    }
    var saveButton = UIButton(type: .system).apply { button in
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("保存", for: .normal)
    }
    var contentView: UIView = UIView().apply { view in
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cornerRadius = 20
    }
    var chineseVoiceLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "中文語音"
        label.textAlignment = .center
        label.textColor = .darkGray
    }
    var englishVoiceLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "英文語音"
        label.textAlignment = .center
        label.textColor = .darkGray
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    private func initUI() {
        view.backgroundColor = .black.withAlphaComponent(0.6)
        view.addSubview(contentView)
        contentView.addSubview(chineseVoiceLabel)
        contentView.addSubview(englishVoiceLabel)
        contentView.addSubview(pickerView)
        contentView.addSubview(saveButton)
        pickerView.delegate = self
        pickerView.dataSource = self
        contentView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(350)
        }
        chineseVoiceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.top.equalToSuperview().inset(50)
        }
        englishVoiceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.5)
            make.top.equalToSuperview().inset(50)
        }
        pickerView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(50)
            make.bottom.equalToSuperview().inset(100)
            make.leading.trailing.equalToSuperview()
        }
        saveButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 100, height: 50))
            make.top.equalTo(pickerView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
    }
    
    //TODO: - 保存聲音檔
    @objc private func save() {
        dismiss(animated: true)
    }
    
    /// 播放選中的聲音
    private func speakVoice(row: Int, component: Int) {
        let voice = (component == 0) ? voiceManager.chineseVoices[row] : voiceManager.englishVoices[row]
        let utterance = (component == 0) ? AVSpeechUtterance(string: "賣苦棄養") : AVSpeechUtterance(string: "hello, how are you?")
        voiceManager.speak(utterance: utterance, voice: voice)
    }
    
    // MARK: - UIPickerViewDataSource, UIPickerViewDelegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // 左中文，右英文
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return voiceManager.chineseVoices.count
        } else {
            return voiceManager.englishVoices.count
        }
    }
    
//    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
//        <#code#>
//    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let voice = (component == 0) ? voiceManager.chineseVoices[row] : voiceManager.englishVoices[row]
        return voice.countryName + voice.displayGender + " \(row + 1)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        speakVoice(row: row, component: component)
    }
}
