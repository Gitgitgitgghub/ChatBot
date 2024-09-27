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
        case modifyNote(attr: NSAttributedString?)
        /// 刪除comment
        case deleteComment(indexPath: IndexPath)
        /// 刪除筆記
        case deleteNote
    }
    
    enum OutputEvent {
        case toast(message: String, reload: Bool)
        case openEditor(editData: Data?, isNote: Bool, useHtmlEdotir: Bool)
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
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    override func handleInputEvent(inputEvent: InputEvent) {
        switch inputEvent {
        case .modifyNote(attr: let attr):
            modifyNote(attr: attr)
        case .deleteNote:
            deleteNote()
        case .deleteComment(indexPath: let indexPath):
            deleteComment(indexPath: indexPath)
        default:
            self.inputEvent = inputEvent
            chooseEditString()
        }
    }
    
    private func deleteNote() {
        guard let id = myNote.id else { return  }
        noteManager.deleteMyNote(byID: id)
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { [weak self] _ in
                self?.sendOutputEvent(.deleteNoteSuccess)
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
                self?.sendOutputEvent(.deleteCommentSuccess)
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
        sendOutputEvent(.openEditor(editData: editData, isNote: isEditNote, useHtmlEdotir: usingHtml))
    }
    
    private func saveNote(note: MyNote, actionName: String) {
        noteManager.saveNote(myNote)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.sendOutputEvent(.toast(message: "\(actionName)失敗: \(error.localizedDescription)", reload: false))
                }
            } receiveValue: { [weak self] _ in
                self?.sendOutputEvent(.toast(message: "\(actionName)成功", reload: true))
            }
            .store(in: &subscriptions)
    }
    
    /// 更改筆記內容包含comment
    private func modifyNote(attr: NSAttributedString?) {
        guard let attr = attr else { return }
        guard let action = inputEvent else { return }
        switch action {
        case .editNote:
            myNote.setAttributeStringData(attr: attr, documentType: myNote.stringDocumentType)
            saveNote(note: myNote, actionName: "修改筆記")
        case .editComment(let indexPath):
            guard let comment = myNote.comments.getOrNil(index: indexPath.row) else { return }
            comment.setAttributeStringData(attr: attr, documentType: comment.stringDocumentType)
            saveNote(note: myNote, actionName: "修改筆記")
        case .addComment:
            let myComment: MyComment?
            if myNote.stringDocumentType == .html {
                myComment = .init(htmlString: attr)
            }else {
                myComment = .init(attributedString: attr)
            }
            guard let comment = myComment else { return }
            myNote.comments.append(comment)
            saveNote(note: myNote, actionName: "新增筆記")
        default: break
        }
    }
    
}
