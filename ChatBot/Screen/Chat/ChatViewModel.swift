//
//  ChatViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import OpenAI
import Combine

class ChatViewModel: ObservableObject {
    
    private let openai: OpenAIProtocol
    private var cancellables = Set<AnyCancellable>()
    private var subscription: AnyCancellable?
    var messagesSubject = CurrentValueSubject<[MessageModel], Never>([])
    var messages: AnyPublisher<[MessageModel], Never> {
        get {
            return messagesSubject
                .eraseToAnyPublisher()
        }
    }
    private var requestCountSubject = CurrentValueSubject<Int, Never>(0)
    var requestCount: AnyPublisher<Int, Never> {
        get {
            return requestCountSubject.eraseToAnyPublisher()
        }
    }
    private let inputSubject = PassthroughSubject<InputEvent, Never>()
    
    enum InputEvent {
        case sendMessage(message: String)
    }
    
    init(openai: OpenAIProtocol) {
        self.openai = openai
    }
    
    func bindInput() {
        inputSubject
            .sink { completion in
                
            } receiveValue: { [unowned self] event in
                switch event {
                case .sendMessage(message: let message):
                    self.sendMessage(message: message)
                }
            }
            .store(in: &cancellables)
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
    private func sendMessage(message: String) {
        let subject = PassthroughSubject<MessageModel, Never>()
        let userMessage = MessageModel(message: message, isUser: true)
        let taskId = (0...100).randomElement() ?? -1
        subject
            .throttle(for: .seconds(1), scheduler: DispatchSerialQueue.main, latest: true)
            .setFailureType(to: Error.self)
            .handleEvents(receiveSubscription: { [unowned self] _ in
                self.messagesSubject.send(self.messagesSubject.value + [userMessage])
                print("receiveSubscription: \(taskId)")
            }, receiveOutput: { _ in
                print("receiveOutput")
            }, receiveCompletion: { completion in
                print("receiveCompletion \(completion)")
            }, receiveCancel: { [unowned self] in
                print("receiveCancel: \(taskId)")
                self.messagesSubject.value.removeAll(where: { $0.id == userMessage.id })
            }, receiveRequest: { demand in
                print("receiveRequest \(demand)")
            })
            .flatMap{ [unowned self] messageModel in
                return self.openai.chatQuery(message: message)
            }
            .sink(receiveCompletion: { _ in
                print("receiveCompletion")
            }, receiveValue: { [unowned self] result in
                print("receive Value thread: \(Thread.current)")
                let systemMessage = MessageModel(message:  result.choices.first?.message.content?.string ?? "", isUser: false)
                self.messagesSubject.send(self.messagesSubject.value + [systemMessage])
                self.requestCountSubject.value += 1
            })
            .store(in: &cancellables)
        subject.send(userMessage)
    }
    
}
