//
//  RadioButtonGroupView.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/29.
//

import Foundation
import UIKit

class RadioButtonGroupView: UIStackView {
    
    private var radioButtons: [RadioButton] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupStackView()
    }
    
    private func setupStackView() {
        self.axis = .vertical
        self.spacing = 10
        self.alignment = .center
    }
    
    func addButton(_ button: RadioButton) {
        self.addArrangedSubview(button)
        radioButtons.append(button)
    }
    
    func selectButton(_ selectedButton: RadioButton) {
        for button in radioButtons {
            button.setChecked(button == selectedButton)
        }
    }
    
    func selectButton(index: Int) {
        for (i, button) in radioButtons.enumerated() {
            button.setChecked(index == i)
        }
    }
}

class RadioButton: UIButton {
    
    private var isChecked: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    /// check時的背景顏色
    var checkedBackgroundColor: UIColor = .clear {
        didSet {
            updateAppearance()
        }
    }
    /// uncheck時的背景顏色
    var uncheckedBackgroundColor: UIColor = .clear {
        didSet {
            updateAppearance()
        }
    }
    /// check時的image
    var checkedImage: UIImage? = UIImage(systemName: "largecircle.fill.circle") {
        didSet {
            updateAppearance()
        }
    }
    /// uncheck時的image
    var uncheckedImage: UIImage? = UIImage(systemName: "circle") {
        didSet {
            updateAppearance()
        }
    }
    /// 圖片與文字的間距
    var spacing: CGFloat = 8.0 {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    
    private func initUI() {
        self.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        contentHorizontalAlignment = .center
        updateAppearance()
    }
    
    private func updateAppearance() {
        var config = self.configuration ?? UIButton.Configuration.plain()
        config.imagePlacement = .leading
        config.imagePadding = spacing
        //config.baseForegroundColor = isChecked ? checkedBackgroundColor : uncheckedBackgroundColor
        config.background.backgroundColor = isChecked ? checkedBackgroundColor : uncheckedBackgroundColor
        config.imagePadding = spacing
        config.image = isChecked ? checkedImage : uncheckedImage
        self.configuration = config
    }
    
    @objc private func buttonTapped() {
        if let group = self.superview as? RadioButtonGroupView {
            group.selectButton(self)
        }
    }
    
    func setChecked(_ checked: Bool) {
        self.isChecked = checked
    }
}

