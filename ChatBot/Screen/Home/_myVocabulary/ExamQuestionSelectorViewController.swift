//
//  ExamQuestionSelectorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/23.
//

import UIKit
import SnapKit

class ExamQuestionSelectorViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    private let letters: [String] = ["隨機", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    private var selectedLetter: String?
    private var selectedSortingOption: String?
    private let sortingOptions = SystemDefine.VocabularyExam.SortOption.allCases
    private var selectedSortingIndex = 0
    var completionHandler: ((String?, String?) -> Void)?
    private let pickerView = UIPickerView()
    private let optionsStackView = UIStackView()

    init() {
        super.init(nibName: nil, bundle: nil)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        view.addSubview(pickerView)
        view.addSubview(optionsStackView)
        pickerView.delegate = self
        pickerView.dataSource = self
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 10
        optionsStackView.distribution = .fillEqually
        for (index, option) in sortingOptions.enumerated() {
            let optionButton = createOptionButton(with: option.rawValue, tag: index)
            optionsStackView.addArrangedSubview(optionButton)
        }
        pickerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(150)
        }
        optionsStackView.snp.makeConstraints { make in
            make.top.equalTo(pickerView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(10)
        }
        preferredContentSize = CGSize(width: 250, height: 300)
    }
    
    private func createOptionButton(with title: String, tag: Int) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = .black
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0)
        configuration.buttonSize = .medium
        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.tag = tag
        button.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
        updateButtonAppearance(button, selected: tag == selectedSortingIndex)
        return button
    }
    
    private func updateButtonAppearance(_ button: UIButton, selected: Bool) {
        if selected {
            button.configuration?.background.backgroundColor = .systemGray5
            button.configuration?.baseForegroundColor = .systemBlue
        } else {
            button.configuration?.background.backgroundColor = .clear
            button.configuration?.baseForegroundColor = .black
        }
    }
    
    @objc private func optionSelected(_ sender: UIButton) {
        selectedSortingIndex = sender.tag
        selectedSortingOption = sortingOptions[selectedSortingIndex].rawValue
        for case let button as UIButton in optionsStackView.arrangedSubviews {
            updateButtonAppearance(button, selected: button.tag == selectedSortingIndex)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return letters.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return letters[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedLetter = letters[row]
        print("Selected letter: \(selectedLetter ?? "")")
    }
    
    func show(in viewController: UIViewController, completionHandler: @escaping ((_ letter: String?, _ sortOption: String?) -> Void)) {
        self.completionHandler = completionHandler
        self.selectedLetter = letters.first
        self.selectedSortingOption = sortingOptions.first?.rawValue
        let alertController = UIAlertController(title: "選擇出題類型", message: nil, preferredStyle: .alert)
        alertController.setValue(self, forKey: "contentViewController")
        alertController.addAction(UIAlertAction(title: "確認", style: .default, handler: { [weak self] _ in
            self?.completionHandler?(self?.selectedLetter, self?.selectedSortingOption)
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { [weak self] _ in
            self?.completionHandler?(nil, nil)
        }))
        viewController.present(alertController, animated: true, completion: nil)
    }
}





