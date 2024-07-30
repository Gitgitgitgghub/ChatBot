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
        case modifyNote(content: String)
        /// 刪除comment
        case deleteComment(indexPath: IndexPath)
        /// 刪除筆記
        case deleteNote
    }
    
    enum OutputEvent {
        case toast(message: String, reload: Bool)
        case edit(editData: Data?, isNote: Bool)
        case deleteNoteSuccess
        case deleteCommentSuccess
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
                case .deleteNote:
                    self?.deleteNote()
                case .deleteComment(indexPath: let indexPath):
                    self?.deleteComment(indexPath: indexPath)
                default:
                    self?.inputEvent = event
                    self?.chooseEditString()
                }
            }
            .store(in: &subscriptions)
    }
    
    func transform(inputEvent: InputEvent) {
        inputSubject.send(inputEvent)
    }
    
    private func deleteNote() {
        guard let id = myNote.id else { return  }
        noteManager.deleteMyNote(byID: id)
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { [weak self] _ in
                self?.outputSubject.send(.deleteNoteSuccess)
            }
            .store(in: &subscriptions)

    }
    
    private func deleteComment(indexPath: IndexPath) {
        guard let removalId = myNote.comments[indexPath.row].id else { return }
        noteManager.deleteMyCommnet(byID: removalId)
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { [weak self] _ in
                self?.myNote.comments.removeAll(where: { $0.id == removalId })
                self?.outputSubject.send(.deleteCommentSuccess)
            }
            .store(in: &subscriptions)
    }
    
    /// 選擇要更改的字串並發送outputEvent
    private func chooseEditString() {
        guard let inputEvent = self.inputEvent else { return }
        var editData: Data?
        var isEditNote: Bool = false
        switch inputEvent {
        case .editNote:
            editData = myNote.attributedStringData
            isEditNote = true
        case .editComment(let indexPath):
            editData = myNote.comments[indexPath.row].attributedStringData
        case .addComment:
            editData = nil
        default: return
        }
        outputSubject.send(.edit(editData: editData, isNote: isEditNote))
    }
    
    /// 更改筆記內容包含comment
    private func modifyNote(content: String) {
        guard let action = inputEvent else { return }
        switch action {
        case .editNote:
            myNote.setAttributedString(htmlString:content)
            noteManager.saveNote(myNote)
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
            guard let comment = myNote.comments.getOrNil(index: indexPath.row) else { return }
            comment.setAttributedString(htmlString:content)
            noteManager.saveNote(myNote)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.outputSubject.send(.toast(message: "editComment error: \(error.localizedDescription)", reload: false))
                }
            } receiveValue: { [weak self] _ in
                self?.outputSubject.send(.toast(message: "修改筆記成功", reload: true))
            }
            .store(in: &self.subscriptions)
        case .addComment:
            guard let comment = MyComment(htmlString: content) else { return }
            myNote.comments.append(comment)
            noteManager.saveNote(myNote)
                .sink { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.outputSubject.send(.toast(message: "addComment error: \(error.localizedDescription)", reload: false))
                    }
                } receiveValue: { [weak self] _ in
                    self?.outputSubject.send(.toast(message: "新增筆記成功", reload: true))
                }
                .store(in: &self.subscriptions)
        default: break
        }
    }
    
}
