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
    @Published var loginMethod: LoginViewController.LogingMethod = .account
    @Published var platform: AIPlatform = .openAI
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
        case keyLength
        
        var localizedDescription: String {
            switch self {
            case .accountLength:
                return "帳號長度錯誤"
            case .passwordLength:
                return "密碼長度錯誤"
            case .confirmPasswordError:
                return "請確認密碼"
            case .keyLength:
                return "Key長度錯誤"
            }
        }
    }
    
    func unbindings() {
        subscriptions.removeAll()
        
    }
    
    func setupBindings() {
        bindErrorMessage()
        bindLoginEnable()
        bindloginMethodChange()
    }
    
    func bindloginMethodChange() {
        $loginMethod
            .sink { [unowned self] _ in
                self.account = ""
                self.password = ""
                self.confirmPassword = ""
                self.errorMessage = ""
            }
            .store(in: &subscriptions)
        $platform
            .sink { [unowned self] _ in
                self.account = ""
            }
            .store(in: &subscriptions)
    }
    
    /// 處理可否點選登入
    private func bindLoginEnable() {
        $errorMessage
            .map { $0.isEmpty }
            .map({ [weak self] isAllPass in
                guard let `self` = self else { return false }
                switch loginMethod {
                case .account:
                    return isAllPass && !self.account.isEmpty && !self.password.isEmpty
                case .key:
                    return isAllPass && self.account.isNotEmpty
                }
            })
            .sink(receiveValue: { [unowned self] isEnable in
                self.isLoginButtonEnabled = isEnable
            })
            .store(in: &subscriptions)
    }
    
    /// 綁定關於錯誤訊息的處理
    private func bindErrorMessage() {
        let validAccount = $account
            .map { $0.isEmpty || $0.count > 3 }
            .eraseToAnyPublisher()
        
        let validPassword = $password
            .map {
                if self.loginMethod == .account {
                    return $0.isEmpty || $0.count > 3
                }
                return true
            }
            .eraseToAnyPublisher()
        
        let isPasswordMatch = $password
            .combineLatest($confirmPassword)
            .map {
                if self.loginMethod == .account {
                    return $0.isEmpty || $0 == $1
                }
                return true
            }
            .eraseToAnyPublisher()
        Publishers.CombineLatest3(validAccount, validPassword, isPasswordMatch)
            .map { validAccount, validPassword, isPasswordMatch in
                if !validAccount {
                    switch self.loginMethod {
                    case .account:
                        return ValidationError.accountLength.localizedDescription
                    case .key:
                        return ValidationError.keyLength.localizedDescription
                    }
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
    }
    
}
