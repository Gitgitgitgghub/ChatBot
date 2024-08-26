//
//  TimerManager.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/26.
//

import Combine
import Foundation

class TimerManager {
    private var timerSubscription: Cancellable?
    private var timerPublisher: Timer.TimerPublisher?
    private var interval: TimeInterval
    
    @Published var counter: Int = 0
    
    init(interval: TimeInterval = 1.0) {
        self.interval = interval
    }
    
    deinit {
        stopTimer()
    }
    
    /// 啟動
    func startTimer() {
        timerPublisher = Timer.publish(every: interval, on: .main, in: .common)
        timerSubscription = timerPublisher?
            .autoconnect()
            .sink { [weak self] _ in
                self?.counter += 1
                print("Timer fired: \(self?.counter ?? 0)")
            }
    }
    
    /// 停止
    func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    /// 重置
    func resetTimer() {
        stopTimer()
        counter = 0
    }
}


