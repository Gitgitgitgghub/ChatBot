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
        case deleteNote(indexPath: IndexPath)
    }
    
    enum OutputEvent {
        case toast(message: String, reload: Bool)
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
                case .deleteNote(indexPath: let indexPath):
                    self.deleteNote(indexPath: indexPath)
                }
            }
            .store(in: &subscriptions)
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
    /// 刪除筆記
    private func deleteNote(indexPath: IndexPath) {
        guard let id = myNotes[indexPath.row].id else { return }
        NoteManager.shared
            .deleteMyNote(byID: id)
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { [weak self] _ in
                self?.myNotes.removeAll(where: { $0.id == id })
                self?.outputSubject.send(.toast(message: "刪除成功 ！", reload: true))
            }
            .store(in: &subscriptions)
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
