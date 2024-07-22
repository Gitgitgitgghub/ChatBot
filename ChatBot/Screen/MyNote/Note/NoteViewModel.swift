//
//  NoteViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/22.
//

import Foundation


class NoteViewModel: BaseViewModel<NoteViewModel.InputEvent, NoteViewModel.OutputEvent> {
    
    enum InputEvent {
        /// 編輯筆記
        case editNote
        /// 編輯自己添加的筆記
        case editComment(indexPath: IndexPath)
        /// 新增自己的筆記
        case addComment
        /// 變更內容
        case modifyNote(content: NSAttributedString)
    }
    
    enum OutputEvent {
        case toast(message: String, reload: Bool)
    }
    
    enum Section {
        /// 儲存的原始筆記
        case note
        /// 自己添加的筆記
        case comment
    }
    
    @Published private(set) var myNote: MyNote
    let sections: [Section] = [.note , .comment]
    private var inputEvent: InputEvent?
    private let noteManager = NoteManager.shared
    
    init(myNote: MyNote) {
        self.myNote = myNote
    }
    
    func bind() {
        inputSubject
            .sink { [weak self] event in
                switch event {
                case .modifyNote(content: let content):
                    self?.modifyNote(content: content)
                default: 
                    self?.inputEvent = event
                }
            }
            .store(in: &subscriptions)
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
    private func modifyNote(content: NSAttributedString) {
        guard let action = inputEvent else { return }
        switch action {
        case .editNote:
            myNote.setAttributedString(attr: content)
            noteManager.saveNote(myNote, comments: [])
                .receive(on: RunLoop.main)
                .sink { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.outputSubject.send(.toast(message: "editNote error: \(error.localizedDescription)", reload: false))
                    }
                } receiveValue: { [weak self] _ in
                    self?.outputSubject.send(.toast(message: "修改筆記成功", reload: true))
                }
                .store(in: &subscriptions)
        case .editComment(let indexPath):
            //TODO: - 太醜之後要改
            DatabaseManager.shared.dbQueue.readPublisher { db in
                let comment = try self.myNote.comments.fetchAll(db)[indexPath.row]
                comment.setAttributedString(attr: content)
                return comment
            }
            .flatMap { comment in
                self.noteManager.saveNote(self.myNote, comments: [comment])
            }
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.outputSubject.send(.toast(message: "editComment error: \(error.localizedDescription)", reload: false))
                }
            } receiveValue: { [weak self] _ in
                self?.outputSubject.send(.toast(message: "修改筆記成功", reload: true))
            }
            .store(in: &self.subscriptions)
        case .addComment:
            //TODO: - 太醜之後要改
            do {
                let comment = try MyComment(attributedString: content)
                noteManager.saveNote(myNote, comments: [comment])
                    .sink { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.outputSubject.send(.toast(message: "addComment error: \(error.localizedDescription)", reload: false))
                        }
                    } receiveValue: { [weak self] _ in
                        self?.outputSubject.send(.toast(message: "新增筆記成功", reload: true))
                    }
                    .store(in: &self.subscriptions)
            }catch {
                
            }
        default: break
        }
    }
    
}
