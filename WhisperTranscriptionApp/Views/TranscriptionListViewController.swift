import UIKit
import CoreData

class TranscriptionListViewController: UIViewController {
    // MARK: - UI Elements
    private let tableView = UITableView()
    
    // MARK: - Properties
    private var transcriptions: [Transcription] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchTranscriptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTranscriptions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Transcriptions"
        view.backgroundColor = .white
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TranscriptionCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    // MARK: - Data Fetching
    private func fetchTranscriptions() {
        transcriptions = TranscriptionStorageManager.shared.fetchTranscriptions()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension TranscriptionListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return transcriptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = tableView.dequeueReusableCell(withIdentifier: "TranscriptionCell", for: indexPath)
       let transcription = transcriptions[indexPath.row]
       cell.textLabel?.text = transcription.dateFormattedString()
       return cell
    }
}

// MARK: - UITableViewDelegate
extension TranscriptionListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transcriptionVC = TranscriptionViewController()
        transcriptionVC.transcription = transcriptions[indexPath.row]
        navigationController?.pushViewController(transcriptionVC, animated: true)
    }
    
    // Swipe to delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let transcription = transcriptions[indexPath.row]
            TranscriptionStorageManager.shared.deleteTranscription(transcription)
            transcriptions.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
} 