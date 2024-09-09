//
//  SpeakButton.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/6.
//

import Foundation
import UIKit

class SpeakButton: AnimationButton {
    
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
        self.setImage(UIImage(systemName: "speaker.wave.2.fill")?.withTintColor(.fromAppColors(\.secondaryText), renderingMode: .alwaysOriginal), for: .normal)
    }
}
