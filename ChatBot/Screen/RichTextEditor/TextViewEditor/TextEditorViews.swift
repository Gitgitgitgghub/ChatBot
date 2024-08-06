//
//  TextEditorViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/2.
//

import Foundation
import UIKit
import SnapKit


protocol TextEditorViewsProtocol: AnyObject {
    
    func getActionUIStatus() -> ActionUIStatusModel
    
    func getActions() -> [TextEditorViewController.Action]
    
    func onActionButtonClick(action: TextEditorViewController.Action, indexPath: IndexPath)
}

class TextEditorViews: ControllerView {
    
    typealias Action = ActionUIStatusModel.Action
    
    lazy var actionCollectionView: UICollectionView = {
        let layout = CollectionViewLeftAlignedLayout()
        layout.sectionInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.layer.borderColor = UIColor.lightGray.cgColor
        collectionView.layer.borderWidth = 1
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    lazy var textView = NoActionTextView().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.cornerRadius = 10
        $0.delegate = self
        $0.textColor = .white
    }
    var actions: [Action] {
        return delegate?.getActions() ?? []
    }
    var actionUIStatus: ActionUIStatusModel? {
        return delegate?.getActionUIStatus()
    }
    weak var delegate: TextEditorViewsProtocol?
    private var textViewBottomConstraint: Constraint?
    
    override func initUI() {
        view.addSubview(actionCollectionView)
        view.addSubview(textView)
        actionCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(150)
        }
        textView.snp.makeConstraints { make in
            make.top.equalTo(actionCollectionView.snp.bottom).offset(10)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            textViewBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10).constraint
        }
        actionCollectionView.dataSource = self
        actionCollectionView.delegate = self
        actionCollectionView.register(cellType: ActionCell.self)
    }
    
    func updateTextViewBottomConstraint(keyboardHeight: CGFloat) {
        textViewBottomConstraint?.update(offset: -keyboardHeight)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension TextEditorViews: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with: ActionCell.self, for: indexPath)
        cell.tag = indexPath.item
        let action = actions[indexPath.item]
        guard let actionUIStatus = self.actionUIStatus else { return cell }
        cell.bindAction(action: action, actionUIStatus: actionUIStatus)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let action = actions[indexPath.item]
        delegate?.onActionButtonClick(action: action, indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let action = actions[indexPath.item]
        switch action {
        case .fontColor:
            return CGSize(width: 110, height: 30)
        case .highlightColor:
            return CGSize(width: 110, height: 30)
        case .fontSize:
            return CGSize(width: 110, height: 30)
        case .fontName:
            return CGSize(width: actionCollectionView.frame.width, height: 30)
        default: return CGSize(width: 30, height: 30)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

//MARK: ActionCell
extension TextEditorViews {
    
    class ActionCell: UICollectionViewCell {
        
        lazy var button: UIButton = {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.isUserInteractionEnabled = false
            button.isVisible = false
            return button
        }()
        lazy var label: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .systemGray
            label.font = .systemFont(ofSize: 16)
            label.numberOfLines = 1
            label.isVisible = false
            return label
        }()
        lazy var colorView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .white
            view.layer.cornerRadius = 12
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.black.cgColor
            view.isVisible = false
            return view
        }()
        var action: TextEditorViewController.Action?
        var actionUIStatus: ActionUIStatusModel?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func commonInit() {
            contentView.addSubview(button)
            contentView.addSubview(label)
            contentView.addSubview(colorView)
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(5)
                make.centerY.equalToSuperview()
            }
            colorView.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 24, height: 24))
                make.leading.equalTo(label.snp.trailing).offset(5)
                make.centerY.equalToSuperview()
            }
        }
        
        func bindAction(action: TextEditorViewController.Action, actionUIStatus: ActionUIStatusModel) {
            self.action = action
            self.actionUIStatus = actionUIStatus
            switch action {
            case .bold:
                setButton(isSeleted: actionUIStatus.bold)
            case .italic:
                setButton(isSeleted: actionUIStatus.italic)
            case .underline:
                setButton(isSeleted: actionUIStatus.underline)
            case .strikethrough:
                setButton(isSeleted: actionUIStatus.strikethrough)
            case .textAlignLeft:
                setButton(isSeleted: actionUIStatus.textAlignLeft)
            case .textAlignCenter:
                setButton(isSeleted: actionUIStatus.textAlignCenter)
            case .textAlignRight:
                setButton(isSeleted: actionUIStatus.textAlignRight)
            case .insertImage, .link:
                setButton(isSeleted: false)
            case .fontColor:
                setColor(color: actionUIStatus.fontColor)
            case .highlightColor:
                setColor(color: actionUIStatus.highlightColor)
            case .fontSize:
                setFontSize(size: actionUIStatus.fontSize)
            case .fontName:
                setFontName(name: actionUIStatus.fontName)
            }
        }
        
        private func setButton(isSeleted: Bool) {
            guard let action = self.action else { return }
            button.isVisible = true
            label.isVisible = false
            colorView.isVisible = false
            button.setImage(action.image, for: .normal)
            if action.enableToggle() {
                button.tintColor = isSeleted ? .white : .systemGray
                button.backgroundColor = !isSeleted ? .white : .systemGray
            }else {
                button.backgroundColor = .white
                button.tintColor = .systemGray
            }
        }
        
        private func setColor(color: UIColor) {
            guard let action = self.action else { return }
            button.isVisible = false
            label.isVisible = true
            colorView.isVisible = true
            label.text = action.actionName
            colorView.backgroundColor = color
        }
        
        private func setFontName(name: String) {
            guard let action = self.action else { return }
            button.isVisible = false
            label.isVisible = true
            colorView.isVisible = false
            label.font = UIFont(name: name, size: 16)
            label.text = "\(action.actionName)：\(name)"
        }
        
        private func setFontSize(size: CGFloat) {
            guard let action = self.action else { return }
            button.isVisible = false
            label.isVisible = true
            colorView.isVisible = false
            let size = Int(size)
            label.text = "\(action.actionName)：\(size)"
        }
        
    }
    
}

extension TextEditorViews: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}
