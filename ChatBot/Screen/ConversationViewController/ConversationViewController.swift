//
//  ConversationViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/18.
//

import Foundation
import UIKit


class ConversationViewController: BaseUIViewController<ConversationViewModel> {
    

    private lazy var views = ConversationViews(view: self.view)
    private var tableView: UITableView {
        return views.tableView
    }
    
    init(scenario: Scenario) {
        super.init(viewModel: .init(scenario: scenario))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestMicrophoneAccess()
        initUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sendInputEvent(.release)
    }
    
    private func initUI() {
        title = "語音對話"
        views.recordButton.addTarget(self, action: #selector(recoderButtonClicked), for: .touchUpInside)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: ConversationViews.SystemCell.self)
        tableView.register(cellType: ConversationViews.UserCell.self)
        tableView.estimatedRowHeight = UITableView.automaticDimension
        views.recordingView.delegate = self
    }
    
    override func handleOutputEvent(_ outputEvent: ConversationViewModel.OutputEvent) {
        switch outputEvent {
        case .volumeChanged(value: let value):
            self.volumeChanged(value: value)
        case .reloadData:
            self.tableView.reloadData()
        case .showScenario(scenario: let scenario):
            self.showScenario(scenario: scenario)
        case .showTranslation(translation: let translation):
            self.showTranslation(translation: translation)
        }
    }
    
    override func onLoadingStatusChanged(status: LoadingStatus) {
        switch status {
        case .error(error: let error):
            showToast(message: error.localizedDescription)
        default:
            views.showLoadingView(status: status, with: "加載中..")
        }
    }
    
    private func showTranslation(translation: String) {
        let alert = UIAlertController(title: "翻譯", message: translation, preferredStyle: .alert)
        alert.addAction(.init(title: "關閉", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showScenario(scenario: Scenario?) {
        guard let scenario = scenario else { return }
        views.scenarioView.isVisible = true
        views.scenarioView.bindScenario(scenario: scenario)
    }
    
    private func volumeChanged(value: Float) {
        views.recordingView.volumeProgressView.progress = value
    }
    
    @objc private func recoderButtonClicked() {
        views.recordingView.isVisible = !views.recordingView.isVisible

    }
    
    private func showInputAlert() {
        let vc = UIAlertController(title: "儲存筆記", message: "請輸入標題", preferredStyle: .alert)
        vc.addTextField { textField in
            textField.text = ""
        }
        vc.addAction(.init(title: "保存", style: .default, handler: { action in
            self.sendInputEvent(.userInput(input: vc.textFields?.first?.text ?? "123"))
        }))
        vc.addAction(.init(title: "取消", style: .cancel))
        present(vc, animated: true)
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource, AudioCellDelegate
extension ConversationViewController: UITableViewDelegate, UITableViewDataSource, AudioCellDelegate {
    
    func hintButtonClicked(indexPath: IndexPath) {
        sendInputEvent(.hintButtonClicked(indexPath: indexPath))
    }
    
    func spekaButtonClicked(indexPath: IndexPath) {
        sendInputEvent(.playAudio(indexPath: indexPath))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.audioResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let audioResult = viewModel.audioResults[indexPath.row]
        switch audioResult.role {
        case .ai:
            let cell = tableView.dequeueReusableCell(with: ConversationViews.SystemCell.self, for: indexPath)
            cell.bindAudioResult(audioResult: audioResult, indexPath: indexPath)
            cell.delegate = self
            return cell
        case .user:
            let cell = tableView.dequeueReusableCell(with: ConversationViews.UserCell.self, for: indexPath)
            cell.bindAudioResult(audioResult: audioResult, indexPath: indexPath)
            cell.delegate = self
            return cell
        default: return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    
}

extension ConversationViewController: RecordingViewDelegate {
    
    func startRecording() {
        sendInputEvent(.startRecording)
    }
    
    func stopRecording() {
        sendInputEvent(.stopRecording)
    }
    
}
