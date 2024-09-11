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
    private let typeOptions: [SystemDefine.EnglishExam.QuestionType] = SystemDefine.EnglishExam.QuestionType.allCases
    private var selectedTypeIndex = 0
    /// 排序選項
    private let sortingOptions = SystemDefine.EnglishExam.SortOption.allCases
    private var selectedSortingIndex = 0
    var completionHandler: ((_ QuestionType: SystemDefine.EnglishExam.QuestionType?) -> Void)?
    private let pickerView = UIPickerView().apply {
        $0.isVisible = false
    }
    private let questionTypeStackView = UIStackView().apply {
        $0.isVisible = false
    }
    private let sortOptionsStackView = UIStackView().apply {
        $0.isVisible = false
    }
    private let typeOptionLabel = UILabel().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.text = "問題類型"
        $0.textColor = .darkGray
        $0.font = .boldSystemFont(ofSize: 16)
        $0.isVisible = false
    }
    private let sortOptionLabel = UILabel().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.text = "問題排序"
        $0.textColor = .darkGray
        $0.font = .boldSystemFont(ofSize: 16)
        $0.isVisible = false
    }
    /// 顯示的ＵＩ組件
    private(set) var selectorComponent: [SelectorComponent] = SelectorComponent.allCases
    
    enum SelectorComponent: CaseIterable {
        case letterPicker
        case questionTypeSelector
        case sortSelector
    }
    
    init(selectorComponent: [SelectorComponent] = SelectorComponent.allCases) {
        super.init(nibName: nil, bundle: nil)
        self.selectorComponent = selectorComponent
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        setUIComponentVisible()
        var lastView: UIView? = nil
        // 開頭字母
        if selectorComponent.contains(.letterPicker) {
            view.addSubview(pickerView)
            pickerView.delegate = self
            pickerView.dataSource = self
            pickerView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(150)
            }
            lastView = pickerView
        }
        // 題型
        if selectorComponent.contains(.questionTypeSelector) {
            view.addSubview(typeOptionLabel)
            view.addSubview(questionTypeStackView)
            typeOptionLabel.snp.makeConstraints { make in
                if let lastView = lastView {
                    make.top.equalTo(lastView.snp.bottom).offset(10)
                } else {
                    make.top.equalToSuperview().offset(10)
                }
                make.leading.trailing.equalToSuperview().inset(10)
                make.height.equalTo(20)
            }
            questionTypeStackView.snp.makeConstraints { make in
                make.top.equalTo(typeOptionLabel.snp.bottom).offset(5)
                make.leading.trailing.equalToSuperview().inset(10)
            }
            addQuestionTypeOptions()
            lastView = questionTypeStackView
        }
        // 排序
        if selectorComponent.contains(.sortSelector) {
            view.addSubview(sortOptionLabel)
            view.addSubview(sortOptionsStackView)
            sortOptionLabel.snp.makeConstraints { make in
                if let lastView = lastView {
                    make.top.equalTo(lastView.snp.bottom).offset(5)
                } else {
                    make.top.equalToSuperview().offset(10)
                }
                make.leading.trailing.equalToSuperview().inset(10)
                make.height.equalTo(20)
            }
            
            sortOptionsStackView.snp.makeConstraints { make in
                make.top.equalTo(sortOptionLabel.snp.bottom).offset(5)
                make.leading.trailing.equalToSuperview().inset(10)
                make.bottom.equalToSuperview().inset(10)
            }
            addSortOptions()
            lastView = sortOptionsStackView
        }
        updatePreferredContentSize()
    }
    
    private func updatePreferredContentSize() {
        view.layoutIfNeeded()
        var totalHeight: CGFloat = 0
        if selectorComponent.contains(.letterPicker) {
            totalHeight += pickerView.frame.height
        }
        if selectorComponent.contains(.questionTypeSelector) {
            totalHeight += typeOptionLabel.frame.height + questionTypeStackView.frame.height + 15
        }
        if selectorComponent.contains(.sortSelector) {
            totalHeight += sortOptionLabel.frame.height + sortOptionsStackView.frame.height + 15
        }
        preferredContentSize = CGSize(width: 300, height: totalHeight + 30) // 额外加上全局的间距
    }
    
    
    private func setUIComponentVisible() {
        for component in selectorComponent {
            switch component {
            case .letterPicker:
                pickerView.isVisible = true
            case .questionTypeSelector:
                questionTypeStackView.isVisible = true
                typeOptionLabel.isVisible = true
            case .sortSelector:
                sortOptionLabel.isVisible = true
                sortOptionsStackView.isVisible = true
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layoutIfNeeded()
        updatePreferredContentSize()
    }
    
    private func addQuestionTypeOptions() {
        questionTypeStackView.axis = .vertical
        questionTypeStackView.spacing = 2
        questionTypeStackView.distribution = .fillEqually
        questionTypeStackView.translatesAutoresizingMaskIntoConstraints = false
        for (index, option) in typeOptions.enumerated() {
            let optionButton = createOptionButton(with: option.title, tag: index)
            questionTypeStackView.addArrangedSubview(optionButton)
        }
    }
    
    private func addSortOptions() {
        sortOptionsStackView.axis = .vertical
        sortOptionsStackView.spacing = 2
        sortOptionsStackView.distribution = .fillEqually
        sortOptionsStackView.translatesAutoresizingMaskIntoConstraints = false
        for (index, option) in sortingOptions.enumerated() {
            let optionButton = createOptionButton(with: option.rawValue, tag: index)
            sortOptionsStackView.addArrangedSubview(optionButton)
        }
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
        button.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 280, height: 44))
        }
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
        if sortOptionsStackView.arrangedSubviews.contains(sender) {
            selectedSortingIndex = sender.tag
            for case let button as UIButton in sortOptionsStackView.arrangedSubviews {
                updateButtonAppearance(button, selected: button.tag == selectedSortingIndex)
            }
        }
        if questionTypeStackView.arrangedSubviews.contains(sender) {
            selectedTypeIndex = sender.tag
            for case let button as UIButton in questionTypeStackView.arrangedSubviews {
                updateButtonAppearance(button, selected: button.tag == selectedTypeIndex)
            }
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
    
    func show(in viewController: UIViewController, completionHandler: @escaping ((_ QuestionType: SystemDefine.EnglishExam.QuestionType?) -> Void)) {
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
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    private func onCompletion() {
        switch typeOptions[selectedTypeIndex] {
        case .vocabularyCloze:
            completionHandler?(.vocabularyCloze(letter: selectedLetter ?? "", sortOption: sortingOptions[selectedSortingIndex]))
        case .vocabularyWord:
            completionHandler?(.vocabularyWord(letter: selectedLetter ?? "", sortOption: sortingOptions[selectedSortingIndex]))
        default: break
        }
    }
}





