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
        case addNote(title: String?, attributedString: NSAttributedString?)
    }
    
    enum OutputEvent {
        case toast(message: String, reload: Bool)
    }
    
    @Published var myNotes: [MyNote] = []
    
    override func handleInputEvent(inputEvent: InputEvent) {
        switch inputEvent {
        case .fetchAllNote:
            self.fetchAllNote()
        case .deleteNote(indexPath: let indexPath):
            self.deleteNote(indexPath: indexPath)
        case .addNote(let title, attributedString: let attributedString):
            self.addNote(title: title, attributedString: attributedString)
        }
    }
    
    private func addNote(title: String?, attributedString: NSAttributedString?) {
        guard let attributedString = attributedString else { return }
        guard let note = MyNote(title: title ?? "我的筆記", attributedString: attributedString) else { return }
        NoteManager.shared.saveNote(note)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.sendOutputEvent(.toast(message: "新增筆記失敗：\(error.localizedDescription)", reload: false))
                case .finished: break
                }
                
            } receiveValue: { [weak self] _ in
                self?.sendOutputEvent(.toast(message: "新增筆記成功", reload: false))
            }
            .store(in: &subscriptions)
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
                self?.sendOutputEvent(.toast(message: "刪除成功 ！", reload: true))
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
