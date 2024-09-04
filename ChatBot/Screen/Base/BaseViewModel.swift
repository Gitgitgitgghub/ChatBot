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
    var inputSubject: PassthroughSubject<Input, Never> { get }
    var outputSubject: PassthroughSubject<Output, Never> { get }
    
    func transform(inputEvent: Input)
}

/// BaseViewModel
/// 這邊<I, O>是因為我還不確定ViewModelProtocol定義的associatedtype: Input, Input，想交給繼承的類實踐
/// 利用generic利用型別推導把associatedtype再抽象一次
class BaseViewModel<I, O>: NSObject, ViewModelProtocol {
    
    private let _inputSubject = PassthroughSubject<I, Never>()
    private let _outputSubject = PassthroughSubject<O, Never>()
    var subscriptions = Set<AnyCancellable>()
    var inputSubject: PassthroughSubject<I, Never> {
        return _inputSubject
    }
    var outputSubject: PassthroughSubject<O, Never> {
        return _outputSubject
    }
    @Published var loadingStatus = CurrentValueSubject<LoadingStatus, Never>(.none)
    
    func transform(inputEvent: I) {
        inputSubject.send(inputEvent)
    }
    
    func performAction<T>(_ publisher: AnyPublisher<T, Error>, message: String = "") -> AnyPublisher<T, Error> {
        return publisher
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.loadingStatus.send(.loading(message: message))
            }, receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.loadingStatus.send(.success)
                case .failure(let error):
                    self?.loadingStatus.send(.error(error: error))
                }
            })
            .eraseToAnyPublisher()
    }
    
    deinit {
        subscriptions.removeAll()
        print("\(className) deinit")
    }
}


