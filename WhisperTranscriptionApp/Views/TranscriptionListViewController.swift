import UIKit
import CoreData

class TranscriptionListViewController: UIViewController {
    // MARK: - UI Elements
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(TranscriptionCell.self, forCellReuseIdentifier: TranscriptionCell.identifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        return table
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No transcriptions yet.\nTap + to start recording."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    // MARK: - Properties
    private var transcriptions: [Transcription] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTranscriptions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupNavigationBar() {
        title = "Transcriptions"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(startNewRecording)
        )
        navigationItem.rightBarButtonItem = addButton
    }
    
    // MARK: - Data Management
    private func fetchTranscriptions() {
        transcriptions = TranscriptionStorageManager.shared.fetchTranscriptions()
        emptyStateLabel.isHidden = !transcriptions.isEmpty
        tableView.reloadData()
    }
    
    @objc private func startNewRecording() {
        let recordingVC = RecordingViewController()
        navigationController?.pushViewController(recordingVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension TranscriptionListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcriptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TranscriptionCell.identifier, for: indexPath) as? TranscriptionCell else {
            return UITableViewCell()
        }
        
        let transcription = transcriptions[indexPath.row]
        cell.configure(with: transcription)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TranscriptionListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transcriptionVC = TranscriptionViewController()
        transcriptionVC.transcription = transcriptions[indexPath.row]
        navigationController?.pushViewController(transcriptionVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            
            let transcription = self.transcriptions[indexPath.row]
            
            do {
                // Delete audio file
                if let audioURL = transcription.audioURL {
                    AudioFileStorage.shared.deleteAudioFile(at: audioURL)
                }
                
                // Delete from Core Data
                try TranscriptionStorageManager.shared.deleteTranscription(transcription)
                
                // Update UI
                self.transcriptions.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                self.emptyStateLabel.isHidden = !self.transcriptions.isEmpty
                
                completion(true)
            } catch {
                ErrorAlertManager.shared.handleStorageError(error, in: self)
                completion(false)
            }
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            guard let self = self else { return }
            
            let transcriptionVC = TranscriptionViewController()
            transcriptionVC.transcription = self.transcriptions[indexPath.row]
            self.navigationController?.pushViewController(transcriptionVC, animated: true)
            
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        return configuration
    }
} 