//
//  LoginViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import Foundation
import Combine
import OpenAI

class LoginViewModel: BaseViewModel<LoginViewModel.InputEvent, LoginViewModel.OutputEvent> {
    
    let validation: UserValidation
    private let inputPublisher = PassthroughSubject<InputEvent, Never>()
        
    init(validation: UserValidation) {
        self.validation = validation
        super.init()
        setupBindings()
    }
    
    deinit {
        unbindings()
        print("LoginViewModel deinit")
    }
    
    enum LoginStatus {
        case none
        case loading
        case failure(error: Error)
        case success
    }
    
    enum OutputEvent {
        
    }
    
    enum InputEvent: Equatable {
        /// 輸入帳號
        case account(text: String)
        /// 輸入密碼
        case password(text: String)
        /// 輸入確認密碼
        case confirmPassword(text: String)
        /// 點選登入
        case login
        /// 點選切換登入方式
        case switchLoginMethod
        /// 呼叫自動登入
        case autoLogin
    }
    
    func unbindings() {
        validation.unbindings()
        subscriptions.removeAll()
    }
    
    func setupBindings() {
        inputPublisher
            .print("inputEvent")
            .sink { [unowned self] input in
                switch input {
                case .account(let text):
                    validation.account = text
                case .password(let text):
                    validation.password = text
                case .confirmPassword(let text):
                    validation.confirmPassword = text
                case .login:
                    self.loging()
                case .switchLoginMethod:
                    self.switchLoginMethod()
                case .autoLogin:
                    self.autoLogin()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func autoLogin() {
        guard !AccountManager.shared.needLogin() else { return }
        keyLogin(key: AccountManager.shared.apiKey)
    }
    
    /// 切換登入方式
    private func switchLoginMethod() {
        let newMethod: LoginViewController.LogingMethod = validation.loginMethod == .account ? .key : .account
        validation.loginMethod = newMethod
    }
    
    private func loging() {
        switch validation.loginMethod {
        case .account:
            accountLogin()
        case .key:
            keyLogin()
        }
    }
    
    private func accountLogin() {
        loadingStatus.value = .loading(message: "登入中...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.loadingStatus.value = .success
        }
    }
    
    /// 使用金鑰登入
    /// 如果有帶key近來則直接使用
    /// 沒有帶則走輸入流程
    private func keyLogin(key: String = "") {
        let token: String?
        if key.isNotEmpty {
            token = key
        }else {
            token = validation.account == "1234" ? reallyVeryConfidential.decodeFromBase64() : validation.account
        }
        guard let token = token else { return }
        let openAI = OpenAI(apiToken: token)
        performAction(openAI.chats(query: .init(messages: [.init(role: .user, content: "hello")!], model: .gpt3_5Turbo)), message: "登入中...")
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { _ in
                AccountManager.shared.saveAPIKey(key: token)
            }
            .store(in: &subscriptions)
    }
    
    func trasformInput(input: InputEvent) {
        inputPublisher.send(input)
    }
}
