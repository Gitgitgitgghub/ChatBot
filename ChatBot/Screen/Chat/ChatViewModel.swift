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
    @Published var chatLaunchMode: ChatViewController.ChatLaunchMode
    @Published var inputMessage: String? = "mock"
    @Published var pickedImageInfo: [UIImagePickerController.InfoKey : Any]?
    /// 展示資料
    @Published var displayMessages: [ChatMessage] = []
    private let parser = AttributedStringParser()
    /// 一次要解析多少筆
    private let proloadBatchCount = 20
    private let chatService: AIChatManager
    private var attributedStringCatches = CacheManager<Int, NSAttributedString>()
    private var estimatedHeightCatches = CacheManager<Int, CGFloat>()
    /// 聊天室
    private(set) var chatRoom: ChatRoom!
    
    /// 輸入事件
    enum InputEvent {
        case sendMessage
        case createImage
        case editImage
        case preloadAttributedString(currentIndex: Int)
        case saveMessages
        case retrySendMessage
        case saveMessageToMyNote(noteTitle: String?, indexPath: IndexPath)
    }
    
    enum OutPutEvent {
        case parseComplete(indexs: [IndexPath])
        case saveChatMessageSuccess
        case saveChatMessageError(error: Error)
    }

    
    init(service: AIServiceProtocol, chatLaunchMode: ChatViewController.ChatLaunchMode) {
        self.chatService = .init(service: service)
        self.chatLaunchMode = chatLaunchMode
        super.init()
        self.setupPreloadPipeline()
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
            let chatMessage = ChatMessage(message: message, role: .user)
            chatMessage.type = .mock
            mocks.append(chatMessage)
        }
        displayMessages.append(contentsOf: mocks)
        delay(delay: 1) {
            print("模擬資料 總筆數：\(mocks.count)")
            self.preloadAttributedStringEvent(startIndex: self.displayMessages.count - 1)
        }
    }
    
    func bindInput() {
        inputSubject
            .sink { [weak self] inputEvent in
                guard let `self` = self else { return }
                switch inputEvent {
                case .sendMessage:
                    self.sendMessageEvent()
                case .createImage: break
                case .editImage: break
                case .preloadAttributedString(let startIndex):
                    self.preloadAttributedStringEvent(startIndex: startIndex)
                case .saveMessages:
                    self.saveMessages()
                case .retrySendMessage:
                    self.retrySendMessage()
                case .saveMessageToMyNote(let noteTitle, let indexPath):
                    self.saveMessageToMyNote(noteTitle: noteTitle, indexPath: indexPath)
                }
            }
            .store(in: &subscriptions)
    }
    
    func getAttributeString(index: Int) -> NSAttributedString? {
        return attributedStringCatches.getCache(forKey: index)
    }
    
    func getEstimatedHeight(index: Int) -> CGFloat? {
        return estimatedHeightCatches.getCache(forKey: index)
    }
    
    /// 主要處理launchMode 數據該怎麼初始化
    private func handleLaunchMode() {
        switch chatLaunchMode {
        case .normal:
            self.chatRoom = .init(lastUpdate: .now)
            break
        case .chatRoom(let chatRoom):
            self.chatRoom = chatRoom
            do {
                try DatabaseManager.shared.dbQueue.read { db in
                    displayMessages = try chatRoom.messages.fetchAll(db)
                    preloadAttributedStringEvent(startIndex: self.displayMessages.count - 1)
                }
            }catch {
                
            }
        case .prompt(_, prompt: let prompt):
            self.chatRoom = .init(lastUpdate: .now)
            let message = ChatMessage(message: prompt, role: .user)
            displayMessages.append(message)
            preloadAttributedStringEvent(startIndex: self.displayMessages.count - 1)
        }
    }
    
    /// 當前是否需要執行預加載
    private func isNeedToPreload(currentIndex: Int) -> Bool {
        return currentIndex == displayMessages.count - 11 || (currentIndex == 0 && displayMessages.isEmpty)
    }
    
    private let preloadSubject = PassthroughSubject<[Int], Never> ()
    
    /// 設定預加載流程
    private func setupPreloadPipeline() {
        preloadSubject
            .flatMap { [weak self] numbers -> AnyPublisher<[Int], Never> in
                guard let `self` = self else {
                    return Just([])
                        .eraseToAnyPublisher()
                }
                // 1. 先過濾出有緩存的部分
                let cachedNumbers = numbers.filter { self.attributedStringCatches.getCache(forKey: $0) != nil }
                // 2. 取得沒有緩存的部分
                let uncachedNumbers = numbers.filter {
                    self.attributedStringCatches.getCache(forKey: $0) == nil &&
                    self.displayMessages.getOrNil(index: $0)?.message != nil
                }
                // 3. 如果全部都有緩存，直接回傳
                if uncachedNumbers.isEmpty {
                    print("🔴沒有資料可以加載")
                    return Just(cachedNumbers)
                        .eraseToAnyPublisher()
                }
                // 4. 需要轉換的字串資料，這邊我們假設有一個可以對應 tag 和 string 的陣列
                let stringsToConvert = uncachedNumbers.map { tag in
                    return (tag: tag, string: self.displayMessages.getOrNil(index: tag)?.message ?? "")
                }
                print("需要執行預加載共：\(uncachedNumbers.count)筆")
                // 5. 呼叫 convertStringsToAttributedStrings 進行轉換，並合併已緩存的結果
                return self.parser.convertStringsToAttributedStrings(stringWithTags: stringsToConvert)
                    .map { result -> [Int] in
                        // 轉換完畢後，將結果存入緩存
                        self.attributedStringCatches.setCache(result.attr, forKey: result.tag)
                        self.estimatedHeightCatches.setCache(result.attr.estimatedHeightForAttributedString(), forKey: result.tag)
                        return cachedNumbers + [result.tag]
                    }
                    .collect()
                    .map { $0.flatMap { $0 } }
                    .catch { error -> AnyPublisher<[Int], Never> in
                        print("Error converting strings: \(error)")
                        return Just([]).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink(receiveValue: { [weak self] indexs in
                self?.outputSubject.send(.parseComplete(indexs: indexs.map{ IndexPath(row: $0, section: 0) }))
            })
            .store(in: &subscriptions)
    }

    /// 預加載AttributedString事件
    private func preloadAttributedStringEvent(startIndex: Int) {
        preloadSubject.send(Array.generateAlternatingNumbers(start: startIndex, count: self.proloadBatchCount))
    }

    /// 綁定重新發送訊息事件
    private func retrySendMessage() {
        guard let lastMessage = displayMessages.last?.message else { return }
        inputMessage = lastMessage
        sendMessageEvent(appendInputMessage: false)
    }
    
    private func saveMessageToMyNote(noteTitle: String?, indexPath: IndexPath) {
        guard let attr = attributedStringCatches.getCache(forKey: indexPath.row) else { return }
        guard let note = MyNote(title: noteTitle ?? "My Note", htmlString: attr) else { return }
        NoteManager.shared.saveNote(note)
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
    
    /// 綁定送出文字訊息事件
    private func sendMessageEvent(appendInputMessage: Bool = true) {
        guard let inputMessage = inputMessage, !inputMessage.isEmpty else { return }
        let chatMessage = ChatMessage(message: inputMessage, role: .user)
        if inputMessage == "mock" {
            mock()
            return
        }
        defer {
            self.inputMessage = ""
        }
        let publisher = appendInputMessage ? appendNewMessage(newMessage: chatMessage) : 
        Just<Void>(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        for message in displayMessages {
            print(message.role)
        }
        publisher
            .flatMap({ self.chatService.chat(messages: self.displayMessages) })
            .flatMap({ chatMessage in
                print("回應訊息： \(String(describing: chatMessage.message))")
                return self.appendNewMessage(newMessage: chatMessage)
            })
            .sink { _ in
                
            } receiveValue: { _ in
                
            }
            .store(in: &subscriptions)
    }
    
    /// 把訊息轉attr後加入displayMessage
    private func appendNewMessage(newMessage: ChatMessage) -> AnyPublisher<Void, Error> {
        return parser.convertStringToAttributedString(string: newMessage.message)
            .receive(on: RunLoop.main)
            .map({  [weak self] attr in
                guard let `self` = self else { return }
                let index = self.displayMessages.count
                self.attributedStringCatches.setCache(attr, forKey: index)
                self.estimatedHeightCatches.setCache(attr.estimatedHeightForAttributedString(), forKey: index)
                self.displayMessages.append(newMessage)
                return ()
            })
            .eraseToAnyPublisher()
    }
    
    /// 儲存聊天訊息
    private func saveMessages() {
        guard displayMessages.isNotEmpty else {
            outputSubject.send(.saveChatMessageError(error: NSError(domain: "沒有聊天訊息", code: 1)))
            return
        }
        ChatRoomManager.shared.saveChatRoom(chatRoom, messages: displayMessages)
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
}
