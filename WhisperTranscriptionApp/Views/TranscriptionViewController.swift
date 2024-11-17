import UIKit
import AVFoundation

class TranscriptionViewController: UIViewController {
    // MARK: - UI Elements
    private let transcriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8.0
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.textColor = .label
        return textView
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.widthAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        button.accessibilityIdentifier = "playButton"
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
        progress.trackTintColor = .systemGray5
        return progress
    }()
    
    // MARK: - Properties
    var transcription: Transcription?
    private var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
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
            playButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            playButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            audioProgressView.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            audioProgressView.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 10),
            audioProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            transcriptionTextView.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 20),
            transcriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            transcriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            transcriptionTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
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
                message: "Audio file not found",
                in: self
            )
            return
        }
        
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback(audioURL: audioURL)
        }
    }
    
    private func startPlayback(audioURL: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            playButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            
            startPlaybackTimer()
        } catch {
            ErrorAlertManager.shared.showAlert(
                title: "Playback Error",
                message: error.localizedDescription,
                in: self
            )
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        audioProgressView.progress = 0
        playbackTimer?.invalidate()
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updatePlaybackProgress), userInfo: nil, repeats: true)
    }
    
    @objc private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        audioProgressView.progress = Float(player.currentTime / player.duration)
    }
    
    @objc private func saveTranscription() {
        transcription?.text = transcriptionTextView.text
        do {
            try TranscriptionStorageManager.shared.saveContext()
            navigationController?.popViewController(animated: true)
        } catch {
            ErrorAlertManager.shared.handleStorageError(error, in: self)
        }
    }
    
    @objc private func shareTranscription() {
        guard let text = transcriptionTextView.text else { return }
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.barButtonItem = shareButton
        }
        present(activityVC, animated: true)
    }
}

// MARK: - AVAudioPlayerDelegate
extension TranscriptionViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlayback()
    }
}