//
//  BaseViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/7.
//

import Foundation
import Combine




/// 定義viewModel基本架構
protocol ViewModelProtocol: AnyObject {
    
    /// 定義輸入事件
    associatedtype Input
    /// 定義輸出事件
    associatedtype Output
    
    init()
    
    var inputSubject: PassthroughSubject<Input, Never> { get }
    var outputSubject: PassthroughSubject<Output, Never> { get }
    var loadingStatus: CurrentValueSubject<LoadingStatus, Never> { get }
    
    func transform(inputEvent: Input)
    
    func handleInputEvent(inputEvent: Input)
    
    func sendOutputEvent(_ outputEvent: Output)
}

/// BaseViewModel
/// 這邊<I, O>是因為我還不確定ViewModelProtocol定義的associatedtype: Input, Input，想交給繼承的類實踐
/// 利用generic利用型別推導把associatedtype再抽象一次
class BaseViewModel<I, O>: NSObject, ViewModelProtocol {
    
    var inputSubject = PassthroughSubject<I, Never>()
    var outputSubject = PassthroughSubject<O, Never>()
    var subscriptions = Set<AnyCancellable>()
    var loadingStatus = CurrentValueSubject<LoadingStatus, Never>(.none)
    
    required override init() {
        super.init()
        self.bindInputEvent()
    }
    
    deinit {
        subscriptions.removeAll()
        print("\(className) deinit")
    }
    
    private func bindInputEvent() {
        inputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                self?.handleInputEvent(inputEvent: event)
            }
            .store(in: &subscriptions)
    }
    
    func performAction<T>(_ publisher: AnyPublisher<T, Error>, message: String = "") -> AnyPublisher<T, Error> {
        loadingStatus.send(.loading(message: message))
        return publisher
            .receive(on: RunLoop.main)
            .handleEvents(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.loadingStatus.send(.success)
                case .failure(let error):
                    self?.loadingStatus.send(.error(error: error))
                }
            })
            .eraseToAnyPublisher()
    }
    
    //MARK: - ViewModelProtocol
    func transform(inputEvent: I) {
        inputSubject.send(inputEvent)
    }
    
    func sendOutputEvent(_ outputEvent: O) {
        outputSubject.send(outputEvent)
    }
    
    func handleInputEvent(inputEvent: I) {
        fatalError("Subclasses must override `handleInputEvent`")
    }
    
}




