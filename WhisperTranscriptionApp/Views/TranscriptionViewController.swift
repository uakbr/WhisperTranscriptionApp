import UIKit
import CoreData
import AVFoundation

class TranscriptionViewController: UIViewController {
    // MARK: - UI Elements
    private let transcriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isScrollEnabled = true
        return textView
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    private let saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
        return button
    }()
    
    private let shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        return button
    }()
    
    private let audioProgressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemBlue
        return progress
    }()
    
    // MARK: - Properties
    var transcription: Transcription?
    private var isPlaying = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        navigationItem.rightBarButtonItems = [saveButton, shareButton]
        
        view.addSubview(transcriptionTextView)
        view.addSubview(playButton)
        view.addSubview(audioProgressView)
        
        transcriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        audioProgressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            playButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            transcriptionTextView.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 10),
            transcriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            transcriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            transcriptionTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            
            audioProgressView.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 8),
            audioProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            audioProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
        
        if let transcription = transcription {
            transcriptionTextView.text = transcription.text
        }
    }
    
    // MARK: - Actions
    private func setupActions() {
        saveButton.target = self
        saveButton.action = #selector(saveTranscription)
        
        shareButton.target = self
        shareButton.action = #selector(shareTranscription)
        
        playButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
    }
    
    @objc private func togglePlayback() {
        guard let audioURL = transcription?.audioURL else {
            ErrorAlertManager.shared.showAlert(
                title: "Playback Error",
                message: "Audio file not found"
            )
            return
        }
        
        isPlaying.toggle()
        
        if isPlaying {
            playButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            AudioFileStorage.shared.playAudioFile(
                at: audioURL,
                progressHandler: { [weak self] progress in
                    self?.audioProgressView.progress = Float(progress)
                },
                completionHandler: { [weak self] in
                    self?.isPlaying = false
                    self?.playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
                    self?.audioProgressView.progress = 0
                }
            )
        } else {
            playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            AudioFileStorage.shared.stopPlayback()
        }
    }
    
    @objc private func saveTranscription() {
        guard let transcription = transcription else { return }
        transcription.text = transcriptionTextView.text
        
        TranscriptionStorageManager.shared.saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func shareTranscription() {
        guard let text = transcriptionTextView.text else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.barButtonItem = shareButton
        }
        
        present(activityVC, animated: true)
    }
}