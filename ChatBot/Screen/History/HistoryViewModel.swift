//
//  HistoryViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/7.
//

import Foundation


class HistoryViewModel: BaseViewModel<HistoryViewModel.InputEvent, HistoryViewModel.OutputEvent> {
    
    enum InputEvent {
        case fetchChatRooms
        case deleteAllChatRoom
        case deleteChatRoom(indexPath: IndexPath)
    }
    
    enum OutputEvent {
        case toast(message: String, reload: Bool = false)
    }
    
    @Published var chatRooms: [ChatRoom] = []
    
    func bind() {
        inputSubject
            .eraseToAnyPublisher()
            .sink { _ in
                
            } receiveValue: { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .fetchChatRooms:
                    self.fetchChatRooms()
                case .deleteAllChatRoom:
                    self.deleteAllChatRoom()
                case .deleteChatRoom(indexPath: let indexPath):
                    self.deleteChatRoom(indexPath: indexPath)
                }
            }
            .store(in: &subscriptions)
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
    private func deleteChatRoom(indexPath: IndexPath) {
//        guard let id = chatRooms.getOrNil(index: indexPath.row)?.id else { return }
//        DatabaseManager.shared
//            .deleteChatRoom(byID: id)
//            .sink { [weak self] completion in
//                switch completion {
//                case .finished: break
//                case .failure(let error):
//                    self?.outputSubject.send(.toast(message: "刪除失敗： \(error.localizedDescription)"))
//                }
//                
//            } receiveValue: { [weak self] _ in
//                self?.chatRooms.remove(at: indexPath.row)
//                self?.outputSubject.send(.toast(message: "刪除成功 ！", reload: true))
//            }
//            .store(in: &subscriptions)
    }
    
    private func deleteAllChatRoom() {
        guard chatRooms.isNotEmpty else { return }
        DatabaseManager.shared
            .deleteAllChatRooms()
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.outputSubject.send(.toast(message: "刪除失敗： \(error.localizedDescription)"))
                }
                
            } receiveValue: { [weak self] _ in
                self?.chatRooms.removeAll()
                self?.outputSubject.send(.toast(message: "刪除成功 ！", reload: true))
            }
            .store(in: &subscriptions)
    }
    
    /// 拿取所有聊天室資料
    private func fetchChatRooms() {
        DatabaseManager.shared
            .fetchChatRooms()
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { [weak self] chatRooms in
                self?.chatRooms = chatRooms
            }
            .store(in: &subscriptions)
    }
    
}
