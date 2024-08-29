//
//  GrammarPointSelectorViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/29.
//

import UIKit
import SnapKit

import UIKit
import SnapKit

class GrammarPointSelectorViewController: UIViewController {
    
    private var grammarPoints: [SystemDefine.EnglishExam.TOEICGrammarPoint?] = SystemDefine.EnglishExam.TOEICGrammarPoint.allCases
    private var selectedPoint: SystemDefine.EnglishExam.TOEICGrammarPoint? = nil
    private let scrollView = UIScrollView()
    private let radioButtonsView = RadioButtonGroupView().apply {
        $0.axis = .vertical
        $0.alignment = .fill
        $0.spacing = 15
    }
    private let containerView = UIView().apply {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }
    let confirmButton = UIButton(type: .system).apply {
        $0.setTitle("確定", for: .normal)
        $0.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        $0.setTitleColor(.systemBlue, for: .normal)
    }
    let cancelButton = UIButton(type: .system).apply {
        $0.setTitle("取消", for: .normal)
        $0.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        $0.setTitleColor(.systemRed, for: .normal)
    }
    let titleLabel = UILabel().apply {
        $0.text = "選擇想練習的文法"
        $0.font = UIFont.boldSystemFont(ofSize: 18)
        $0.textAlignment = .center
    }
    
    var completion: ((TOEICGrammarPoint?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        grammarPoints.insert(nil, at: 0)
        initUI()
    }
    
    private func initUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(confirmButton)
        containerView.addSubview(cancelButton)
        containerView.addSubview(scrollView)
        scrollView.addSubview(radioButtonsView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalToSuperview().multipliedBy(0.8)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(40)
        }
        radioButtonsView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalTo(scrollView.snp.width).offset(-40)
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.bottom).offset(10)
            make.bottom.equalTo(cancelButton.top).offset(-10)
            make.leading.trailing.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(44)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(44)
        }
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        addRatioButtons()
    }
    
    private func addRatioButtons() {
        for grammarPoint in grammarPoints {
            let button = RadioButton()
            button.setTitle(grammarPoint?.rawValue ?? "不指定", for: .normal)
            button.checkedBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            button.uncheckedBackgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
            button.setTitleColor(.systemBlue, for: .normal)
            button.layer.cornerRadius = 8
            button.snp.makeConstraints { make in
                make.height.equalTo(44)
            }
            button.addTarget(self, action: #selector(grammarPointSelected(_:)), for: .touchUpInside)
            radioButtonsView.addButton(button)
        }
        radioButtonsView.selectButton(index: 0)
    }
    
    func show(in vc: UIViewController, completion: @escaping ((TOEICGrammarPoint?) -> Void)) {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        self.completion = completion
        vc.present(self, animated: true)
    }
    
    @objc private func grammarPointSelected(_ sender: UIButton) {
        guard let index = radioButtonsView.arrangedSubviews.firstIndex(of: sender) else { return }
        selectedPoint = grammarPoints[index]
    }
    
    @objc private func confirmButtonTapped() {
        dismiss(animated: true) {
            self.completion?(nil)
        }
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
}





