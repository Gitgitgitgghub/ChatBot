//
//  AudioManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/18.
//

import Foundation
import AVFAudio


protocol AudioManagerDelegate: AnyObject {
    
    func didFinishRecordingAt(at url: URL)
    
    func volumeChanged(decibels: Float)
    
}

class AudioManager: NSObject, AVAudioRecorderDelegate {
    
    static let shared = AudioManager()
    
    private(set) var audioRecorder: AVAudioRecorder?
    private(set) var timer: Timer?
    var audioPlayer: AVAudioPlayer?
    let settings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    weak var delegate: AudioManagerDelegate?
    
    private override init() {
        super.init()
        createConversationRecordDirectory()
    }
    
    private func createConversationRecordDirectory() {
        let fileManager = FileManager.default
        let conversationRecordDir = getDocumentsDirectory()
        if !fileManager.fileExists(atPath: conversationRecordDir.path) {
            do {
                try fileManager.createDirectory(at: conversationRecordDir, withIntermediateDirectories: true, attributes: nil)
                print("成功創建 conversationRecord 資料夾")
            } catch {
                print("創建資料夾失敗: \(error)")
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("conversationRecord")
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            let timestamp: TimeInterval = Date().timeIntervalSince1970
            let fileURL = getDocumentsDirectory().appendingPathComponent("recording_\(Int(timestamp)).m4a")
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            // 啟動定時器來更新音量條
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateVolumeMeter), userInfo: nil, repeats: true)
            print("開始錄音 \(fileURL)")
        } catch {
            print("錄音失敗")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
    }
    
    @objc private func updateVolumeMeter() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        let normalizedLevel = normalizedPowerLevel(fromDecibels: level)
        delegate?.volumeChanged(decibels: normalizedLevel)
    }
    
    /// 轉換為分貝
    private func normalizedPowerLevel(fromDecibels decibels: Float) -> Float {
        let threshold: Float = -40.0
        if decibels < threshold {
            return 0.0
        } else if decibels >= 0 {
            return 1.0
        } else {
            return (decibels + 80) / 80
        }
    }

    /// 將音頻數據保存到資料夾
    func saveAudioToDocumentsDirectory(data: Data) -> URL? {
        let timestamp: TimeInterval = Date().timeIntervalSince1970
        let documentsURL = getDocumentsDirectory()
        let fileURL = documentsURL.appendingPathComponent("audio_\(Int(timestamp)).m4a")
        do {
            try data.write(to: fileURL)
            print("成功保存音頻文件到: \(fileURL)")
            return fileURL
        } catch {
            print("保存音頻文件失敗: \(error)")
            return nil
        }
    }

    
    //MARK: - AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            delegate?.didFinishRecordingAt(at: recorder.url)
        }
    }
    
}

extension AudioManager : AudioPlayProtocol {
    
}
