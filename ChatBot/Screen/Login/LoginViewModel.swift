//
//  LoginViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import Foundation
import Combine
import OpenAI

class LoginViewModel {
    
    let validation: UserValidation
    @Published var isLoading: LoginStatus = .none
    private let inputPublisher = PassthroughSubject<InputEvent, Never>()
    private var subscriptions = Set<AnyCancellable>()
        
    init(validation: UserValidation) {
        self.validation = validation
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
                }
            }
            .store(in: &subscriptions)
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
        isLoading = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isLoading = .success
        }
    }
    
    private func keyLogin() {
        let token: String? = validation.account == "1234" ? reallyVeryConfidential.decodeFromBase64() : validation.account
        guard let token = token else { return }
        let openAI = OpenAI(apiToken: token)
        openAI.chats(query: .init(messages: [.init(role: .user, content: "hello")!], model: .gpt3_5Turbo))
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveRequest:  { [weak self] _ in
                self?.isLoading = .loading
            })
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.isLoading = .failure(error: error)
                }
            } receiveValue: { [weak self] _ in
                SystemDefine.share.apiToken = token
                self?.isLoading = .success
            }
            .store(in: &subscriptions)
    }
    
    func trasformInput(input: InputEvent) {
        inputPublisher.send(input)
    }
}
