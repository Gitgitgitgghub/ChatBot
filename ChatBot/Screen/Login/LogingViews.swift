//
//  LogingViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/14.
//

import Foundation
import UIKit


class LogingViews: ControllerView {
    
    lazy var accountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.text = "Account"
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
        label.textColor = .black
        label.text = "Password"
        return label
    }()
    lazy var confirmPwLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.text = "Confirm Password"
        return label
    }()
    lazy var accountTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "input your account"
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }()
    lazy var pwTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "input your password"
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }()
    lazy var confirmPwTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "confirm your password"
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }()
    
    lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        button.backgroundColor = .blue.withAlphaComponent(0.8)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        return button
    }()
    lazy var calcelAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("boom", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        button.backgroundColor = .blue.withAlphaComponent(0.8)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        return button
    }()
    lazy var loadingView: LoadingView = {
        let view = LoadingView(messgae: "登入中請稍候")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        return view
    }()
    
    override func initUI() {
        view.backgroundColor = .white
        view.addSubview(accountLabel)
        view.addSubview(pwLabel)
        view.addSubview(confirmPwLabel)
        view.addSubview(accountTextField)
        view.addSubview(pwTextField)
        view.addSubview(confirmPwTextField)
        view.addSubview(loginButton)
        view.addSubview(errorLabel)
        view.addSubview(loadingView)
        view.addSubview(calcelAllButton)
        accountTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(50)
            make.top.equalToSuperview().inset(250)
            make.height.equalTo(40)
        }
        accountLabel.snp.makeConstraints { make in
            make.leading.equalTo(accountTextField).inset(3)
            make.bottom.equalTo(accountTextField.snp.top).offset(-5)
        }
        pwLabel.snp.makeConstraints { make in
            make.leading.equalTo(accountLabel)
            make.top.equalTo(accountTextField.snp.bottom).offset(5)
        }
        pwTextField.snp.makeConstraints { make in
            make.leading.equalTo(accountTextField)
            make.size.equalTo(accountTextField)
            make.top.equalTo(pwLabel.snp.bottom).offset(5)
        }
        confirmPwLabel.snp.makeConstraints { make in
            make.leading.equalTo(accountLabel)
            make.top.equalTo(pwTextField.snp.bottom).offset(5)
        }
        confirmPwTextField.snp.makeConstraints { make in
            make.leading.equalTo(accountTextField)
            make.size.equalTo(accountTextField)
            make.top.equalTo(confirmPwLabel.snp.bottom).offset(5)
        }
        loginButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 100, height: 40))
            make.centerX.equalToSuperview()
            make.top.equalTo(confirmPwTextField.snp.bottom).offset(20)
        }
        calcelAllButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 100, height: 40))
            make.centerX.equalToSuperview()
            make.top.equalTo(loginButton.snp.bottom).offset(20)
        }
        errorLabel.snp.makeConstraints { make in
            make.bottom.equalTo(accountLabel.snp.top).offset(-10)
            make.centerX.equalToSuperview()
        }
        loadingView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 200, height: 200))
            make.center.equalToSuperview()
        }
    }
    
}
