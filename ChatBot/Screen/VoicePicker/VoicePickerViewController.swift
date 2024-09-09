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
        button.cornerRadius = 8
        button.backgroundColor = .fromAppColors(\.lightCoffeeButton)
        button.setTitleColor(.fromAppColors(\.darkCoffeeText), for: .normal)
    }
    var closeButton = UIButton(type: .system).apply { button in
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("離開", for: .normal)
        button.cornerRadius = 8
        button.backgroundColor = .red.withAlphaComponent(0.6)
        button.setTitleColor(.white, for: .normal)
    }
    var contentView: UIView = UIView().apply { view in
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cornerRadius = 20
        view.backgroundColor = .systemBackground
    }
    var currentChineseVoiceLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .fromAppColors(\.normalText)
        label.textAlignment = .center
    }
    var currentEnglishVoiceLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .fromAppColors(\.normalText)
        label.textAlignment = .center
    }
    var chineseVoiceLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "中文語音"
        label.textAlignment = .center
        label.textColor = .fromAppColors(\.darkCoffeeText)
    }
    var englishVoiceLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "英文語音"
        label.textAlignment = .center
        label.textColor = .fromAppColors(\.darkCoffeeText)
    }
    var rateSlider = UISlider().apply { rateSlider in
        rateSlider.minimumValue = AVSpeechUtteranceMinimumSpeechRate
        rateSlider.maximumValue = AVSpeechUtteranceMaximumSpeechRate
        rateSlider.translatesAutoresizingMaskIntoConstraints = false
    }
    var pitchSlider = UISlider().apply { pitchSlider in
        pitchSlider.minimumValue = 0.5
        pitchSlider.maximumValue = 2.0
        pitchSlider.translatesAutoresizingMaskIntoConstraints = false
    }
    var rateLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .fromAppColors(\.darkCoffeeText)
        label.textAlignment = .center
    }
    var pitchLabel = UILabel().apply { label in
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .fromAppColors(\.darkCoffeeText)
        label.textAlignment = .center
    }
    var speakChineseButton = SpeakButton().apply { button in
        button.cornerRadius = 5
    }
    var speakEnglishButton = SpeakButton().apply { button in
        button.cornerRadius = 5
    }
    var playingVoiceComponent = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setDefaultValue()
    }
    
    private func initUI() {
        view.backgroundColor = .black.withAlphaComponent(0.6)
        view.addSubview(contentView)
        contentView.addSubview(chineseVoiceLabel)
        contentView.addSubview(englishVoiceLabel)
        contentView.addSubview(currentChineseVoiceLabel)
        contentView.addSubview(currentEnglishVoiceLabel)
        contentView.addSubview(pickerView)
        contentView.addSubview(rateLabel)
        contentView.addSubview(rateSlider)
        contentView.addSubview(pitchLabel)
        contentView.addSubview(pitchSlider)
        contentView.addSubview(speakChineseButton)
        contentView.addSubview(speakEnglishButton)
        contentView.addSubview(saveButton)
        contentView.addSubview(closeButton)
        pickerView.delegate = self
        pickerView.dataSource = self
        contentView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(550)
        }
        chineseVoiceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.top.equalToSuperview().inset(10)
            make.height.equalTo(20)
        }
        englishVoiceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.5)
            make.top.equalToSuperview().inset(10)
            make.height.equalTo(20)
        }
        currentChineseVoiceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.top.equalTo(chineseVoiceLabel.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        currentEnglishVoiceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.5)
            make.top.equalTo(englishVoiceLabel.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        pickerView.snp.makeConstraints { make in
            make.top.equalTo(currentEnglishVoiceLabel.snp.bottom).offset(15)
            make.height.equalTo(150)
            make.leading.trailing.equalToSuperview()
        }
        speakChineseButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 50, height: 50))
            make.centerX.equalTo(chineseVoiceLabel)
            make.top.equalTo(pickerView.snp.bottom).offset(15)
        }
        speakEnglishButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 50, height: 50))
            make.centerX.equalTo(englishVoiceLabel)
            make.top.equalTo(pickerView.snp.bottom).offset(15)
        }
        rateLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(speakEnglishButton.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        rateSlider.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(rateLabel.snp.bottom).offset(10)
            make.height.equalTo(20)
            make.leading.trailing.equalToSuperview().inset(50)
        }
        pitchLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(rateSlider.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        pitchSlider.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(pitchLabel.snp.bottom).offset(10)
            make.height.equalTo(20)
            make.leading.trailing.equalToSuperview().inset(50)
        }
        saveButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 100, height: 50))
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.centerX.equalToSuperview().multipliedBy(1.5)
        }
        closeButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 100, height: 50))
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.centerX.equalToSuperview().multipliedBy(0.5)
        }
        saveButton.addTarget(self, action: #selector(saveVoice), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        rateSlider.addTarget(self, action: #selector(rateSliderChanged(_:)), for: .valueChanged)
        pitchSlider.addTarget(self, action: #selector(pitchSliderChanged(_:)), for: .valueChanged)
        speakChineseButton.addTarget(self, action: #selector(onSpeakButtonClicked(sender:)), for: .touchUpInside)
        speakEnglishButton.addTarget(self, action: #selector(onSpeakButtonClicked(sender:)), for: .touchUpInside)
        voiceManager.delegate = self
    }
    
    /// 設定ＵＩ預設值
    private func setDefaultValue() {
        if let index = indexOfVoice(voiceId: voiceManager.voiceSetting.selectedChineseVoiceId, voices: voiceManager.chineseVoices) {
            currentChineseVoiceLabel.text = "當前: \(voiceManager.chineseVoices[index].displayName(number: index + 1))"
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
        if let index = indexOfVoice(voiceId: voiceManager.voiceSetting.selectedEnglishVoiceId, voices: voiceManager.englishVoices) {
            currentEnglishVoiceLabel.text = "當前: \(voiceManager.englishVoices[index].displayName(number: index + 1))"
            pickerView.selectRow(index, inComponent: 1, animated: false)
        }
        rateSlider.value = voiceManager.voiceSetting.voiceRate
        pitchSlider.value = voiceManager.voiceSetting.voicePitch
        rateSliderChanged(rateSlider)
        pitchSliderChanged(pitchSlider)
    }
    
    private func indexOfVoice(voiceId: String, voices :[AVSpeechSynthesisVoice]) -> Int? {
        return voices.firstIndex(where: { $0.identifier == voiceId })
    }
    
    /// 保存聲音檔
    @objc private func saveVoice() {
        voiceManager.saveVoice(chIndex: pickerView.selectedRow(inComponent: 0), engIndex: pickerView.selectedRow(inComponent: 1), rate: rateSlider.value, pitch: pitchSlider.value)
        close()
    }
    
    /// 離開不保存
    @objc private func close() {
        dismiss(animated: true)
    }
    
    @objc private func rateSliderChanged(_ sender: UISlider) {
        rateLabel.text = String(format: "語速: %.1f", sender.value)
    }
    
    @objc private func pitchSliderChanged(_ sender: UISlider) {
        pitchLabel.text = String(format: "語調: %.1f", sender.value)
    }
    
    /// 點選播放按鈕
    @objc private func onSpeakButtonClicked(sender: UIButton) {
        let component = sender == speakChineseButton ? 0 : 1
        speak(component: component)
    }
    
    private func speak(component: Int) {
        self.playingVoiceComponent = component
        switch component {
        case 0:
            let voice = voiceManager.chineseVoices[pickerView.selectedRow(inComponent: 0)]
            let utterance = AVSpeechUtterance(string: "賣苦棄養 test test")
            utterance.rate = rateSlider.value
            utterance.pitchMultiplier = pitchSlider.value
            voiceManager.speak(utterance: utterance, voice: voice)
        case 1:
            let voice = voiceManager.englishVoices[pickerView.selectedRow(inComponent: 1)]
            let utterance = AVSpeechUtterance(string: "hello, how are you?")
            utterance.rate = rateSlider.value
            utterance.pitchMultiplier = pitchSlider.value
            voiceManager.speak(utterance: utterance, voice: voice)
        default: break
        }
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
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let voice = (component == 0) ? voiceManager.chineseVoices[row] : voiceManager.englishVoices[row]
        return voice.displayName(number: row + 1)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        speak(component: component)
    }
}


//MARK: - AVSpeechSynthesizerDelegate
extension VoicePickerViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        //改變按鈕狀態
        switch playingVoiceComponent {
        case 0:
            speakChineseButton.isSelected = true
            speakEnglishButton.isSelected = false
        case 1:
            speakChineseButton.isSelected = false
            speakEnglishButton.isSelected = true
        default: break
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        //改變按鈕狀態
        speakChineseButton.isSelected = false
        speakEnglishButton.isSelected = false
    }
    
}
