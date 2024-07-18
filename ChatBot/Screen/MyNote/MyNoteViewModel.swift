//
//  MyNoteViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/18.
//

import Foundation


class MyNoteViewModel: BaseViewModel<MyNoteViewModel.InputEvent, MyNoteViewModel.OutputEvent> {
    
    enum InputEvent {
        case fetchAllNote
    }
    
    enum OutputEvent {
        
    }
    
    @Published var myNotes: [MyNote] = []
    
    func bind() {
        inputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .fetchAllNote:
                    self.fetchAllNote()
                }
            }
            .store(in: &subscriptions)
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
    /// 獲取所有筆記
    private func fetchAllNote() {
        NoteManager.shared
            .fetchMyNotes()
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { [weak self] myNotes in
                guard let `self` = self else { return }
                self.myNotes = myNotes
            }
            .store(in: &subscriptions)
    }
}
