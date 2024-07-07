//
//  BaseViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/7.
//

import Foundation
import Combine


/// 定義viewModel基本架構
protocol ViewModelProtocol {
    /// 定義輸入事件
    associatedtype Input
    /// 定義輸出事件
    associatedtype Output
    var inputSubject: PassthroughSubject<Input, Error> { get }
    var outputSubject: PassthroughSubject<Output, Error> { get }
    var subscriptions: Set<AnyCancellable> { set get }
}

/// BaseViewModel
/// 這邊<I, O>是因為我還不確定ViewModelProtocol定義的associatedtype: Input, Input，想交給繼承的類實踐
/// 利用generic利用型別推導把associatedtype再抽象一次
class BaseViewModel<I, O>: NSObject, ViewModelProtocol {
    
    private let _inputSubject = PassthroughSubject<I, any Error>()
    private let _outputSubject = PassthroughSubject<O, any Error>()
    private let _subscriptions = Set<AnyCancellable>()
    var inputSubject: PassthroughSubject<I, any Error> {
        return _inputSubject
    }
    var outputSubject: PassthroughSubject<O, any Error> {
        return _outputSubject
    }
    var subscriptions: Set<AnyCancellable> {
        set {
            
        }
        get {
            return _subscriptions
        }
    }
    
    deinit {
        subscriptions.removeAll()
        print("\(className) deinit")
    }
}


