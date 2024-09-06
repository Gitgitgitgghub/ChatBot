//
//  HomeViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/3.
//

import Foundation
import UIKit


class HomeViews: ControllerView {
    
    var functionsStackView = UIStackView().apply { view in
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.alignment = .center
        view.distribution = .equalSpacing
        view.spacing = 15
    }
    /// function監聽
    var functionClickListener: (_ function: SystemDefine.HomeEnableFunction) -> () = { _ in
        
    }

    
    override func initUI() {
        view.addSubview(functionsStackView)
        functionsStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(100)
        }
        addFunctionButtons()
    }
    
    private func addFunctionButtons() {
        let enableFunctions = SystemDefine.HomeEnableFunction.allCases.filter({ $0.enable })
        for function in enableFunctions {
            let button = UIButton(type: .custom)
            button.setTitle(function.title, for: .normal)
            button.backgroundColor = .fromAppColors(\.lightCoffeeButton)
            button.setTitleColor(.fromAppColors(\.darkCoffeeText), for: .normal)
            button.cornerRadius = 10
            button.tag = function.rawValue
            button.addTarget(self, action: #selector(onFunctionButtonClicked(sender:)), for: .touchUpInside)
            button.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 100, height: 50))
            }
            functionsStackView.addArrangedSubview(button)
        }
    }
    
    @objc private func onFunctionButtonClicked(sender: UIButton) {
        guard let function = SystemDefine.HomeEnableFunction(rawValue: sender.tag) else { return }
        functionClickListener(function)
    }
    
}
