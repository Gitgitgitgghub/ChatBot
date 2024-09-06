//
//  StarButton.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/22.
//

import Foundation
import UIKit

class StarButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = 10
        self.backgroundColor = .fromAppColors(\.lightCoffeeButton)
        self.setImage(UIImage(systemName: "star")?.withTintColor(.fromAppColors(\.secondaryText), renderingMode: .alwaysOriginal), for: .normal)
        self.setImage(UIImage(systemName: "star.fill")?.withTintColor(.fromAppColors(\.titleHighlight), renderingMode: .alwaysOriginal), for: .selected)
        self.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped() {
        self.isSelected.toggle()
        UIView.animate(withDuration: 0.1,
                       animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform.identity
            }
        })
    }
}
