//
//  UserVarifidation.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/17.
//

import Foundation
import Combine

class UserValidation {
    
    @Published var account = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage = ""
    @Published var isLoginButtonEnabled = false
    var aa = CurrentValueSubject<String, Never>("")
    var ab = PassthroughSubject<String, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    deinit {
        print("UserValidation deinit")
        //subscriptions.removeAll()
    }
    
    enum ValidationError: Error {
        case accountLength
        case passwordLength
        case confirmPasswordError
        
        var localizedDescription: String {
            switch self {
            case .accountLength:
                return "帳號長度錯誤"
            case .passwordLength:
                return "密碼長度錯誤"
            case .confirmPasswordError:
                return "請確認密碼"
            }
        }
    }
    
    func unbindings() {
        subscriptions.removeAll()
        
    }
    
    func setupBindings() {
        let validAccount = $account
            .map { $0.isEmpty || $0.count > 3 }
            .eraseToAnyPublisher()
        
        let validPassword = $password
            .map { $0.isEmpty || $0.count > 3}
            .eraseToAnyPublisher()
        
        let isPasswordMatch = $password
            .combineLatest($confirmPassword)
            .map { $0.isEmpty || $0 == $1 }
            .eraseToAnyPublisher()
        
        Publishers.CombineLatest3(validAccount, validPassword, isPasswordMatch)
            .map { validAccount, validPassword, isPasswordMatch in
                if !validAccount {
                    return ValidationError.accountLength.localizedDescription
                }
                if !validPassword {
                    return ValidationError.passwordLength.localizedDescription
                }
                if !isPasswordMatch {
                    return ValidationError.confirmPasswordError.localizedDescription
                }
                return ""
            }
            .sink { [unowned self] errorMessage in
                self.errorMessage = errorMessage
            }
            .store(in: &subscriptions)
        $errorMessage
            .map { $0.isEmpty }
            .map({ [weak self] isAllPass in
                guard let `self` = self else { return false }
                return isAllPass && !self.account.isEmpty && !self.password.isEmpty
            })
            .sink(receiveValue: { [unowned self] isEnable in
                self.isLoginButtonEnabled = isEnable
            })
            .store(in: &subscriptions)
    }
    
}
