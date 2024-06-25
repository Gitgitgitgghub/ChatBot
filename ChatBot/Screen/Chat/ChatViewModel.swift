//
//  ChatViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import OpenAI
import Combine
import UIKit

class ChatViewModel: NSObject {
    
    let openai: OpenAIProtocol
    private var subscriptions = Set<AnyCancellable>()
    @Published var inputMessage: String? = "可以給我推薦的swift學習影片嗎? 並且附上影片網址"
    @Published var messages: [OpenAIResult] = []
    @Published var pickedImageInfo: [UIImagePickerController.InfoKey : Any]?
    let messagesSubject = CurrentValueSubject<[MessageModel], Never>([])
    private let inputSubject = PassthroughSubject<InputEvent, Never>()

    
    /// 輸入事件
    enum InputEvent {
        case sendMessage
        case createImage
        case editImage
    }

    
    init(openai: OpenAIProtocol) {
        self.openai = openai
    }
    
    deinit {
        subscriptions.removeAll()
        print("\(className) deinit")
    }
    
    func mock() {
        messages.append(contentsOf: Array(repeating: .chatResult(data: nil), count: 1))
    }
    
    func bindInput() -> AnyPublisher<InputEvent, Never> {
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
                self?.inputMessage = ""
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
        inputSubject
            .filter { event in
                return event == .editImage && !unwrap(self.inputMessage, "").isEmpty
            }
            .map({ _ in
                return self.inputMessage!
            })
            .handleEvents(receiveSubscription: { _ in
                
            }, receiveOutput: { [weak self] output in
                self?.messages.append(.userChatQuery(message: output))
            })
            .flatMap { message in
                return self.openai.editImage(info: self.pickedImageInfo!, prompt: message, size: ._512)
            }
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("failure: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] imageResult in
                self?.messages.append(.imageResult(prompt: unwrap(self?.inputMessage, ""), data: imageResult))
                self?.inputMessage = ""
            }
            .store(in: &subscriptions)
        return inputSubject.eraseToAnyPublisher()
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
}
