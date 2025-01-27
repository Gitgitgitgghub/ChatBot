//
//  LoginViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import UIKit
import Combine
import OpenAI

class LoginViewController: BaseUIViewController<LoginViewModel> {
    
    private lazy var views = LogingViews(view: self.view)
    var loginMethod: LogingMethod = .account
    /// 登入方式
    enum LogingMethod {
        case account
        case key
    }
    
    override init() {
        super.init(viewModel: .init(validation: .init()))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bind()
        viewModel.trasformInput(input: .autoLogin)
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
        views.switchLoginMethodButton.addTarget(self, action: #selector(switchMethodButtonClick), for: .touchUpInside)
        views.platformButton.addTarget(self, action: #selector(swtichPlatform), for: .touchUpInside)
    }
    
    override func onLoadingStatusChanged(status: LoadingStatus) {
        views.showLoadingView(status: status)
        switch status {
        case .error(error: let error):
            loginFailed(errorMessage: error.localizedDescription)
        case .success:
            loginSuccess()
        default: break
        }
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
        viewModel.validation.$loginMethod
            .sink { [unowned self] method in
                self.views.switchLoginMethod(method: method)
            }
            .store(in: &subscriptions)
        viewModel.validation.$platform
            .sink { [unowned self] platform in
                self.views.switchPlatform(platform: platform)
            }
            .store(in: &subscriptions)
    }
    
    /// 登入成功替換掉畫面
    private func loginSuccess() {
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchRootToHomeViewController()
        }
    }
    
    private func loginFailed(errorMessage: String) {
        let alert = UIAlertController(title: "登入失敗", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func swtichPlatform() {
        viewModel.trasformInput(input: .switchAIPlatform)
    }
    
    @objc private func switchMethodButtonClick() {
        viewModel.trasformInput(input: .switchLoginMethod)
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


