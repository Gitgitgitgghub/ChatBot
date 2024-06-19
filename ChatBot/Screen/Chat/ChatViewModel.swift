//
//  ChatViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import OpenAI
import Combine

class ChatViewModel: NSObject {
    
    private let openai: OpenAIProtocol
    private var subscriptions = Set<AnyCancellable>()
    @Published var inputMessage: String?
    @Published var messages: [OpenAIResult] = []
    var messagesSubject = CurrentValueSubject<[MessageModel], Never>([])
    private let inputSubject = PassthroughSubject<InputEvent, Never>()

    
    /// 輸入事件
    enum InputEvent {
        case sendMessage
        case createImage
    }
    
    init(openai: OpenAIProtocol) {
        self.openai = openai
    }
    
    deinit {
        subscriptions.removeAll()
        print("\(className) deinit")
    }
    
    func bindInput() {
        inputSubject
            .filter { event in
                return event == .sendMessage && !unwrap(self.inputMessage, "").isEmpty
            }
            .map({ _ in
                return self.inputMessage!
            })
            .handleEvents(receiveSubscription: { _ in
                
            }, receiveOutput: { [weak self] output in
                self?.messages.append(.userChatQuery(message: output))
            })
            .flatMap { message in
                return self.openai.chatQuery(message: message)
            }
            .sink { _ in
                
            } receiveValue: { [weak self] chatResult in
                self?.messages.append(.chatResult(data: chatResult))
            }
            .store(in: &subscriptions)
        inputSubject
            .filter { event in
                return event == .createImage && !unwrap(self.inputMessage, "").isEmpty
            }
            .map({ _ in
                return self.inputMessage!
            })
            .handleEvents(receiveSubscription: { _ in
                
            }, receiveOutput: { [weak self] output in
                self?.messages.append(.userChatQuery(message: output))
            })
            .flatMap { message in
                return self.openai.createImage(prompt: message, size: ._1024)
            }
            .sink { _ in
                
            } receiveValue: { [weak self] imageResult in
                self?.messages.append(.imageResult(prompt: unwrap(self?.inputMessage, ""), data: imageResult))
                self?.inputMessage = ""
            }
            .store(in: &subscriptions)
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
}
