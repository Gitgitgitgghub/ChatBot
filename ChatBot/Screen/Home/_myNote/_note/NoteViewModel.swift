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
        /// 變更內容
        case modifyNoteByNSAttributedString(attr: NSAttributedString?)
        /// 刪除comment
        case deleteComment(indexPath: IndexPath)
        /// 刪除筆記
        case deleteNote
    }
    
    enum OutputEvent {
        case toast(message: String, reload: Bool)
        case editUsingHtmlEditor(editData: Data?, isNote: Bool)
        case editUsingTextViewEditor(editData: Data?, isNote: Bool)
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
                case .modifyNoteByNSAttributedString(attr: let attr):
                    self?.modifyNoteByNSAttributedString(attr: attr)
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
        var usingHtml = false
        switch inputEvent {
        case .editNote:
            editData = myNote.attributedStringData
            isEditNote = true
            usingHtml = myNote.stringDocumentType == .html
        case .editComment(let indexPath):
            editData = myNote.comments[indexPath.row].attributedStringData
            usingHtml = myNote.comments[indexPath.row].stringDocumentType == .html
        case .addComment:
            editData = nil
            usingHtml = myNote.stringDocumentType == .html
        default: return
        }
        if usingHtml {
            outputSubject.send(.editUsingHtmlEditor(editData: editData, isNote: isEditNote))
        }else {
            outputSubject.send(.editUsingTextViewEditor(editData: editData, isNote: isEditNote))
        }
    }
    
    private func saveNote(note: MyNote, actionName: String) {
        noteManager.saveNote(myNote)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.outputSubject.send(.toast(message: "\(actionName)失敗: \(error.localizedDescription)", reload: false))
                }
            } receiveValue: { [weak self] _ in
                self?.outputSubject.send(.toast(message: "\(actionName)成功", reload: true))
            }
            .store(in: &subscriptions)
    }
    
    /// 更改筆記內容包含comment
    private func modifyNote(content: String) {
        guard let action = inputEvent else { return }
        switch action {
        case .editNote:
            myNote.setAttributedString(htmlString:content)
            saveNote(note: myNote, actionName: "修改筆記")
        case .editComment(let indexPath):
            guard let comment = myNote.comments.getOrNil(index: indexPath.row) else { return }
            comment.setAttributedString(htmlString:content)
            saveNote(note: myNote, actionName: "修改筆記")
        case .addComment:
            guard let comment = MyComment(htmlString: content) else { return }
            myNote.comments.append(comment)
            saveNote(note: myNote, actionName: "新增筆記")
        default: break
        }
    }
    
    private func modifyNoteByNSAttributedString(attr: NSAttributedString?) {
        guard let action = inputEvent else { return }
        guard let attr = attr else { return }
        switch action {
        case .editNote:
            myNote.setAttributedString(attr: attr)
            saveNote(note: myNote, actionName: "修改筆記")
        case .editComment(let indexPath):
            guard let comment = myNote.comments.getOrNil(index: indexPath.row) else { return }
            comment.setAttributedString(attr: attr)
            saveNote(note: myNote, actionName: "修改筆記")
        case .addComment:
            guard let comment = MyComment(attributedString: attr) else { return }
            myNote.comments.append(comment)
            saveNote(note: myNote, actionName: "新增筆記")
        default: break
        }
    }
    
}