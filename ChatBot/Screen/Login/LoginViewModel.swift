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
    
    required init() {
        fatalError("init() has not been implemented")
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
        /// 切換平台
        case switchAIPlatform
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
                case .switchAIPlatform:
                    switchAIPlatform()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func switchAIPlatform() {
        let newPlatform: AIPlatform = validation.platform == .geminiAI ? .openAI : .geminiAI
        validation.platform = newPlatform
    }
    
    private func autoLogin() {
        guard !AccountManager.shared.needLogin() else { return }
        let keyInfo = AccountManager.shared.loadKeyInfo()
        keyLogin(platform: keyInfo.platform, key: keyInfo.key)
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
            keyLogin(platform: validation.platform, key: validation.account)
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
    private func keyLogin(platform: AIPlatform, key: String = "") {
        var token: String = ""
        if key == "1234" {
            switch validation.platform {
            case .openAI:
                token = openAIKey
            case .geminiAI:
                token = geminiAIKey
            }
        }else if key.isNotEmpty {
            token = key
        }
        guard token.isNotEmpty else { return }
        performAction(AccountManager.shared.login(keyInfo: .init(platform: platform, key: token)), message: "登入中...")
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { _ in
                
            }
            .store(in: &subscriptions)
    }
    
    func trasformInput(input: InputEvent) {
        inputPublisher.send(input)
    }
}
