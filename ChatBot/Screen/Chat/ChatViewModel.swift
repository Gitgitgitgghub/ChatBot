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
    @Published var inputMessage: String? = "mock"
    @Published var pickedImageInfo: [UIImagePickerController.InfoKey : Any]?
    private let inputSubject = PassthroughSubject<InputEvent, Never>()
    let outputSubject = PassthroughSubject<OutPutEvent, Never>()
    private let parser = AttributedStringParser()
    /// 一次要解析多少筆
    private let proloadBatchCount = 20
    /// 當前頁數
    private(set) var currentPage = 0
    /// 原始資料
    private(set) var originalMessages: [MessageModel] = []
    /// 展示資料
    @Published var displayMessages: [MessageModel] = []
    
    /// 輸入事件
    enum InputEvent {
        case sendMessage
        case createImage
        case editImage
        case preloadAttributedString(currentIndex: Int)
    }
    
    enum OutPutEvent {
        case imageDownloadComplete
    }

    
    init(openai: OpenAIProtocol) {
        self.openai = openai
    }
    
    deinit {
        subscriptions.removeAll()
        print("\(className) deinit")
    }
    
    /// 模擬ai回覆訊息
    func mock() {
        var mocks: [MessageModel] = []
        for _ in 0...105 {
            let message = Bool.random() ? mockString : mockString2
            mocks.append(.init(message: message, sender: .ai))
        }
        originalMessages = mocks
        print("模擬資料 總筆數：\(originalMessages.count)")
        preloadAttributedStringEvent(currentIndex: 0)
    }
    
    func bindInput() -> AnyPublisher<InputEvent, Never> {
        inputSubject
            .sink { [weak self] inputEvent in
                guard let `self` = self else { return }
                switch inputEvent {
                case .sendMessage:
                    self.sendMessageEvent()
                case .createImage:
                    self.createImaheEvent()
                case .editImage:
                    self.editImageEvent()
                case .preloadAttributedString(let startAt):
                    self.preloadAttributedStringEvent(currentIndex: startAt)
                }
            }
            .store(in: &subscriptions)
        return inputSubject.eraseToAnyPublisher()
    }
    
    func imageDownloadComplete() {
        outputSubject.send(.imageDownloadComplete)
    }
    
    /// 綁定編輯圖片事件
    private func editImageEvent() {
//        inputSubject
//            .filter { event in
//                return event == .editImage && !unwrap(self.inputMessage, "").isEmpty
//            }
//            .map({ _ in
//                return self.inputMessage!
//            })
//            .handleEvents(receiveSubscription: { _ in
//                
//            }, receiveOutput: { [weak self] output in
//                self?.messages.append(.userChatQuery(message: output))
//            })
//            .flatMap { message in
//                return self.openai.editImage(info: self.pickedImageInfo!, prompt: message, size: ._512)
//            }
//            .sink { completion in
//                switch completion {
//                case .finished:
//                    break
//                case .failure(let error):
//                    print("failure: \(error.localizedDescription)")
//                }
//            } receiveValue: { [weak self] imageResult in
//                self?.messages.append(.imageResult(prompt: unwrap(self?.inputMessage, ""), data: imageResult))
//                self?.inputMessage = ""
//            }
//            .store(in: &subscriptions)
    }
    
    /// 綁定創造圖片事件
    private func createImaheEvent() {
//        inputSubject
//            .filter { event in
//                return event == .createImage && !unwrap(self.inputMessage, "").isEmpty
//            }
//            .map({ _ in
//                return self.inputMessage!
//            })
//            .handleEvents(receiveSubscription: { _ in
//                
//            }, receiveOutput: { [weak self] output in
//                self?.messages.append(.userChatQuery(message: output))
//            })
//            .flatMap { message in
//                return self.openai.createImage(prompt: message, size: ._1024)
//            }
//            .sink { _ in
//                
//            } receiveValue: { [weak self] imageResult in
//                self?.messages.append(.imageResult(prompt: unwrap(self?.inputMessage, ""), data: imageResult))
//                self?.inputMessage = ""
//            }
//            .store(in: &subscriptions)
    }
    
    /// 當前是否需要執行預加載
    private func isNeedToPreload(currentIndex: Int) -> Bool {
        return currentIndex == displayMessages.count - 11 || (currentIndex == 0 && displayMessages.isEmpty)
    }
    
    /// 預加載AttributedString事件
    private func preloadAttributedStringEvent(currentIndex: Int) {
        guard isNeedToPreload(currentIndex: currentIndex) else { return }
        let startIndex = currentPage * proloadBatchCount
        let endIndex = min(startIndex + proloadBatchCount, originalMessages.count)
        // 確保有資料可以加載
        guard startIndex < endIndex else { 
            print("沒有資料可以加載了")
            return
        }
        let preloadData = Array(originalMessages[startIndex..<endIndex])
        print("需要執行預加載： 當前位置\(currentIndex) 從：\(startIndex) 到： \(endIndex) 共：\(preloadData.count)")
        parser.convertStringsToAttributedStrings(strings: preloadData.map{ $0.message })
            .collect(preloadData.count)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("preloadAttributedStringEvent Error:", error.localizedDescription)
                }
            }, receiveValue: { [weak self] attributedStrings in
                for (index, attributedString) in attributedStrings.enumerated() {
                    preloadData[index].attributedString = attributedString
                    preloadData[index].estimatedHeightForAttributedString = attributedString.estimatedHeightForAttributedString()
                }
                self?.currentPage += 1
                self?.displayMessages.append(contentsOf: preloadData)
            })
            .store(in: &subscriptions)
    }
    
    /// 綁定送出文字訊息事件
    private func sendMessageEvent() {
        guard let inputMessage = inputMessage, !inputMessage.isEmpty else { return }
        let inputMessageModel: MessageModel = .init(message: inputMessage, sender: .user)
        self.inputMessage = ""
        appendNewMessage(newMessage: inputMessageModel)
        if inputMessage == "mock" {
            mock()
            return
        }
        openai.chatQuery(message: inputMessage)
            .sink { _ in
                
            } receiveValue: { [weak self] messagesModel in
                print("回應訊息： \(messagesModel.message)")
                self?.appendNewMessage(newMessage: messagesModel)
            }
            .store(in: &subscriptions)
    }
    
    /// 添加新的訊息
    private func appendNewMessage(newMessage: MessageModel) {
        parser.convertStringToAttributedString(string: newMessage.message)
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { [weak self] attr in
                guard let `self` = self else { return }
                newMessage.attributedString = attr
                newMessage.estimatedHeightForAttributedString = attr.estimatedHeightForAttributedString()
                self.originalMessages.append(newMessage)
                self.displayMessages.append(newMessage)
            }
            .store(in: &subscriptions)
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
}
