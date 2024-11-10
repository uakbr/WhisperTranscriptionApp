import UIKit

class ErrorAlertManager {
    static let shared = ErrorAlertManager()
    
    private init() {}
    
    func showAlert(title: String, message: String, in viewController: UIViewController? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        DispatchQueue.main.async {
            if let viewController = viewController {
                viewController.present(alert, animated: true)
            } else if let topVC = UIApplication.shared.windows.first?.rootViewController {
                topVC.present(alert, animated: true)
            }
        }
    }
    
    // Specific error handling methods
    func handleMicrophonePermissionError(in viewController: UIViewController? = nil) {
        showAlert(
            title: "Microphone Access Required",
            message: "Please enable microphone access in Settings to use the recording features.",
            in: viewController
        )
    }
    
    func handleModelLoadingError(_ error: Error, in viewController: UIViewController? = nil) {
        showAlert(
            title: "Model Loading Error",
            message: "Failed to load the Whisper model: \(error.localizedDescription)",
            in: viewController
        )
    }
    
    func handleStorageError(_ error: Error, in viewController: UIViewController? = nil) {
        showAlert(
            title: "Storage Error",
            message: "Failed to save or retrieve data: \(error.localizedDescription)",
            in: viewController
        )
    }
    
    func handleRecordingError(_ error: Error, in viewController: UIViewController? = nil) {
        showAlert(
            title: "Recording Error",
            message: "An error occurred during recording: \(error.localizedDescription)",
            in: viewController
        )
    }
    
    func handleTranscriptionError(_ error: Error, in viewController: UIViewController? = nil) {
        showAlert(
            title: "Transcription Error",
            message: "An error occurred during transcription: \(error.localizedDescription)",
            in: viewController
        )
    }
    
    func handleCloudKitError(_ error: Error, in viewController: UIViewController? = nil) {
        showAlert(
            title: "Cloud Error",
            message: "An error occurred with iCloud: \(error.localizedDescription)",
            in: viewController
        )
    }
}