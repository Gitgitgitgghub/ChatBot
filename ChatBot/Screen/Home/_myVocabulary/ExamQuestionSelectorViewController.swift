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
    /// 題型選項
    private let typeOptions: [SystemDefine.VocabularyExam.QuestionType] = SystemDefine.VocabularyExam.QuestionType.allCases
    private var selectedTypeIndex = 0
    /// 排序選項
    private let sortingOptions = SystemDefine.VocabularyExam.SortOption.allCases
    private var selectedSortingIndex = 0
    var completionHandler: ((_ QuestionType: SystemDefine.VocabularyExam.QuestionType?) -> Void)?
    private let pickerView = UIPickerView()
    private let questionTypeStackView = UIStackView()
    private let sortOptionsStackView = UIStackView()

    init() {
        super.init(nibName: nil, bundle: nil)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        view.addSubview(pickerView)
        view.addSubview(sortOptionsStackView)
        view.addSubview(questionTypeStackView)
        pickerView.delegate = self
        pickerView.dataSource = self
        questionTypeStackView.axis = .vertical
        questionTypeStackView.spacing = 10
        questionTypeStackView.distribution = .fillEqually
        sortOptionsStackView.axis = .vertical
        sortOptionsStackView.spacing = 10
        sortOptionsStackView.distribution = .fillEqually
        for (index, option) in typeOptions.enumerated() {
            let optionButton = createOptionButton(with: option.title, tag: index)
            questionTypeStackView.addArrangedSubview(optionButton)
        }
        for (index, option) in sortingOptions.enumerated() {
            let optionButton = createOptionButton(with: option.rawValue, tag: index)
            sortOptionsStackView.addArrangedSubview(optionButton)
        }
        pickerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(150)
        }
        questionTypeStackView.snp.makeConstraints { make in
            make.top.equalTo(pickerView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(10)
        }
        sortOptionsStackView.snp.makeConstraints { make in
            make.top.equalTo(questionTypeStackView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(10)
        }
        preferredContentSize = CGSize(width: 250, height: 350)
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
        for case let button as UIButton in sortOptionsStackView.arrangedSubviews {
            selectedSortingIndex = button.tag
            updateButtonAppearance(button, selected: button.tag == selectedSortingIndex)
        }
        for case let button as UIButton in questionTypeStackView.arrangedSubviews {
            selectedTypeIndex = button.tag
            updateButtonAppearance(button, selected: button.tag == selectedTypeIndex)
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
    
    func show(in viewController: UIViewController, completionHandler: @escaping ((_ QuestionType: SystemDefine.VocabularyExam.QuestionType?) -> Void)) {
        self.completionHandler = completionHandler
        self.selectedLetter = letters.first
        self.selectedTypeIndex = 0
        self.selectedSortingIndex = 0
        let alertController = UIAlertController(title: "選擇出題類型", message: nil, preferredStyle: .alert)
        alertController.setValue(self, forKey: "contentViewController")
        alertController.addAction(UIAlertAction(title: "確認", style: .default, handler: { [weak self] _ in
            guard let `self` = self else { return }
            self.onCompletion()
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { [weak self] _ in
            self?.completionHandler?(nil)
        }))
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    private func onCompletion() {
        switch typeOptions[selectedTypeIndex] {
        case .vocabularyCloze:
            completionHandler?(.vocabularyCloze(letter: selectedLetter ?? "", sortOption: sortingOptions[selectedSortingIndex]))
        case .vocabularyWord:
            completionHandler?(.vocabularyWord(letter: selectedLetter ?? "", sortOption: sortingOptions[selectedSortingIndex]))
        }
    }
}





