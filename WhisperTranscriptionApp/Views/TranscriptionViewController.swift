import UIKit
import CoreData

class TranscriptionViewController: UIViewController {
    // MARK: - UI Elements
    private let transcriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isScrollEnabled = true
        return textView
    }()
    
    private let saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
        return button
    }()
    
    // MARK: - Properties
    var transcription: Transcription?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = saveButton
        
        view.addSubview(transcriptionTextView)
        transcriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            transcriptionTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
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
    }
    
    @objc private func saveTranscription() {
        guard let transcription = transcription else { return }
        transcription.text = transcriptionTextView.text
        
        TranscriptionStorageManager.shared.saveContext()
        
        navigationController?.popViewController(animated: true)
    }
}