//
//  LoginViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import UIKit
import Combine
import OpenAI

class LoginViewController: BaseUIViewController {
    
    private lazy var views = LogingViews(view: self.view)
    private lazy var viewModel = LoginViewModel(validation: UserValidation())

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
    }
    
    private func initUI() {
        title = "Login"
        views.accountTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        views.pwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        views.confirmPwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        views.accountTextField.delegate = self
        views.pwTextField.delegate = self
        views.confirmPwTextField.delegate = self
        views.loginButton.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
        views.calcelAllButton.addTarget(self, action: #selector(boom), for: .touchUpInside)
    }
    
    private func bind() {
        viewModel.validation.$isLoginButtonEnabled
            .sink { [weak self] isEnable in
                self?.views.loginButton.isEnabled = isEnable
            }
            .store(in: &subscriptions)
        viewModel.validation.$errorMessage
            .sink { [weak self] errorMessgae in
                self?.views.errorLabel.text = errorMessgae
            }
            .store(in: &subscriptions)
        viewModel.$isLoading
            .sink { [weak self] status in
                switch status {
                case .none:
                    self?.views.loadingView.isVisible = false
                case .loading:
                    self?.views.loadingView.isVisible = true
                case .failure(error: _):
                    self?.views.loadingView.isVisible = false
                case .success:
                    self?.views.loadingView.isVisible = false
                    let vc = ChatViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            .store(in: &subscriptions)
    }
    
    @objc private func loginButtonClicked() {
        viewModel.trasformInput(input: .login)
    }
    
    @objc private func boom() {
        viewModel.unbindings()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }
        switch textField {
        case views.accountTextField:
            viewModel.trasformInput(input: .account(text: text))
        case views.pwTextField:
            viewModel.trasformInput(input: .password(text: text))
        case views.confirmPwTextField:
            viewModel.trasformInput(input: .confirmPassword(text: text))
        default: break
        }
    }
    
    deinit {
        subscriptions.removeAll()
    }

}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


