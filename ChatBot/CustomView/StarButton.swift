//
//  StarButton.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/22.
//

import Foundation
import UIKit

class StarButton: AnimationButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    
    private func initUI() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = 10
        self.backgroundColor = .fromAppColors(\.lightCoffeeButton)
        self.setImage(UIImage(systemName: "star")?.withTintColor(.fromAppColors(\.secondaryText), renderingMode: .alwaysOriginal), for: .normal)
        self.setImage(UIImage(systemName: "star.fill")?.withTintColor(.fromAppColors(\.titleHighlight), renderingMode: .alwaysOriginal), for: .selected)
    }
    
    override func buttonTappedAnimation() {
        isSelected.toggle()
        super.buttonTappedAnimation()
    }
}
