//
//  SettingViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/7/9.
//

import UIKit

class SettingViewController: UIViewController {
    
    lazy var views = SettingViews(view: self.view)
    
    /// tableView Data
    private let settings: [[Setting]] = [
        [.logout],
        [.voiceSetting]
    ]
    /// 定義設定
    enum Setting: String {
        case logout = "登出"
        case voiceSetting = "聲音設定"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    private func initUI() {
        views.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        views.tableView.delegate = self
        views.tableView.dataSource = self
    }
    
    /// 處理cell點擊事件
    private func handleCellTap(indexPath: IndexPath) {
        views.tableView.deselectRow(at: indexPath, animated: false)
        let setting = settings[indexPath.section][indexPath.row]
        switch setting {
        case .logout:
            handelLogout()
        case .voiceSetting:
            handleVoiceSetting()
        }
    }
    
    /// 處理帳號登出
    private func handelLogout() {
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            AccountManager.shared.logout()
            sceneDelegate.switchRootToLoginViewController()
        }
    }
    
    /// 處理聲音設定
    private func handleVoiceSetting() {
        let vc = VoicePickerViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = settings[indexPath.section][indexPath.row].rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleCellTap(indexPath: indexPath)
    }
}
