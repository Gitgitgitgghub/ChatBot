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
    }
    
    enum OutputEvent {
        
    }
    
    func bind() {
        inputSubject
            .eraseToAnyPublisher()
            .sink { _ in
                
            } receiveValue: { event in
                
            }
            .store(in: &subscriptions)
    }
    
}
