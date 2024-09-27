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
    
    override func handleInputEvent(inputEvent: InputEvent) {
        switch inputEvent {
        case .fetchChatRooms:
            self.fetchChatRooms()
        case .deleteAllChatRoom:
            self.deleteAllChatRoom()
        case .deleteChatRoom(indexPath: let indexPath):
            self.deleteChatRoom(indexPath: indexPath)
        }
    }
    
    private func deleteChatRoom(indexPath: IndexPath) {
        guard let id = chatRooms.getOrNil(index: indexPath.row)?.id else { return }
        ChatRoomManager.shared
            .deleteChatRoom(byID: id)
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.sendOutputEvent(.toast(message: "刪除失敗： \(error.localizedDescription)"))
                }
                
            } receiveValue: { [weak self] _ in
                self?.chatRooms.remove(at: indexPath.row)
                self?.sendOutputEvent(.toast(message: "刪除成功 ！", reload: true))
            }
            .store(in: &subscriptions)
    }
    
    private func deleteAllChatRoom() {
        guard chatRooms.isNotEmpty else { return }
        ChatRoomManager.shared
            .deleteAllChatRooms()
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.sendOutputEvent(.toast(message: "刪除失敗： \(error.localizedDescription)"))
                }
                
            } receiveValue: { [weak self] _ in
                self?.chatRooms.removeAll()
                self?.sendOutputEvent(.toast(message: "刪除成功 ！", reload: true))
            }
            .store(in: &subscriptions)
    }
    
    /// 拿取所有聊天室資料
    private func fetchChatRooms() {
        ChatRoomManager.shared
            .fetchChatRooms()
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { [weak self] chatRooms in
                self?.chatRooms = chatRooms
            }
            .store(in: &subscriptions)
    }
    
}
