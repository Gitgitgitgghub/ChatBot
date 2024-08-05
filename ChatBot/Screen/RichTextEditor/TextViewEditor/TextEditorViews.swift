//
//  TextEditorViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/2.
//

import Foundation
import UIKit


protocol TextEditorViewsProtocol: AnyObject {
    
    func getActionDataSource() -> [TextEditorViewController.Action]
    
    func onActionButtonClick(action: TextEditorViewController.Action, indexPath: IndexPath)
}

class TextEditorViews: ControllerView {
    
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
    var actions: [TextEditorViewController.Action] {
        return delegate?.getActionDataSource() ?? []
    }
    weak var delegate: TextEditorViewsProtocol?
    
    override func initUI() {
        view.addSubview(actionCollectionView)
        view.addSubview(textView)
        actionCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(50)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(150)
        }
        textView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.height.greaterThanOrEqualTo(300)
            make.centerY.equalToSuperview()
        }
        actionCollectionView.dataSource = self
        actionCollectionView.delegate = self
        actionCollectionView.register(cellType: ActionCell.self)
    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension TextEditorViews: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let action = actions[indexPath.item]
        let cell = collectionView.dequeueReusableCell(with: ActionCell.self, for: indexPath)
        cell.tag = indexPath.item
        cell.bindAction(action: action)
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
        
        func bindAction(action: TextEditorViewController.Action) {
            self.action = action
            switch action {
            case .bold(let isSeleted), .italic(let isSeleted), .underline(let isSeleted), .strikethrough(let isSeleted), .textAlignLeft(let isSeleted), .textAlignCenter(let isSeleted), .textAlignRight(let isSeleted):
                setButton(isSeleted: isSeleted)
            case .insertImage, .link:
                setButton(isSeleted: false)
            case .fontColor(let color), .highlightColor(let color):
                setColor(color: color)
            case .fontSize(let size):
                setFontSize(size: size)
            case .fontName(let foneName):
                setFontName(name: foneName)
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
