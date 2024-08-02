//
//  TextEditorViews.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/2.
//

import Foundation
import UIKit


protocol TextEditorViewsProtocol: AnyObject {
    
    func onActionButtonClick(action: TextEditorViewController.Action)
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
    lazy var actions: [TextEditorViewController.Action] = TextEditorViewController.Action.allCases
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
        actionCollectionView.register(ActionCell.self, forCellWithReuseIdentifier: ActionCell.className)
    }
    
    func getCellButton(action: TextEditorViewController.Action) -> UIButton? {
        guard let cell = actionCollectionView.cellForItem(at: .init(item: action.rawValue, section: 0)) as? ActionCell else { return nil }
        return cell.button
    }
    
    func toggleActionButton(action: TextEditorViewController.Action) {
        guard let button =  getCellButton(action: action) else { return }
        guard action.enableSelected() else { return }
        switch action {
            // 這三顆按鈕互斥
        case .textAlignLeft, .textAlignCenter, .textAlignRight:
            let alignActions: [TextEditorViewController.Action] = [.textAlignLeft, .textAlignCenter, .textAlignRight]
            alignActions.forEach { alignAction in
                if alignAction != action {
                    guard let otherButton = getCellButton(action: alignAction) else { return }
                    otherButton.isSelected = false
                    otherButton.tintColor = .systemGray
                    otherButton.backgroundColor = .white
                }
            }
            button.isSelected = true
            button.tintColor = .white
            button.backgroundColor = .systemGray
        default:
            button.isSelected.toggle()
            button.tintColor = button.isSelected ? .white : .systemGray
            button.backgroundColor = button.isSelected ? .systemGray : .white
        }
    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension TextEditorViews: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let action = TextEditorViewController.Action.init(rawValue: indexPath.item) else { return UICollectionViewCell() }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionCell.className, for: indexPath)
        as! ActionCell
        cell.tag = action.rawValue
        switch action {
        case .fontColor:
            cell.setColor(title: "Text Color", color: .white)
        case .highlightColor:
            cell.setColor(title: "Highlight", color: .clear)
        case .fontSize:
            cell.setFontSize(size: 16)
        case .font:
            cell.setFontName(name: "Arial")
        default:
            cell.setButton(image: action.image)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let action = TextEditorViewController.Action.init(rawValue: indexPath.item) else { return }
        toggleActionButton(action: action)
        delegate?.onActionButtonClick(action: action)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let action = TextEditorViewController.Action.init(rawValue: indexPath.item) else { return .zero }
        switch action {
        case .fontColor:
            return CGSize(width: 110, height: 30)
        case .highlightColor:
            return CGSize(width: 110, height: 30)
        case .fontSize:
            return CGSize(width: 110, height: 30)
        case .font:
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
        
        func setButton(image: UIImage?) {
            button.isVisible = true
            button.tintColor = .systemGray
            button.setImage(image, for: .normal)
        }
        
        func setColor(title: String, color: UIColor) {
            button.isVisible = false
            label.isVisible = true
            colorView.isVisible = true
            label.text = title
            colorView.backgroundColor = color
        }
        
        func setFontName(name: String) {
            button.isVisible = false
            label.isVisible = true
            colorView.isVisible = false
            label.font = UIFont(name: name, size: 16)
            label.text = "字型：\(name)"
        }
        
        func setFontSize(size: CGFloat) {
            button.isVisible = false
            label.isVisible = true
            colorView.isVisible = false
            let size = Int(size)
            label.text = "文字大小：\(size)"
        }
        
    }
    
}

extension TextEditorViews: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}
