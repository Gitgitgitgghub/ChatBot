//
//  AudioPlayProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/19.
//

import Foundation
import AVFoundation

protocol AudioPlayProtocol: AnyObject {
    
    var audioPlayer: AVAudioPlayer? { set get }
    
    /// 播放音頻
    func playAudio(from url: URL, repeatPlayback: Bool)
    /// 暫停播放
    func pauseAudio()
    /// 繼續播放
    func resumeAudio()
    /// 停止播放
    func stopAudio()
}

extension AudioPlayProtocol {
    
    // 播放音頻
    func playAudio(from url: URL, repeatPlayback: Bool = false) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            // 設置是否重複播放
            audioPlayer?.numberOfLoops = repeatPlayback ? -1 : 0

            audioPlayer?.play()
            print("正在播放音頻：\(url)")
        } catch {
            print("播放音頻失敗: \(error)")
        }
    }

    // 暫停播放
    func pauseAudio() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.pause()
            print("音頻暫停")
        }
    }

    // 繼續播放
    func resumeAudio() {
        if audioPlayer?.isPlaying == false {
            audioPlayer?.play()
            print("繼續播放音頻")
        }
    }

    // 停止播放
    func stopAudio() {
        audioPlayer?.stop()
        print("音頻停止")
    }
    
}
