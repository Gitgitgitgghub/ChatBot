//
//  LoginViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import UIKit
import Combine

class LoginViewController: UIViewController {
    
    private lazy var views = LogingViews(view: self.view)
    private let varifidation = UserVarifidation()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
    }
    
    private func initUI() {
        views.accountTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        views.pwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        views.confirmPwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        views.accountTextField.delegate = self
        views.pwTextField.delegate = self
        views.confirmPwTextField.delegate = self
    }
    
    private func bind() {
        varifidation
            .loginButtonEnable
            .sink { [weak self] isEnable in
                self?.views.loginButton.isEnabled = isEnable
            }
            .store(in: &cancellables)
//        varifidation.$account
//            .map ({ value in
//                if value.count <= 3 && !value.isEmpty {
//                    return UserVarifidation.VarifidationError.accountLength.rawValue
//                }
//                return ""
//            })
//            .sink(receiveValue: { [weak self] errorMessage in
//                self?.views.errorLabel.text = errorMessage
//            })
//            .store(in: &cancellables)
        varifidation.$account
            .eraseToAnyPublisher()
            .setFailureType(to: UserVarifidation.VarifidationError.self)
            .print("login")
            .tryMap ({ value in
                if value.count <= 3 && !value.isEmpty {
                    throw UserVarifidation.VarifidationError.accountLength
                }
                return ""
            })
            .catch({ [weak self] error in
                if let error = error as? UserVarifidation.VarifidationError {
                    return Just(error.rawValue)
                }
                return Just("")
            })
            .sink(receiveValue: { [weak self] errorMessage in
                self?.views.errorLabel.text = errorMessage
            })
            .store(in: &cancellables)
        varifidation.$password
            .map ({ value in
                if value.count <= 3 && !value.isEmpty {
                    return UserVarifidation.VarifidationError.passwordLength.rawValue
                }
                return ""
            })
            .sink(receiveValue: { [weak self] errorMessage in
                self?.views.errorLabel.text = errorMessage
            })
            .store(in: &cancellables)
        Publishers.CombineLatest(varifidation.$password, varifidation.$confirmPassword)
            .map { password, confirm in
                if password.isEmpty || confirm.isEmpty || password == confirm {
                    return ""
                }
                return UserVarifidation.VarifidationError.confirmPasswordError.rawValue
            }
            .sink(receiveValue: { [weak self] errorMessage in
                self?.views.errorLabel.text = errorMessage
            })
            .store(in: &cancellables)

    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        switch textField {
        case views.accountTextField:
            varifidation.account = textField.text ?? ""
        case views.pwTextField:
            varifidation.password = textField.text ?? ""
        case views.confirmPwTextField:
            varifidation.confirmPassword = textField.text ?? ""
        default: break
        }
    }
    
    deinit {
        cancellables.removeAll()
    }

}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

class UserVarifidation {
    
    @Published var account = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    var loginButtonEnable: AnyPublisher<Bool, Never> {
        let validAccount = $account.map { $0.count >= 3 }
        let validPassword = $password.map { $0.count >= 3 }
        let isPasswordMatch = Publishers.CombineLatest($password, $confirmPassword)
            .map { password, confirmPasword in
                password == confirmPasword
            }
        return Publishers.CombineLatest3(validAccount, validPassword, isPasswordMatch)
            .map({ validAccount, validPassword, isPasswordMatch in
                return validAccount && validPassword && isPasswordMatch
            })
            .eraseToAnyPublisher()

    }
    
    enum VarifidationError: String, Error {
        case accountLength = "帳號長度錯誤"
        case passwordLength = "密碼長度錯誤"
        case confirmPasswordError = "請確認密碼"
        
        
    }
}
