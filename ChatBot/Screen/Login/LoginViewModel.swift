//
//  LoginViewModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import Foundation
import Combine

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
        case account(text: String)
        case password(text: String)
        case confirmPassword(text: String)
        case login
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
                }
            }
            .store(in: &subscriptions)
    }
    
    private func loging() {
        isLoading = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isLoading = .success
        }
    }
    
    func trasformInput(input: InputEvent) {
        inputPublisher.send(input)
    }
}
