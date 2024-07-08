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

class ChatViewModel: BaseViewModel<ChatViewModel.InputEvent, ChatViewModel.OutPutEvent> {
    /// 啟動模式
    let chatLaunchMode: ChatViewController.ChatLaunchMode
    let openai: OpenAIProtocol
    private var parserSubscription: AnyCancellable? = nil
    @Published var inputMessage: String? = "hi"
    @Published var pickedImageInfo: [UIImagePickerController.InfoKey : Any]?
    private let parser = AttributedStringParser()
    /// 一次要解析多少筆
    private let proloadBatchCount = 20
    /// 展示資料
    @Published var displayMessages: [ChatMessage] = []
    private(set) var attributedStringCatches: [Int : NSAttributedString] = [:]
    private(set) var estimatedHeightCatches: [Int : CGFloat] = [:]
    /// 聊天室
    private(set) var chatRoom: MyChatRoom!
    
    /// 輸入事件
    enum InputEvent {
        case sendMessage
        case createImage
        case editImage
        case preloadAttributedString(currentIndex: Int)
        case saveMessages
    }
    
    enum OutPutEvent {
        case parseComplete(indexs: [IndexPath])
        case saveChatMessageSuccess
        case saveChatMessageError(error: Error)
    }

    
    init(openai: OpenAIProtocol, chatLaunchMode: ChatViewController.ChatLaunchMode) {
        self.openai = openai
        self.chatLaunchMode = chatLaunchMode
        super.init()
        self.handleLaunchMode()
    }
    
    deinit {
        subscriptions.removeAll()
        print("\(className) deinit")
    }
    
    /// 模擬ai回覆訊息
    func mock() {
//        var array: [String] = []
//        var array2: [String] = []
//        for i in 0...10 {
//            array.append("\(i)")
//        }
//        for i in 11...20 {
//            array.append("\(i)")
//        }
//        parser.convertStringsToAttributedStrings(strings: array)
//            .collect(array.count)
//            .sink { _ in
//                
//            } receiveValue: { value in
//                for a in value {
//                    print("mock receiveValue \(a)")
//                }
//                
//            }
//            .store(in: &subscriptions)
//        parser.convertStringsToAttributedStrings(strings: array2)
//            .collect(array.count)
//            .sink { _ in
//                
//            } receiveValue: { value in
//                for a in value {
//                    print("mock receiveValue \(a)")
//                }
//                
//            }
//            .store(in: &subscriptions)
        var mocks: [ChatMessage] = []
        for _ in 0...100 {
            let message = Bool.random() ? mockString : mockString2
            if let chatMessage = ChatMessage.createNewMessage(content: message, role: .assistant, messageType: .mock) {
                mocks.append(chatMessage)
            }
        }
        displayMessages.append(contentsOf: mocks)
        delay(delay: 1) {
            print("模擬資料 總筆數：\(mocks.count)")
            self.preloadAttributedStringEvent(startIndex: self.displayMessages.count - 1)
        }
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
                case .preloadAttributedString(let startIndex):
                    self.preloadAttributedStringEvent(startIndex: startIndex)
                case .saveMessages:
                    self.saveMessages()
                }
            }
            .store(in: &subscriptions)
        return inputSubject.eraseToAnyPublisher()
    }
    
    /// 主要處理launchMode 數據該怎麼初始化
    private func handleLaunchMode() {
        switch chatLaunchMode {
        case .normal:
            self.chatRoom = MyChatRoomManager.shared.createChatRoom()
            break
        case .chatRoom(let chatRoom):
            self.chatRoom = chatRoom
            displayMessages = chatRoom.sortedMessages
            preloadAttributedStringEvent(startIndex: self.displayMessages.count - 1)
        }
    }
    
    /// 當前是否需要執行預加載
    private func isNeedToPreload(currentIndex: Int) -> Bool {
        return currentIndex == displayMessages.count - 11 || (currentIndex == 0 && displayMessages.isEmpty)
    }
    
    /// 生成一串數字
    /// 例如: start 50 ,count 10 會給 [50, 49, 51, 48, 52, 47, 53, 46, 54, 45]
    /// - Parameters:
    ///   - start: 從哪裡開始
    ///   - count: 要生成幾個
    /// - Returns: 一串數字
    private func generateAlternatingNumbers(start: Int, count: Int) -> [Int] {
        var numbersArray: [Int] = []
        let currentNumber = start
        for i in 0..<count {
            if i % 2 == 0 {
                // 偶数索引，递增
                numbersArray.append(currentNumber + i / 2)
            } else {
                // 奇数索引，递减
                numbersArray.append(currentNumber - (i / 2 + 1))
            }
        }
        return numbersArray
    }
    
    /// 取得需要加載資料的publisher
    /// 需要多產生一個Int當tag的原因是因為
    /// parser.convertStringsToAttributedStrings 是merge所以變成無序回來順序已經不是傳進去的樣子了
    private func getPreloadDataPublisher(startIndex: Int) -> Future<[(Int, String)], Error> {
        return Future { promise in
            DispatchQueue.global(qos: .background).async {
                var preloadData: [(Int, String)] = []
                let preloadIndexs = self.generateAlternatingNumbers(start: startIndex, count: self.proloadBatchCount)
                for index in preloadIndexs {
                    if let message = self.displayMessages.getOrNil(index: index), self.attributedStringCatches[index] == nil {
                        preloadData.append((index ,message.message ?? ""))
                    }
                }
                if preloadData.isEmpty {
                    print("🔴沒有資料可以加載")
                }
                promise(.success(preloadData))
            }
        }
    }

    private func convertToAttributedStrings(data: [(Int, String)]) -> AnyPublisher<[(tag: Int, attr: NSAttributedString)], Error> {
        if data.isEmpty {
            return Empty(completeImmediately: true).eraseToAnyPublisher()
        }
        // 這邊是.collect(data.count) 所以只會有一個receiveValue
        // 如果拿掉的話要做流的處理debounce之類的
        return parser.convertStringsToAttributedStrings(stringWithTags: data)
            .collect(data.count)
            .eraseToAnyPublisher()
    }

    /// 預加載AttributedString事件
    private func preloadAttributedStringEvent(startIndex: Int) {
        // 這邊獨立出來方便隨時取消
        parserSubscription?.cancel()
        parserSubscription = getPreloadDataPublisher(startIndex: startIndex)
            .flatMap { [weak self] data -> AnyPublisher<[(tag: Int, attr: NSAttributedString)], Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "self is nil", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                print("需要執行預加載： 從：\(startIndex) 共：\(data.count)筆")
                return self.convertToAttributedStrings(data: data)
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCancel: {
                print("🔴加載事件被取消")
            })
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("preloadAttributedStringEvent Error:", error.localizedDescription)
                }
            }, receiveValue: { [weak self] results in
                self?.handlePreloadResult(results)
            })
    }

    /// 處理預加載完後的事件
    private func handlePreloadResult(_ results: [(tag: Int, attr: NSAttributedString)]) {
        var indexPaths: [IndexPath] = []
        for result in results {
            let index = result.tag
            let attributedString = result.attr
            attributedStringCatches[index] = attributedString
            estimatedHeightCatches[index] = attributedString.estimatedHeightForAttributedString()
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        outputSubject.send(.parseComplete(indexs: indexPaths))
    }

    
    /// 綁定送出文字訊息事件
    private func sendMessageEvent() {
        guard let inputMessage = inputMessage, !inputMessage.isEmpty else { return }
        guard let chatMessage = ChatMessage.createNewMessage(content: inputMessage, role: .user, messageType: .message) else { return }
        if inputMessage == "mock" {
            mock()
            return
        }
        self.inputMessage = ""
        appendNewMessage(newMessage: chatMessage)
            .flatMap({ [self] in openai.chatQuery(messages: self.displayMessages, model: .gpt3_5Turbo) })
            .flatMap({ [self] chatMessage in
                print("回應訊息： \(String(describing: chatMessage.message))")
                return self.appendNewMessage(newMessage: chatMessage)
            })
            .sink { _ in
                
            } receiveValue: { _ in
                
            }
            .store(in: &subscriptions)
    }
    
    /// 添加新的訊息
    private func appendNewMessage(newMessage: ChatMessage) -> AnyPublisher<Void, Error> {
        return parser.convertStringToAttributedString(string: newMessage.message ?? "")
            .receive(on: RunLoop.main)
            .map({  [weak self] attr in
                guard let `self` = self else { return }
                let index = self.displayMessages.count
                self.attributedStringCatches[index] = attr
                self.estimatedHeightCatches[index] = attr.estimatedHeightForAttributedString()
                self.displayMessages.append(newMessage)
                return ()
            })
            .eraseToAnyPublisher()
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
    /// 儲存聊天訊息
    private func saveMessages() {
        let manager = MyChatRoomManager.shared
        manager.saveChatMessage(chatRoom: chatRoom, messages: displayMessages)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.outputSubject.send(.saveChatMessageError(error: error))
                case .finished: break
                }
                
            } receiveValue: { [weak self] _ in
                self?.outputSubject.send(.saveChatMessageSuccess)
            }
            .store(in: &subscriptions)
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
}
