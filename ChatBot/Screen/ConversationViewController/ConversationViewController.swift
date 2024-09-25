//
//  ConversationViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/18.
//

import Foundation
import UIKit


class ConversationViewController: BaseUIViewController {
    
    override var enableSwipeToGoBack: Bool {
        set {
            //super.enableSwipeToGoBack = newValue
        }
        get {
            return false
        }
    }
    private let viewModel: ConversationViewModel
    private lazy var views = ConversationViews(view: self.view)
    private var tableView: UITableView {
        return views.tableView
    }
    
    init(scenario: Scenario) {
        viewModel = ConversationViewModel(scenario: scenario)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestMicrophoneAccess()
        initUI()
        bind()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.transform(inputEvent: .stopRecording)
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
    
    private func bind() {
        viewModel.bindInputEvent()
        viewModel.outputSubject
            .sink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
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
            .store(in: &subscriptions)
        viewModel.loadingStatus
            .sink { [weak self] status in
                switch status {
                case .error(error: let error):
                    self?.showToast(message: error.localizedDescription)
                default:
                    self?.views.showLoadingView(status: status, with: "加載中..")
                }
            }
            .store(in: &subscriptions)
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
            self.viewModel.transform(inputEvent: .userInput(input: vc.textFields?.first?.text ?? "123"))
        }))
        vc.addAction(.init(title: "取消", style: .cancel))
        present(vc, animated: true)
    }
    
    override func handleBackAction() {
        viewModel.transform(inputEvent: .release)
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource, AudioCellDelegate
extension ConversationViewController: UITableViewDelegate, UITableViewDataSource, AudioCellDelegate {
    
    func hintButtonClicked(indexPath: IndexPath) {
        viewModel.transform(inputEvent: .hintButtonClicked(indexPath: indexPath))
    }
    
    func spekaButtonClicked(indexPath: IndexPath) {
        viewModel.transform(inputEvent: .playAudio(indexPath: indexPath))
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
        viewModel.transform(inputEvent: .startRecording)
    }
    
    func stopRecording() {
        viewModel.transform(inputEvent: .stopRecording)
    }
    
}
