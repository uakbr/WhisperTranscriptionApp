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
        let alert = UIAlertController(
            title: "Microphone Access Denied",
            message: "Please enable microphone access in Settings to use this feature.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        (viewController ?? topViewController())?.present(alert, animated: true)
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
    
    func handleSupabaseError(_ error: Error, in viewController: UIViewController? = nil) {
        showAlert(
            title: "Supabase Error",
            message: error.localizedDescription,
            in: viewController
        )
    }
}