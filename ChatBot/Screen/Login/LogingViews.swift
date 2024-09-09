//
//  LogingViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import Foundation
import UIKit
import NVActivityIndicatorView


class LogingViews: ControllerView {
    
    lazy var accountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .fromAppColors(\.darkCoffeeText)
        label.text = "帳號"
        return label
    }()
    lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .red
        return label
    }()
    lazy var pwLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .fromAppColors(\.darkCoffeeText)
        label.text = "密碼"
        return label
    }()
    lazy var confirmPwLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .fromAppColors(\.darkCoffeeText)
        label.text = "確認密碼"
        return label
    }()
    lazy var accountTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "請輸入帳號"
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        return textField
    }()
    lazy var pwTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "請輸入密碼"
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        return textField
    }()
    lazy var confirmPwTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "請確認你的密碼"
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("登入", for: .normal)
        button.setTitleColor(.fromAppColors(\.darkCoffeeText), for: .normal)
        button.setTitleColor(.fromAppColors(\.secondaryText), for: .disabled)
        button.backgroundColor = .fromAppColors(\.lightCoffeeButton)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        return button
    }()
    lazy var switchLoginMethodButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("切換登入方式", for: .normal)
        button.setTitleColor(.fromAppColors(\.darkCoffeeText), for: .normal)
        button.setTitleColor(.fromAppColors(\.secondaryText), for: .disabled)
        button.backgroundColor = .fromAppColors(\.lightCoffeeButton)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        return button
    }()
    override var backgroundColor: UIColor {
        return .fromAppColors(\.secondaryButtonBackground)
    }
    
    override func initUI() {
        view.addSubview(accountLabel)
        view.addSubview(pwLabel)
        view.addSubview(confirmPwLabel)
        view.addSubview(accountTextField)
        view.addSubview(pwTextField)
        view.addSubview(confirmPwTextField)
        view.addSubview(loginButton)
        view.addSubview(errorLabel)
        view.addSubview(switchLoginMethodButton)
        accountTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(250)
            make.height.equalTo(40)
        }
        accountLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(accountTextField.snp.top).offset(-5)
        }
        pwLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(accountTextField.snp.bottom).offset(5)
        }
        pwTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.size.equalTo(accountTextField)
            make.top.equalTo(pwLabel.snp.bottom).offset(5)
        }
        confirmPwLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(pwTextField.snp.bottom).offset(5)
        }
        confirmPwTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.size.equalTo(accountTextField)
            make.top.equalTo(confirmPwLabel.snp.bottom).offset(5)
        }
        loginButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 100, height: 40))
            make.centerX.equalToSuperview()
            make.top.equalTo(confirmPwTextField.snp.bottom).offset(20)
        }
        switchLoginMethodButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 150, height: 40))
            make.centerX.equalToSuperview()
            make.top.equalTo(loginButton.snp.bottom).offset(20)
        }
        errorLabel.snp.makeConstraints { make in
            make.bottom.equalTo(accountLabel.snp.top).offset(-10)
            make.centerX.equalToSuperview()
        }
    }
    
    func switchLoginMethod(method: LoginViewController.LogingMethod) {
        pwTextField.isVisible = method == .account
        pwLabel.isVisible = method == .account
        confirmPwLabel.isVisible = method == .account
        confirmPwTextField.isVisible = method == .account
        accountLabel.text = method == .account ? "帳號" : "金鑰"
        accountTextField.placeholder = method == .account ? "請輸入帳號" : "請輸入金鑰"
        accountTextField.text = ""
        confirmPwTextField.text = ""
        confirmPwTextField.text = ""
    }
    
}
